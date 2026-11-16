"""Puts a sorted scene into the Godot game: each sequence's pictures become a BackgroundList, and its
dialogue a chain of placeholder lines, one per picture, until you write your own.

    python -P -E art_sort.py package <workspace>      (or the board's "Put in the game" button)

The scene.json "game" block says where things go:
    pictures          res:// folder for them: <pictures>/<KEY>/01.webp, 02.webp ... and <KEY>.tres
    backgroundLists   the BackgroundLists the scene's dialogues use; new lists go on its end
    placeholders      the BackgroundList of placeholder pictures, each file named after its key
    stages            res:// folder searched for the scene's dialogues and stages (data/game_stages)
    skipStages        scene stages not in the game yet
    project           the Godot project, if not the one this tool is in

Dialogue points at a picture by two positions: its list's in the BackgroundLists, and its own in
that list. So nothing here ever moves. A new picture gets the next number in its sequence, a new
sequence's list goes on the end, and a picture taken off the board keeps its place (renamed "(off
the board)") until you remove it yourself.

Pictures go in as lossless WebP at the least compression effort: the same pixels at about 70% of a
PNG's size. The PNG's text (the
InvokeAI prompt) stays in the sorter's library. A picture put in earlier as a PNG becomes a WebP
under the same number on the next run. Every reference to it in the project's text files (.tres,
.tscn, .gd, ...) moves to the WebP, and then the PNG and its .import are deleted. The run refuses,
before writing anything, if a binary resource (.res, .scn) refers to one.

A sequence's dialogue (the start key named after it, in any dialogue using those BackgroundLists)
is written only while it is a placeholder: the skeleton's single "(Placeholder)" line, or a chain
this wrote that is unchanged since. Lines written on the board go in, "Name: text" with a speaker.
Once you edit the dialogue in Godot it is yours, and this only says what is new on the board.
Anything else still showing a sequence's placeholder picture shows the sequence's last picture.

Godot must be closed: the editor saves its own open copies over these files. What has been put
in is recorded in <pictures>/packaged.json, which belongs with the game: keep it in git.
"""
import hashlib
import json
import os
import re
import subprocess
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image

TOOL_DIR = Path(__file__).resolve().parent
STATE_FILE = 'packaged.json'
# Lossless at the least compression effort, as the user asked (quality is the effort here, not image
# quality: every setting keeps the exact pixels). On 1152x1536 renders a picture takes about 0.06s and
# comes out about 70% of a PNG's size; Pillow's defaults (quality 80, method 4) reach about 57% at ten
# times the time. exact keeps the colour under fully transparent pixels.
WEBP = {'lossless': True, 'quality': 0, 'method': 0, 'exact': True}
PICTURE_SUFFIX = '.webp'
# Text files that can name a picture; a binary resource naming one stops the run instead.
TEXT_FILES = ('.tres', '.tscn', '.gd', '.godot', '.cfg', '.json')
BINARY_FILES = ('.res', '.scn')
PLACEHOLDER = '(Placeholder)'
OFF_BOARD = ' (off the board)'
# Where a sequence's chain sits in the dialogue editor: to the right of its start node.
NODE_SIZE = (300, 640)
NODE_STEP = 360
FIRST_NODE_X = 380
# The board's own rule for "Name: text" (board.html dialogueLines).
SPEAKER_LINE = re.compile(r'^([^:]{1,24}):\s*(.+)$')


class PackageError(Exception):
    pass


# ---------------------------------------------------------------- Godot's text resources

class Name(str):
    """A StringName, written &"..."."""


class Raw(str):
    """A value kept exactly as Godot wrote it (Vector2(...), a float, ExtResource(...))."""


class Reader:
    """Reads the values in a Godot text resource (.tres): dictionaries, arrays, strings, numbers.
    Anything else (Vector2(...), typed arrays, floats) is kept as Raw text, so it writes back
    exactly as it was."""

    def __init__(self, text, pos):
        self.text = text
        self.pos = pos

    def fail(self, what):
        line = self.text.count('\n', 0, self.pos) + 1
        raise PackageError(f'could not read the file at line {line}: {what}')

    def skip(self):
        while self.pos < len(self.text) and self.text[self.pos] in ' \t\r\n':
            self.pos += 1

    def expect(self, char):
        self.skip()
        if self.text[self.pos:self.pos + 1] != char:
            self.fail(f'expected {char!r}')
        self.pos += 1

    def value(self):
        self.skip()
        char = self.text[self.pos:self.pos + 1]
        if char == '{':
            return dict((key, value) for key, value, _ in self.entries())
        if char == '[':
            self.pos += 1
            items = []
            while True:
                self.skip()
                if self.text[self.pos] == ']':
                    self.pos += 1
                    return items
                items.append(self.value())
                self.skip()
                if self.text[self.pos] == ',':
                    self.pos += 1
        if char == '"':
            return self.string()
        if char == '&':
            self.pos += 1
            return Name(self.string())
        number = re.compile(r'-?\d+(\.\d*)?([eE][-+]?\d+)?').match(self.text, self.pos)
        if number:
            self.pos = number.end()
            return Raw(number.group()) if number.group(1) or number.group(2) else int(number.group())
        word = re.compile(r'[A-Za-z_]\w*').match(self.text, self.pos)
        if not word:
            self.fail('expected a value')
        start, self.pos = self.pos, word.end()
        if word.group() in ('true', 'false', 'null'):
            return {'true': True, 'false': False, 'null': None}[word.group()]
        if self.text[self.pos:self.pos + 1] == '[':  # a typed array: Array[String]([...])
            self.pos += 1
            self.value()
            self.expect(']')
        if self.text[self.pos:self.pos + 1] == '(':
            self.pos += 1
            while True:
                self.skip()
                if self.text[self.pos] == ')':
                    self.pos += 1
                    break
                self.value()
                self.skip()
                if self.text[self.pos] == ',':
                    self.pos += 1
        return Raw(self.text[start:self.pos])

    def string(self):
        self.pos += 1
        out = []
        while True:
            char = self.text[self.pos:self.pos + 1]
            if char == '':
                self.fail('a string never ends')
            if char == '"':
                self.pos += 1
                return ''.join(out)
            if char == '\\':
                escape = self.text[self.pos + 1]
                if escape in 'uU':
                    digits = 4 if escape == 'u' else 6
                    out.append(chr(int(self.text[self.pos + 2:self.pos + 2 + digits], 16)))
                    self.pos += 2 + digits
                    continue
                out.append({'n': '\n', 't': '\t', 'r': '\r', 'b': '\b', 'f': '\f', 'a': '\a', 'v': '\v'}.get(escape, escape))
                self.pos += 2
                continue
            out.append(char)
            self.pos += 1

    def entries(self):
        """A dictionary's entries as (key, value, the entry's own text)."""
        self.expect('{')
        found = []
        while True:
            self.skip()
            if self.text[self.pos] == '}':
                self.pos += 1
                return found
            start = self.pos
            key = self.value()
            self.expect(':')
            value = self.value()
            found.append((key, value, self.text[start:self.pos]))
            self.skip()
            if self.text[self.pos] == ',':
                self.pos += 1


def quote(text):
    """A string as Godot writes it: only backslashes and quotes escaped, line breaks kept."""
    return '"' + text.replace('\\', '\\\\').replace('"', '\\"') + '"'


def write(value):
    """A value as Godot writes it into a text resource."""
    if isinstance(value, Raw):
        return str(value)
    if isinstance(value, Name):
        return '&' + quote(value)
    if isinstance(value, str):
        return quote(value)
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if value is None:
        return 'null'
    if isinstance(value, int):
        return str(value)
    if isinstance(value, dict):
        if not value:
            return '{}'
        return '{\n' + ',\n'.join(f'{write(k)}: {write(v)}' for k, v in value.items()) + '\n}'
    if isinstance(value, list):
        return '[' + ', '.join(write(v) for v in value) + ']'
    raise PackageError(f'cannot write {value!r} into a Godot file')


def vector(raw):
    """The numbers in a Vector2(...)."""
    return [float(n) for n in raw[raw.index('(') + 1:raw.rindex(')')].split(',')]


def property_value(text, name):
    """Where a top-level property's value starts, eg "nodes = {": the position of the {."""
    found = re.search(rf'^{name} = ', text, re.MULTILINE)
    return found.end() if found else None


def string_property(text, name):
    found = re.search(rf'^{name} = "(.*)"$', text, re.MULTILINE)
    return found.group(1) if found else ''


def ext_resources(text):
    """id -> path of a resource file's [ext_resource ...] lines."""
    found = {}
    for header in re.finditer(r'^\[ext_resource ([^\]]*)\]$', text, re.MULTILINE):
        attrs = dict(re.findall(r'(\w+)="([^"]*)"', header.group(1)))
        found[attrs['id']] = attrs['path']
    return found


def resource_section(text):
    found = re.search(r'^\[resource\]$', text, re.MULTILINE)
    return text[found.end():] if found else ''


def save_text(path, text):
    """Writes only a real change, whole or not at all."""
    if path.exists() and path.read_text(encoding='utf-8') == text:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + '.tmp')
    with open(tmp, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
    os.replace(tmp, path)
    return True


def write_picture(source, target):
    """A picture as lossless WebP, whole or not at all."""
    try:
        with Image.open(source) as img:
            img.load()
            if img.mode not in ('RGB', 'RGBA'):
                img = img.convert('RGBA' if img.has_transparency_data else 'RGB')
            target.parent.mkdir(parents=True, exist_ok=True)
            tmp = target.with_name(target.name + '.tmp')
            img.save(tmp, 'WEBP', **WEBP)
        os.replace(tmp, target)
    except (OSError, ValueError) as e:
        raise PackageError(f'could not make {target.name} from {source}: {e}')


# ---------------------------------------------------------------- the project's files

class Project:
    def __init__(self, root):
        self.root = Path(root)
        if not (self.root / 'project.godot').exists():
            raise PackageError(f'{self.root} is not a Godot project (no project.godot)')

    def path(self, res):
        return self.root / res.removeprefix('res://')

    def res(self, path):
        return 'res://' + Path(path).relative_to(self.root).as_posix()

    def script_uid(self, res):
        uid_file = self.path(res + '.uid')
        return uid_file.read_text(encoding='utf-8').strip() if uid_file.exists() else ''


class Lists:
    """The scene's BackgroundLists file: which list is at which position."""

    def __init__(self, project, res):
        self.project = project
        self.file = project.path(res)
        if not self.file.exists():
            raise PackageError(f'{res} does not exist')
        self.text = self.file.read_text(encoding='utf-8')
        found = re.search(r'^backgroundLists = Array\[[^\n]*?\]\(\[(.*)\]\)$', self.text, re.MULTILINE)
        if not found:
            raise PackageError(f'{res} has no backgroundLists')
        paths = ext_resources(self.text)
        self.paths = [paths[i] for i in re.findall(r'ExtResource\("([^"]+)"\)', found.group(1))]

    def add(self, res, key):
        """Puts a list on the end. Returns its position."""
        if res in self.paths:
            return self.paths.index(res)
        new_id = f'list_{key}'
        last_ext = list(re.finditer(r'^\[ext_resource [^\n]*\]$', self.text, re.MULTILINE))[-1]
        self.text = (self.text[:last_ext.end()] + f'\n[ext_resource type="Resource" path="{res}" id="{new_id}"]'
                     + self.text[last_ext.end():])
        self.text = re.sub(r'^(backgroundLists = Array\[[^\n]*?\]\(\[)(.*)(\]\))$',
                           lambda m: m.group(1) + m.group(2) + (', ' if m.group(2) else '') + f'ExtResource("{new_id}")' + m.group(3),
                           self.text, count=1, flags=re.MULTILINE)
        self.text = re.sub(r'load_steps=(\d+)', lambda m: f'load_steps={int(m.group(1)) + 1}', self.text, count=1)
        self.paths.append(res)
        return len(self.paths) - 1

    def save(self):
        return save_text(self.file, self.text)


def list_backgrounds(text):
    """A BackgroundList file's pictures, in order, as (name, imagePath)."""
    blocks = {}
    for block in re.finditer(r'^\[sub_resource [^\n]*id="([^"]+)"\]\n(.*?)(?=^\[|\Z)', text, re.MULTILINE | re.DOTALL):
        blocks[block.group(1)] = (string_property(block.group(2), 'name'), string_property(block.group(2), 'imagePath'))
    images = re.search(r'^images = Array\[[^\n]*?\]\(\[(.*)\]\)$', text, re.MULTILINE)
    return [blocks[i] for i in re.findall(r'SubResource\("([^"]+)"\)', images.group(1))] if images else []


def list_file_text(project, name, backgrounds):
    """A BackgroundList resource: its name, and its pictures as (name, imagePath) or (name, imagePath, wallpaperId).
    A picture with a wallpaperId unlocks that wallpaper when a line shows it (src/vn/Main.gd); the id comes from
    the slot's "wallpaper" in packaged.json, and the wallpaper itself is in resources/wallpapers/all_wallpapers.tres."""
    background_script = 'res://addons/dialogue_nodes/objects/Background.gd'
    list_script = 'res://addons/dialogue_nodes/objects/BackgroundList.gd'

    def script(res, script_id):
        uid = project.script_uid(res)
        return f'[ext_resource type="Script"{f" uid={quote(uid)}" if uid else ""} path="{res}" id="{script_id}"]'

    lines = [f'[gd_resource type="Resource" script_class="BackgroundList" load_steps={len(backgrounds) + 3} format=3]', '',
             script(background_script, '1_bg'), script(list_script, '2_list'), '']
    ids = [f'picture_{n:02d}' for n in range(1, len(backgrounds) + 1)]
    for sub_id, (bg_name, image_path, *wallpaper) in zip(ids, backgrounds):
        lines += [f'[sub_resource type="Resource" id="{sub_id}"]', 'script = ExtResource("1_bg")',
                  f'name = {quote(bg_name)}', f'imagePath = {quote(image_path)}']
        if wallpaper and wallpaper[0]:
            lines.append(f'wallpaperId = {quote(wallpaper[0])}')
        lines.append('')
    lines += ['[resource]', 'script = ExtResource("2_list")', f'name = {quote(name)}',
              'images = Array[ExtResource("1_bg")]([' + ', '.join(f'SubResource("{i}")' for i in ids) + '])', '']
    return '\n'.join(lines)


def character_names(project, res):
    """The speakers of a dialogue's CharacterList, by position."""
    path = project.path(res) if res else None
    if not path or not path.exists():
        return []
    text = path.read_text(encoding='utf-8')
    found = re.search(r'^characters = Array\[[^\n]*?\]\(\[(.*)\]\)$', text, re.MULTILINE)
    paths = ext_resources(text)
    names = []
    for character_id in re.findall(r'ExtResource\("([^"]+)"\)', found.group(1)) if found else []:
        character = project.path(paths[character_id])
        names.append(string_property(resource_section(character.read_text(encoding='utf-8')), 'name') if character.exists() else '')
    return names


class Dialogue:
    """A DialogueData file. Only the nodes this changes are rewritten: every other entry, and the
    rest of the file, stays byte for byte as it was."""

    def __init__(self, project, path):
        self.project = project
        self.file = path
        self.text = path.read_text(encoding='utf-8')
        self.res = project.res(path)
        start = property_value(self.text, 'starts')
        self.starts = Reader(self.text, start).value() if start is not None else {}
        start = property_value(self.text, 'nodes')
        if start is None:
            raise PackageError(f'{self.res} has no nodes')
        reader = Reader(self.text, start)
        self.nodes = {}
        self.raw = {}
        for key, value, raw in reader.entries():
            self.nodes[key] = value
            self.raw[key] = raw
        self.span = (start, reader.pos)
        self.speakers = character_names(project, string_property(self.text, 'characters'))
        self.changed = False

    def links(self, node_id):
        """The nodes a node leads to."""
        found = []

        def walk(value, field=None):
            if isinstance(value, dict):
                for key, item in value.items():
                    walk(item, key)
            elif isinstance(value, list):
                for item in value:
                    walk(item, field)
            elif isinstance(value, str) and field not in ('dialogue', 'text', 'start_id') and value in self.nodes:
                found.append(str(value))
        walk(self.nodes[node_id])
        return found

    def chain(self, start_key):
        """Every node a start key reaches, in the order reached (the start node itself not included)."""
        start = str(self.starts[start_key])
        seen, todo = [], self.links(start)
        while todo:
            node_id = todo.pop(0)
            if node_id not in seen and node_id != start:
                seen.append(node_id)
                todo += self.links(node_id)
        return seen

    def set_node(self, node_id, value):
        self.nodes[node_id] = value
        self.raw[node_id] = None
        self.changed = True

    def remove(self, node_id):
        del self.nodes[node_id]
        del self.raw[node_id]
        self.changed = True

    def free_ids(self, count, reuse=()):
        """Ids for new dialogue nodes: the ones given first, then numbers no node has."""
        taken = [int(k.split('_')[1]) for k in self.nodes if str(k).startswith('1_') and str(k).split('_')[1].isdigit()]
        next_number = max(taken, default=0) + 1
        ids = [Name(i) for i in list(reuse)[:count]]
        while len(ids) < count:
            ids.append(Name(f'1_{next_number}'))
            next_number += 1
        return ids

    def text_now(self):
        if not self.changed:
            return self.text
        entries = [self.raw[key] if self.raw[key] is not None else f'{write(key)}: {write(value)}'
                   for key, value in self.nodes.items()]
        body = '{\n' + ',\n'.join(entries) + '\n}'
        return self.text[:self.span[0]] + body + self.text[self.span[1]:]

    def save(self):
        return save_text(self.file, self.text_now())


def is_dialogue_node(node_id, node):
    return str(node_id).startswith('1_') and isinstance(node, dict) and 'dialogue' in node


def fingerprint(nodes):
    """What a chain says and shows, ignoring where its nodes sit in the editor."""
    def plain(value):
        if isinstance(value, dict):
            return {str(k): plain(v) for k, v in value.items() if k not in ('offset', 'size')}
        if isinstance(value, list):
            return [plain(v) for v in value]
        return str(value) if isinstance(value, str) else value
    data = json.dumps([[str(node_id), plain(node)] for node_id, node in nodes], sort_keys=True, ensure_ascii=False)
    return hashlib.sha1(data.encode('utf-8')).hexdigest()


def godot_running():
    """The names of running Godot processes (Windows)."""
    if os.name != 'nt':
        return []
    try:
        listing = subprocess.run(['tasklist', '/FO', 'CSV', '/NH'], capture_output=True, text=True, timeout=20).stdout
    except (OSError, subprocess.SubprocessError):
        return []
    names = {line.split('","')[0].strip('"') for line in listing.splitlines()}
    return sorted(n for n in names if n.lower().startswith('godot'))


def find_project():
    for folder in TOOL_DIR.parents:
        if (folder / 'project.godot').exists():
            return folder
    raise PackageError('this tool is not inside a Godot project: give scene.json\'s "game" a "project"')


# ---------------------------------------------------------------- putting a scene in

def speaker_lines(text, speakers):
    """Board dialogue as (speaker, line): a character's number when the name is one of the
    dialogue's characters, else the name as typed (Godot shows it as given), '' for narration."""
    lines = []
    for line in (text or '').split('\n'):
        line = line.strip()
        if not line:
            continue
        named = SPEAKER_LINE.match(line)
        if not named:
            lines.append(('', line))
            continue
        name = named.group(1).strip()
        number = next((n for n, known in enumerate(speakers) if known.lower() == name.lower()), None)
        lines.append((name if number is None else number, named.group(2)))
    return lines


class Packager:
    def __init__(self, workspace, check_godot=True):
        self.workspace = workspace
        self.config = workspace.scene.get('game')
        if not self.config:
            raise PackageError('scene.json has no "game" block saying where the scene goes in the game')
        for field in ('pictures', 'backgroundLists', 'placeholders'):
            if not self.config.get(field):
                raise PackageError(f'scene.json\'s "game" block has no "{field}"')
        if check_godot:
            running = godot_running()
            if running:
                raise PackageError(f'close Godot first ({running[0]} is running): the editor would save '
                                   'its open copies over the files this changes')
        project = self.config.get('project')
        self.project = Project(Path(os.path.expanduser(project)) if project else find_project())
        self.pictures = self.config['pictures'].rstrip('/')
        self.state_file = self.project.path(self.pictures) / STATE_FILE
        self.state = json.loads(self.state_file.read_text(encoding='utf-8')) if self.state_file.exists() else {}
        self.state.setdefault('sequences', {})
        self.renamed = {}  # a picture put in before as a PNG (its res:// path) -> its WebP
        self.report = []
        self.counts = {'pictures': 0, 'new': 0, 'sequences': 0, 'chains': 0}

    def note(self, text):
        self.report.append(text)

    def run(self):
        with self.workspace.lock:
            board = self.workspace.board()
            library = self.workspace.library()['images']
        lists = Lists(self.project, self.config['backgroundLists'])
        placeholders_res = self.config['placeholders']
        if placeholders_res not in lists.paths:
            raise PackageError(f'{self.config["backgroundLists"]} does not hold {placeholders_res}')
        placeholder_list = lists.paths.index(placeholders_res)
        placeholder_files = [path for _, path in list_backgrounds(self.project.path(placeholders_res).read_text(encoding='utf-8'))]
        placeholder_keys = [Path(path).stem for path in placeholder_files]

        sequences = self.place_pictures(board, library, lists)
        lists.save()
        # Before the record says WebP, so a run stopped halfway still knows which PNGs to retire next time.
        self.retire_pngs()
        self.save_state()

        stages = self.project.path(self.config.get('stages', 'res://data/game_stages'))
        shown = set()  # the picture lists some dialogue line shows
        for path in sorted(stages.rglob('*.tres')):
            text = path.read_text(encoding='utf-8')
            if 'script_class="DialogueData"' in text and string_property(text, 'backgroundList') == self.config['backgroundLists']:
                dialogue = Dialogue(self.project, path)
                self.write_chains(dialogue, sequences)
                self.show_real_pictures(dialogue, sequences, placeholder_list, placeholder_keys)
                shown |= {node.get('backgroundList') for node_id, node in dialogue.nodes.items() if is_dialogue_node(node_id, node)}
                if dialogue.save():
                    self.note(f'{dialogue.res}: written')
            elif any(f'imagePath = "{p}"' in text for p in placeholder_files) and path != self.project.path(placeholders_res):
                self.repoint_stage(path, text, sequences, placeholder_files)
        # A sequence the game has no dialogue for yet (eg a scene planned on the board first). A pool is
        # a set the game picks from, not a dialogue.
        for key, sequence in sequences.items():
            if sequence['list'] not in shown and sequence['order'] and not sequence['pool']:
                self.note(f'{key}: its pictures are in the game (list {sequence["list"]}), but no dialogue shows them '
                          f'yet: give a dialogue a start called {key}')
        self.save_state()
        return {'report': self.report, **self.counts, 'state': self.project.res(self.state_file)}

    def save_state(self):
        self.state['about'] = ('Written by tooling/art_sort (art_sort.py package): the sorter image in each picture '
                               'slot, so slots never move, and the dialogue chains it wrote, so it can tell when you have '
                               'edited one. Keep it with the game.')
        self.state['workspace'] = str(self.workspace.root)
        save_text(self.state_file, json.dumps(self.state, indent=1, ensure_ascii=False) + '\n')

    # ---- pictures

    def place_pictures(self, board, library, lists):
        """Puts each sequence's new pictures in (as WebP, as are any put in before as PNGs) and writes
        its BackgroundList. Returns, per key: its list's position, its slots, and the board's order as
        slot numbers."""
        skip = set(self.config.get('skipStages', []))
        planned, pictures = [], []
        for stage, sequence in self.workspace.sequences(board):
            key = sequence['key']
            if stage in skip:
                continue
            items = []  # the board's pictures in order, each once
            for item in board['lanes'].get(key, {}).get('items', []):
                if all(item['image'] != kept['image'] for kept in items):
                    items.append(item)
            record = self.state['sequences'].get(key)
            list_res = f'{self.pictures}/{key}/{key}.tres'
            if record is None and self.project.path(list_res).exists():
                raise PackageError(f'{list_res} exists but {STATE_FILE} has no record of it, so its picture '
                                   f'numbers are unknown. Restore {self.pictures}/{STATE_FILE} (eg from git) first.')
            if not items and record is None:
                continue
            record = record or {'slots': []}
            self.state['sequences'][key] = record
            # A picture can have copies: more slots of the same image (added to the state by hand, so each copy can
            # play a video of its own, tooling/video_gen/pinned.json). The board's picture is its first slot.
            slot_of = {}
            for n, slot in enumerate(record['slots']):
                slot_of.setdefault(slot['image'], n)
            new = []
            for item in items:
                image = item['image']
                if image in slot_of:
                    continue
                if image not in library:
                    raise PackageError(f'{key} lists {image}, which is not in the library')
                number = len(record['slots']) + 1
                record['slots'].append({'image': image, 'file': f'{self.pictures}/{key}/{number:02d}{PICTURE_SUFFIX}'})
                slot_of[image] = number - 1
                new.append(number)
            for slot in record['slots']:
                old = slot['file']
                if not old.endswith(PICTURE_SUFFIX):
                    slot['file'] = re.sub(r'\.[^./]*$', '', old) + PICTURE_SUFFIX
                    self.renamed[old] = slot['file']
                target = self.project.path(slot['file'])
                if not target.exists():
                    # A PNG already in the game is what it shows (perhaps touched up there), so it is the source.
                    source = self.project.path(old) if old != slot['file'] else None
                    if not source or not source.exists():
                        source = self.workspace.library_dir / slot['image']
                    if not source.exists():
                        raise PackageError(f'{slot["file"]} is missing and {slot["image"]} is not in the library to copy again')
                    pictures.append((source, target))
            planned.append((key, sequence, items, record, slot_of, new, list_res))
        self.find_references()
        if pictures:
            with ThreadPoolExecutor(max_workers=min(8, os.cpu_count() or 1)) as pool:
                list(pool.map(lambda job: write_picture(*job), pictures))
            self.note(f'{len(pictures)} {"pictures" if len(pictures) > 1 else "picture"} written as lossless WebP')
        sequences = {}
        for key, sequence, items, record, slot_of, new, list_res in planned:
            on_board = {item['image'] for item in items}
            # Each picture is named after its sequence (WIN_S1_TOP_07), never just its number: the game
            # takes two Backgrounds with the same name as the same picture (src/vn/Background.gd
            # setBackground) and keeps the one on screen.
            backgrounds = [(f'{key}_{n:02d}' + ('' if slot['image'] in on_board else OFF_BOARD), slot['file'], slot.get('wallpaper', ''))
                           for n, slot in enumerate(record['slots'], 1)]
            save_text(self.project.path(list_res), list_file_text(self.project, key, backgrounds))
            position = lists.add(list_res, key)
            order = [slot_of[item['image']] for item in items]
            sequences[key] = {'list': position, 'slots': record['slots'], 'order': order, 'items': items,
                              'context': sequence.get('context', ''), 'record': record, 'pool': sequence.get('kind') == 'pool'}
            self.counts['sequences'] += 1
            self.counts['pictures'] += len(order)
            self.counts['new'] += len(new)
            off = [f'{n:02d}' for n, slot in enumerate(record['slots'], 1) if slot['image'] not in on_board]
            if new:
                self.note(f'{key}: {"pictures" if len(new) > 1 else "picture"} {", ".join(f"{n:02d}" for n in new)} added (list {position})')
            if off:
                self.note(f'{key}: {", ".join(off)} {"are" if len(off) > 1 else "is"} off the board, but '
                          f'{"stay" if len(off) > 1 else "stays"} in the game so no picture number moves. Remove '
                          f'{"them" if len(off) > 1 else "it"} from the list by hand once no dialogue uses '
                          f'{"them" if len(off) > 1 else "it"}.')
        return sequences

    def project_files(self, suffixes):
        for folder, dirs, files in os.walk(self.project.root):
            dirs[:] = [d for d in dirs if not d.startswith('.')]  # .godot (Godot's cache), .git
            for name in files:
                if name.endswith(suffixes):
                    yield Path(folder) / name

    def find_references(self):
        """Finds the text files naming a picture that is becoming a WebP, so retire_pngs can move them
        on. Refuses before anything is written when a reference can't be moved: one in a binary
        resource, or one by the PNG's uid (which goes with its .import) outside an [ext_resource] line."""
        self.referencing = []
        if not self.renamed:
            return
        uids = set()
        for old in self.renamed:
            imported = self.project.path(old + '.import')
            found = re.search(r'^uid="([^"]+)"$', imported.read_text(encoding='utf-8'), re.MULTILINE) if imported.exists() else None
            if found:
                uids.add(found.group(1))
        olds = [old.encode('utf-8') for old in self.renamed]
        for path in self.project_files(TEXT_FILES + BINARY_FILES):
            if path == self.state_file:
                continue
            data = path.read_bytes()
            if path.suffix in BINARY_FILES:
                if any(old in data for old in olds) or {u.encode() for u in uids} & set(re.findall(rb'uid://\w+', data)):
                    raise PackageError(f'{self.project.res(path)} is a binary resource naming a picture put in as a PNG, '
                                       'so it could not follow the picture to WebP. Save it as .tres/.tscn first.')
                continue
            text = data.decode('utf-8', errors='replace')
            stray = set(re.findall(r'uid://\w+', text)) & uids
            if stray:
                # A uid in an [ext_resource] line whose path is one of the PNGs is fine: retire_pngs drops it.
                rest = re.sub(r'^\[ext_resource [^\n]*path="([^"]+)"[^\n]*\](?=\r?$)',
                              lambda m: '' if m.group(1) in self.renamed else m.group(0), text, flags=re.MULTILINE)
                if set(re.findall(r'uid://\w+', rest)) & uids:
                    raise PackageError(f'{self.project.res(path)} names a picture put in as a PNG by its uid, which '
                                       'goes when it becomes a WebP. Point it at the picture by path first.')
            if self.pictures in text or stray:
                self.referencing.append(path)

    def retire_pngs(self):
        """Moves every reference to a picture put in as a PNG on to its WebP, then deletes the PNG and
        its .import."""
        if not self.renamed:
            return
        olds = sorted(self.renamed, key=len, reverse=True)
        pattern = re.compile('(' + '|'.join(re.escape(old) for old in olds) + r')(?![\w.])')
        webps = set(self.renamed.values())

        def drop_uid(found):
            # Godot looks a resource up by uid before path, and the PNG's uid goes with it.
            return found.group(1) + found.group(2) if found.group(3) in webps else found.group(0)
        for path in self.referencing:
            text = path.read_text(encoding='utf-8')
            moved = pattern.sub(lambda found: self.renamed[found.group(1)], text)
            moved = re.sub(r'^(\[ext_resource [^\n]*?) uid="[^"]*"([^\n]*path="([^"]+)"[^\n]*\])(?=\r?$)', drop_uid, moved,
                           flags=re.MULTILINE)
            if save_text(path, moved):
                self.note(f'{self.project.res(path)}: shows the WebP pictures now')
        for old in self.renamed:
            for path in (self.project.path(old), self.project.path(old + '.import')):
                if path.exists():
                    path.unlink()
        many = len(self.renamed) > 1
        self.note(f'{len(self.renamed)} {"pictures" if many else "picture"} put in before as PNG '
                  f'{"are" if many else "is"} WebP now, under the same {"numbers" if many else "number"}')

    # ---- dialogue

    def write_chains(self, dialogue, sequences):
        """Each sequence's own start key gets one line per picture, while its dialogue is a placeholder."""
        for key, sequence in sequences.items():
            if key not in dialogue.starts or not sequence['order']:
                continue
            start = str(dialogue.starts[key])
            chain = dialogue.chain(key)
            written = sequence['record'].get('dialogue')
            ours = (written is not None and written['file'] == dialogue.res and sorted(written['nodes']) == sorted(chain)
                    and all(n in dialogue.nodes for n in written['nodes'])
                    and fingerprint((n, dialogue.nodes[n]) for n in written['nodes']) == written['fingerprint'])
            skeleton = (len(chain) == 1 and is_dialogue_node(chain[0], dialogue.nodes[chain[0]])
                        and str(dialogue.nodes[chain[0]]['dialogue']).startswith(PLACEHOLDER)
                        and dialogue.links(chain[0]) == [])
            if not (ours or skeleton):
                in_dialogue = {dialogue.nodes[n].get('background') for n in chain
                               if is_dialogue_node(n, dialogue.nodes[n]) and dialogue.nodes[n].get('backgroundList') == sequence['list']}
                unused = [f'{n + 1:02d}' for n in sequence['order'] if n not in in_dialogue]
                if unused:
                    self.note(f'{key}: your dialogue does not show {", ".join(unused)} yet (list {sequence["list"]})')
                continue

            lines = []
            for slot, item in zip(sequence['order'], sequence['items']):
                said = speaker_lines(item.get('dialogue'), dialogue.speakers)
                if not said:
                    text = f'{PLACEHOLDER} {key} · picture {slot + 1:02d}'
                    said = [('', text + (f'. {sequence["context"]}' if not lines and sequence['context'] else ''))]
                for k, (speaker, text) in enumerate(said):
                    lines.append({'background': slot if k == 0 else -1, 'backgroundList': sequence['list'] if k == 0 else -1,
                                  'characterState': -1, 'dialogue': text, 'speaker': speaker})
            reuse = written['nodes'] if ours else chain
            ids = dialogue.free_ids(len(lines), reuse)
            start_node = dialogue.nodes[start]
            x, y = (vector(start_node['offset']) + [0, 0])[:2] if 'offset' in start_node else (0, 0)
            nodes = []
            for n, (node_id, line) in enumerate(zip(ids, lines)):
                link = Name(ids[n + 1]) if n + 1 < len(ids) else 'END'
                nodes.append((node_id, {
                    'background': line['background'], 'backgroundList': line['backgroundList'],
                    'characterState': line['characterState'], 'dialogue': line['dialogue'],
                    'offset': Raw(f'Vector2({int(x + FIRST_NODE_X + n * NODE_STEP)}, {int(y)})'),
                    'options': {0: {'condition': {}, 'link': link, 'text': ''}},
                    'size': Raw(f'Vector2({NODE_SIZE[0]}, {NODE_SIZE[1]})'), 'speaker': line['speaker']}))
            chain_print = fingerprint(nodes)
            if ours and chain_print == written['fingerprint'] and ids == written['nodes']:
                continue
            for node_id in chain:
                if node_id not in ids:
                    dialogue.remove(node_id)
            for node_id, node in nodes:
                dialogue.set_node(node_id, node)
            linked = dict(start_node)
            linked['link'] = Name(ids[0])
            dialogue.set_node(start, linked)
            sequence['record']['dialogue'] = {'file': dialogue.res, 'nodes': [str(i) for i in ids], 'fingerprint': chain_print}
            self.counts['chains'] += 1
            self.note(f'{key}: dialogue {"rewritten" if ours else "written"}, {len(nodes)} '
                      f'{"line" if len(nodes) == 1 else "lines"} over {len(sequence["order"])} '
                      f'{"picture" if len(sequence["order"]) == 1 else "pictures"}')

    def show_real_pictures(self, dialogue, sequences, placeholder_list, placeholder_keys):
        """Any line still showing a sequence's placeholder picture shows the real one: the first
        picture when it opens that sequence's own scene, else the picture the sequence ends on."""
        opens = {str(dialogue.nodes[str(node_id)].get('link')): str(key) for key, node_id in dialogue.starts.items()
                 if str(node_id) in dialogue.nodes}
        for node_id, node in list(dialogue.nodes.items()):
            if not is_dialogue_node(node_id, node) or node.get('backgroundList') != placeholder_list:
                continue
            index = node.get('background')
            if not isinstance(index, int) or not 0 <= index < len(placeholder_keys):
                continue
            key = placeholder_keys[index]
            sequence = sequences.get(key)
            if not sequence or not sequence['order']:
                continue
            slot = sequence['order'][0] if opens.get(str(node_id)) == key else sequence['order'][-1]
            changed = dict(node)
            changed['backgroundList'] = sequence['list']
            changed['background'] = slot
            dialogue.set_node(node_id, changed)
            start = opens.get(str(node_id))
            self.note(f'{dialogue.res}: {start or node_id} shows {key} {slot + 1:02d} instead of its placeholder')

    def repoint_stage(self, path, text, sequences, placeholder_files):
        """A stage's starting picture (or any picture set in a .tres) that is still a placeholder."""
        def replace(found):
            key = Path(found.group(1)).stem
            sequence = sequences.get(key)
            if not sequence or not sequence['order']:
                return found.group(0)
            return f'imagePath = {quote(sequence["slots"][sequence["order"][-1]]["file"])}'
        pattern = '^imagePath = "(' + '|'.join(re.escape(p) for p in placeholder_files) + ')"$'
        if save_text(path, re.sub(pattern, replace, text, flags=re.MULTILINE)):
            self.note(f'{self.project.res(path)}: its placeholder picture is real art now')


def package(workspace, check_godot=True):
    result = Packager(workspace, check_godot).run()
    # The dialogue guide (guide.py) describes what was just put in, when the scene has one.
    if (workspace.scene.get('game') or {}).get('guide'):
        from guide import write_guide
        guide = write_guide(workspace)
        result['report'].append(f'dialogue guide written: {guide["file"]}')
    return result
