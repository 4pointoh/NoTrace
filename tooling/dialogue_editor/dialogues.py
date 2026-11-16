"""The dialogue editor's model: the game's DialogueData files read as start keys, each a straight
chain of lines and signals, and the one careful way edits go back into a file.

Files are read with the art sorter's reader (tooling/art_sort/package.py), which writes Godot's text
format back byte for byte. A save rewrites only the node entries it changes: every other entry, and
the rest of the file, stays exactly as it was, so a save next to the art packager's or Godot's own
changes keeps theirs.

A start is editable here when it is a plain chain: start -> line or signal -> ... -> END, every node
reached from that one place only, every line with its single empty option. Anything else (choices,
shared tails, variables) is shown read-only and is left to Godot's graph.

Saving, for each changed start: the file is read again, the start must still be a plain chain and
still say what the page was shown (its fingerprint), or the whole save is refused. Then the old file
goes to the backups folder, the new text is written whole or not at all (starting again from the
file on disk if another program wrote it meanwhile), read back and checked; if the check fails the
old file is put back, over this save's own write only.

The line and signal warnings are the page's (editor.html itemWarnings): this sends none.
"""
import datetime
import hashlib
import html
import json
import os
import re
import subprocess
import sys
import threading
import time
import traceback
import urllib.parse
from collections import Counter
from io import BytesIO
from pathlib import Path

TOOL_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOL_DIR.parent / 'art_sort'))  # -P keeps the tool folders off the import path
import package as P  # noqa: E402
from package import Name, Raw, Reader, write  # noqa: E402

from PIL import Image  # noqa: E402

PLACEHOLDER = P.PLACEHOLDER
DONE_FILE = 'done.json'
MATCHES_FILE = 'match_pictures.json'
MATCHES_ABOUT = ('The picture each Ashely II poker match opens on, picked in the dialogue editor (Match pictures): '
                 'situation -> {list, picture}. FIRST is the first hand; DRESSED_1_2 is a match you start dressed '
                 'with 1 win of yours and 2 of hers. The game does not read this file: the picks are copied into it.')
MATCH_ID = re.compile(r'[A-Za-z0-9_-]{1,60}')
WALLPAPERS_FILE = 'wallpaper_picks.json'
WALLPAPERS_ABOUT = ('The pictures picked as wallpapers in the dialogue editor (the Gallery\'s Wallpapers): picture file -> '
                    '{list, picture}. "seeded": the picture lists (their BackgroundLists file) whose pictures with a video '
                    'were picked for you when Wallpapers was first turned on there. The game does not read this file: '
                    'the picks are put into the game from it when they are ready.')
WALLPAPER_IMAGE = re.compile(r'res://[^\x00-\x1f"]{1,480}\.(?:webp|png|jpg|jpeg)', re.I)
DONE_ABOUT = ('The starts marked done in the dialogue editor (its Done button), per dialogue file: start key and '
              'when it was marked. Only the editor reads this; the game never does.')
LINE, SIGNAL = 'line', 'signal'
KIND_TYPE = {LINE: '1', SIGNAL: '3'}
TYPE_NAMES = {'0': 'start', '1': 'line', '2': 'comment', '3': 'signal', '4': 'set', '5': 'condition'}
START_KEY = re.compile(r'[A-Za-z0-9_]{1,120}')   # used with fullmatch: $ would let a trailing \n in
NODE_ID = re.compile(r'(\d+)_(\d+)')
# Where nodes go in Godot's graph. A chain runs in a row to the right of its start node, one node
# every NODE_STEP (package.py's numbers); its first node clears the start node, which is 488 wide
# (StartNode.tscn: package.py's 380 put the first line over the start node's end).
NODE_SIZE = Raw(f'Vector2({P.NODE_SIZE[0]}, {P.NODE_SIZE[1]})')
NODE_STEP = P.NODE_STEP
FIRST_NODE_GAP = 560
NEW_START_GAP = 700   # a new start goes this far below the lowest start node, and below every node
ROW_GAP = 60
# The size of a node in the graph when its entry doesn't say (the addon's node scenes); a line
# grows with its text, so it gets the packager's size.
SCENE_SIZES = {'0': (488, 87), '1': tuple(P.NODE_SIZE), '2': (200, 237), '3': (240, 86), '4': (365, 86), '5': (348, 160)}
KEEP_BACKUPS = 50
KEEP_DAILY_DAYS = 60  # and the first backup of each day, for this long
ADDON_BACKUP_SUFFIX = '-outside-godot.tres.bak'  # the patched Godot addon's backups (files.gd)
SET_OPS = ['=', '+=', '-=', '*=', '/=']
CONDITION_OPS = ['==', '!=', '>', '<', '>=', '<=']
IMAGE_TYPES = {'.png': 'image/png', '.webp': 'image/webp', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg'}
VIDEO_TYPES = ('.ogv', '.webm', '.mp4', '.mkv', '.mov')  # what Editor.reveal will show or play besides pictures
THUMB_WIDTH = 240
SCAN_EVERY = 3.0      # seconds between looks for new or removed dialogue files
STATUS_EVERY = 3.0    # seconds a Godot-running answer stays good
STAT_EVERY = 20.0     # seconds a picture's size/date stays good
SIDE_EVERY = 1.0      # seconds between looks at a characters/picture list/stage file's date
PATCH_MARKER = 'EXTERNAL_EDIT_SAFE'
ADDON_FILES = 'addons/dialogue_nodes/editor/files.gd'
READ_ONLY_HINT = 'edit this one in Godot'
EMPTY_CHAIN_NOTE = ("no lines: Godot's dialogue editor drops a start with nothing after it from the "
                    'start list the next time it saves this file')


class EditorError(Exception):
    """A request the editor refuses, with the HTTP status that says why."""

    def __init__(self, message, status=400, **extra):
        super().__init__(message)
        self.status = status
        self.extra = extra

    def body(self):
        return {'error': str(self), **self.extra}


# ---------------------------------------------------------------- reading Godot text

def read_text(path):
    """A file's text exactly as stored: no newline translation, so writing it back is byte-identical."""
    with open(path, encoding='utf-8', newline='') as f:
        return f.read()


def sha1(text):
    return hashlib.sha1(text.encode('utf-8') if isinstance(text, str) else text).hexdigest()


def stamp_of(path):
    """What changes when a file does: its modified time, size and file id (a write through a
    temporary file, as Godot, the packager and this tool do, makes a new file even within one tick
    of the clock). None when it is missing."""
    try:
        st = os.stat(path)
    except OSError:
        return None
    return (st.st_mtime_ns, st.st_size, st.st_ino)


def dict_entries(text, pos):
    """The dictionary starting at pos: its entries as (key, value, start, end) and where it ends."""
    reader = Reader(text, pos)
    reader.expect('{')
    found = []
    while True:
        reader.skip()
        if reader.pos >= len(text):
            reader.fail('a dictionary never ends')
        if text[reader.pos] == '}':
            return found, reader.pos + 1
        start = reader.pos
        key = reader.value()
        reader.expect(':')
        value = reader.value()
        found.append((key, value, start, reader.pos))
        reader.skip()
        if text[reader.pos:reader.pos + 1] == ',':
            reader.pos += 1


def godot_body(entries):
    """A dictionary as Godot writes one: an entry per line, or {} when empty."""
    return '{\n' + ',\n'.join(entries) + '\n}' if entries else '{}'


def prop_at(text, name, start=0):
    """Where a top-level property's value starts (after "name = "), searching from start. Searching
    from the end of nodes keeps a dialogue line that happens to read "strays = ..." from fooling it."""
    found = re.compile(rf'^{name} = ', re.MULTILINE).search(text, start)
    return found.end() if found else None


def prop_value(text, name, start=0):
    pos = prop_at(text, name, start)
    return Reader(text, pos).value() if pos is not None else None


def godot_order(value):
    """A value with its dictionaries' keys in the order Godot writes them (sorted)."""
    if isinstance(value, dict):
        def order(key):
            if isinstance(key, int) and not isinstance(key, bool):
                return (0, key, '')
            return (1, 0, str(key))
        return {key: godot_order(value[key]) for key in sorted(value, key=order)}
    if isinstance(value, list):
        return [godot_order(v) for v in value]
    return value


def node_type(node_id):
    return str(node_id).split('_')[0]


def number_text(value):
    return str(int(value)) if float(value).is_integer() else repr(float(value))


def vector_of(node, field):
    if isinstance(node, dict) and isinstance(node.get(field), str) and 'Vector2' in node[field]:
        try:
            x, y = (P.vector(node[field]) + [0, 0])[:2]
            return x, y
        except ValueError:
            pass
    return None


def offset_of(node):
    return vector_of(node, 'offset') or (0.0, 0.0)


def size_of(node_id, node):
    """A node's size in Godot's graph: its own when the entry has one, else its scene's."""
    size = vector_of(node, 'size')
    if size and size[0] > 0 and size[1] > 0:
        return size
    return SCENE_SIZES.get(node_type(node_id), (300, 200))


def step_after(node_id, node):
    """How far right of a chain node the next one goes: NODE_STEP, or more after a node that was
    resized wider than a line node."""
    return max(NODE_STEP, size_of(node_id, node)[0] + NODE_STEP - P.NODE_SIZE[0])


def overlaps(a, b):
    """Whether two (x, y, width, height) boxes overlap."""
    return a[0] < b[0] + b[2] and b[0] < a[0] + a[2] and a[1] < b[1] + b[3] and b[1] < a[1] + a[3]


def free_spot(x, y, w, h, taken, unit=120, reach=12):
    """The nearest place to (x, y) for a w x h node that overlaps nothing in taken (boxes), looking
    on a grid out to reach steps of unit each way (leftward counts as further); below everything
    there is when all of that is taken."""
    near = [b for b in taken if b[0] < x + w + reach * unit and b[0] + b[2] > x - reach * unit
            and b[1] < y + h + reach * unit and b[1] + b[3] > y - reach * unit]
    steps = sorted(((dx, dy) for dx in range(-reach, reach + 1) for dy in range(-reach, reach + 1)),
                   key=lambda d: ((d[0] * d[0] + d[1] * d[1]) * (4 if d[0] < 0 else 1), d[1] < 0, d[1]))
    for dx, dy in steps:
        spot = (x + dx * unit, y + dy * unit, w, h)
        if not any(overlaps(spot, b) for b in near):
            return spot[0], spot[1]
    return x, max(b[1] + b[3] for b in taken) + ROW_GAP


def vector_text(x, y):
    return Raw(f'Vector2({number_text(x)}, {number_text(y)})')


def quoted_ids(raw):
    return set(re.findall(r'"((?:[^"\\]|\\.)*)"', str(raw or '')))


# ---------------------------------------------------------------- one dialogue file

class Walk:
    """Where one start key leads: its node ids in order, and why it can't be edited here, if so."""

    def __init__(self, key, start_id, ids, reason, fingerprint):
        self.key = key
        self.start_id = start_id
        self.ids = ids
        self.reason = reason
        self.fingerprint = fingerprint

    @property
    def editable(self):
        return self.reason is None


class Doc:
    """One DialogueData file's text, read into its starts and nodes, with where each entry sits."""

    def __init__(self, text):
        self.text = text
        try:
            self._read()
        except (P.PackageError, IndexError, ValueError, KeyError, TypeError, AttributeError) as e:
            raise EditorError(f'could not read this dialogue file: {e}', 422)

    def _read(self):
        text = self.text
        section = re.search(r'^\[resource\]\r?$', text, re.MULTILINE)
        if not section:
            raise P.PackageError('it has no [resource] section')
        base = section.end()
        nodes_at = prop_at(text, 'nodes', base)
        starts_at = prop_at(text, 'starts', base)
        if nodes_at is None or starts_at is None:
            raise P.PackageError('it has no starts or no nodes')
        self.problem = None

        entries, end = dict_entries(text, nodes_at)
        self.nodes_span = (nodes_at, end)
        self.order, self.nodes, self.raw, self.keys = [], {}, {}, {}
        for key, value, s, e in entries:
            node_id = str(key)
            if node_id in self.nodes:
                self.problem = f'node {node_id} is in the file twice'
            self.order.append(node_id)
            self.nodes[node_id] = value
            self.raw[node_id] = text[s:e]
            self.keys[node_id] = key
        if text[nodes_at:end] != godot_body([text[s:e] for _, _, s, e in entries]):
            self.problem = "its nodes are not laid out the way Godot writes them (to fix it, open it in Godot's dialogue tab, drag any node a little, and press Ctrl+S there)"
        names = sum(1 for k in self.keys.values() if isinstance(k, Name))
        self.name_keys = names >= len(self.keys) - names  # the file's own style for new node ids

        entries, end = dict_entries(text, starts_at)
        self.starts_span = (starts_at, end)
        self.starts = []        # (key, start node id), in file order
        self.start_raw = {}
        for key, value, s, e in entries:
            self.starts.append((str(key), str(value)))
            self.start_raw[str(key)] = text[s:e]
        if text[starts_at:end] != godot_body([text[s:e] for _, _, s, e in entries]):
            self.problem = "its start list is not laid out the way Godot writes it (to fix it, open it in Godot's dialogue tab, drag any node a little, and press Ctrl+S there)"
        self.start_ids = dict(self.starts)
        if len(self.start_ids) != len(self.starts):
            self.problem = 'a start key is in the file twice'

        after = self.nodes_span[1]
        self.strays = quoted_ids(prop_value(text, 'strays', after))
        self.comments = quoted_ids(prop_value(text, 'comments', after))
        chars = prop_value(text, 'characters', after)
        lists = prop_value(text, 'backgroundList', after)
        self.characters = chars if isinstance(chars, str) and not isinstance(chars, Raw) else ''
        self.background_lists = lists if isinstance(lists, str) and not isinstance(lists, Raw) else ''

        self.incoming = Counter()
        for node_id in self.order:
            for target in self.links(node_id):
                if target != 'END':
                    self.incoming[target] += 1
        self.start_keys_of = {}
        for key, start_id in self.starts:
            self.start_keys_of.setdefault(start_id, []).append(key)
        self._walks = {}

    # ---- the graph

    def links(self, node_id):
        """Where a node goes next, as the game's dialogue box follows it (dialogueBox.gd proceed)."""
        node = self.nodes.get(node_id)
        if not isinstance(node, dict):
            return []
        kind = node_type(node_id)
        if kind == '1':
            options = node.get('options')
            if not isinstance(options, dict):
                return []
            return [str(o.get('link', 'END')) for o in options.values() if isinstance(o, dict)]
        if kind == '5':
            return [str(node.get('true', 'END')), str(node.get('false', 'END'))]
        if kind == '2':
            return []
        return [str(node['link'])] if 'link' in node else []

    def walk(self, key):
        """The nodes a start runs through, in order, and why it is not a plain chain, if it isn't."""
        if key in self._walks:
            return self._walks[key]
        start_id = self.start_ids[key]
        ids, reason = [], None
        start = self.nodes.get(start_id)
        if self.problem:
            reason = self.problem
        elif not isinstance(start, dict) or node_type(start_id) != '0':
            reason = f'its start node {start_id} is missing'
        elif len(self.start_keys_of[start_id]) > 1:
            others = [k for k in self.start_keys_of[start_id] if k != key]
            reason = f'it shares its start node with {", ".join(others)}'
        elif self.incoming[start_id]:
            reason = f'another node links back to its start node {start_id}'
        elif start_id in self.strays or start_id in self.comments:
            reason = f'its start node {start_id} is listed as a stray'
        else:
            seen = set()
            current = str(start.get('link', 'END'))
            while current != 'END':
                reason = self._not_plain(current, seen)
                if reason:
                    break
                seen.add(current)
                ids.append(current)
                current = self.links(current)[0]
        if reason:
            ids = self.reach(start_id)
        nodes = [(start_id, start)] + [(node_id, self.nodes[node_id]) for node_id in ids if node_id in self.nodes]
        walk = Walk(key, start_id, ids, reason, P.fingerprint(nodes))
        self._walks[key] = walk
        return walk

    def _not_plain(self, node_id, seen):
        """Why a node can't be part of a plain chain, or None."""
        node = self.nodes.get(node_id)
        kind = node_type(node_id)
        if node_id not in self.nodes:
            return f'it links to {node_id}, which is not in the file'
        if node_id in seen:
            return f'it loops back to {node_id}'
        if not isinstance(node, dict):
            return f'{node_id} is not a node'
        if kind == '0':
            return f'it runs into the start node {node_id} ({", ".join(self.start_keys_of.get(node_id, ["no key"]))})'
        if kind in ('4', '5'):
            return f'it {"sets" if kind == "4" else "checks"} a variable ({node_id})'
        if kind not in ('1', '3'):
            return f'it has a {TYPE_NAMES.get(kind, "unknown")} node ({node_id}) in its chain'
        if self.incoming[node_id] > 1:
            return f'it shares lines with another start or branch ({node_id} is reached from {self.incoming[node_id]} places)'
        if node_id in self.strays or node_id in self.comments:
            return f'{node_id} is listed as a stray'
        if kind == '3':
            if not isinstance(node.get('signalValue'), str) or 'link' not in node:
                return f'signal {node_id} has unexpected data'
            return None
        options = node.get('options')
        if not isinstance(options, dict) or len(options) != 1:
            return f'it branches: line {node_id} has {len(options) if isinstance(options, dict) else "no"} choices'
        number, option = next(iter(options.items()))
        if number != 0 or not isinstance(option, dict) or set(option) != {'condition', 'link', 'text'}:
            return f'line {node_id} has an unusual option'
        if option['text'] != '':
            return f'it branches: line {node_id} has a choice ("{option["text"]}")'
        if option['condition'] != {}:
            return f'line {node_id} has a condition on its option'
        if not isinstance(node.get('dialogue'), str) or not isinstance(node.get('speaker'), (int, str)) \
                or isinstance(node.get('speaker'), bool):
            return f'line {node_id} has unexpected data'
        for field in ('backgroundList', 'background', 'characterState'):
            if not isinstance(node.get(field), int) or isinstance(node.get(field), bool):
                return f'line {node_id} has no {field} number'
        return None

    def reach(self, start_id):
        """Every node a start reaches, each once, in the order reached (for read-only display)."""
        seen, todo, order = {start_id}, [l for l in self.links(start_id)], []
        while todo and len(order) < 5000:
            node_id = todo.pop(0)
            if node_id == 'END' or node_id in seen:
                continue
            seen.add(node_id)
            order.append(node_id)
            todo += self.links(node_id)
        return order

    def dangling(self):
        """Links to nodes that aren't in the file, as (from, to)."""
        return {(node_id, target) for node_id in self.order for target in self.links(node_id)
                if target != 'END' and target not in self.nodes}

    def numbers(self):
        """The highest number in use per node type, counting every id the file mentions anywhere."""
        mentioned = set(self.order) | self.strays | self.comments | set(self.start_ids.values())
        for node_id in self.order:
            mentioned.update(self.links(node_id))
        found = {}
        for node_id in mentioned:
            match = NODE_ID.fullmatch(node_id)
            if match:
                found[match.group(1)] = max(found.get(match.group(1), 0), int(match.group(2)))
        return found


def line_item(node_id, node):
    return {'id': node_id, 'kind': LINE, 'speaker': node.get('speaker', ''), 'text': str(node.get('dialogue', '')),
            'backgroundList': node.get('backgroundList', -1), 'background': node.get('background', -1),
            'characterState': node.get('characterState', -1)}


def doc_items(doc, walk):
    """A start's items as the page edits them. Read-only starts also show what else they run through,
    in the order reached, each with where it leads (next), so play can follow one way through."""
    items = doc_items_plain(doc, walk)
    if walk.reason:
        for item in items:
            item['next'] = doc.links(item['id'])
    return items


def doc_items_plain(doc, walk):
    items = []
    for node_id in walk.ids:
        node = doc.nodes.get(node_id)
        kind = node_type(node_id)
        if not isinstance(node, dict):
            items.append({'id': node_id, 'kind': 'other', 'type': 'missing', 'summary': f'{node_id} is not in the file'})
        elif kind == '1':
            item = line_item(node_id, node)
            options = node.get('options') if isinstance(node.get('options'), dict) else {}
            if walk.reason and (len(options) != 1 or any(isinstance(o, dict) and (o.get('text') or o.get('condition'))
                                                        for o in options.values())):
                item['choices'] = [{'text': str(o.get('text', '')), 'link': str(o.get('link', 'END')),
                                    'condition': bool(o.get('condition'))} for o in options.values() if isinstance(o, dict)]
            items.append(item)
        elif kind == '3':
            items.append({'id': node_id, 'kind': SIGNAL, 'value': str(node.get('signalValue', ''))})
        elif kind == '4':
            op = node.get('type', 0)
            op = SET_OPS[op] if isinstance(op, int) and 0 <= op < len(SET_OPS) else f'(op {op})'
            items.append({'id': node_id, 'kind': 'other', 'type': 'set',
                          'summary': f'set {node.get("variable", "?")} {op} {node.get("value", "")}'})
        elif kind == '5':
            op = node.get('operator', 0)
            op = CONDITION_OPS[op] if isinstance(op, int) and 0 <= op < len(CONDITION_OPS) else f'(op {op})'
            items.append({'id': node_id, 'kind': 'other', 'type': 'condition',
                          'summary': f'if {node.get("value1", "")} {op} {node.get("value2", "")}: '
                                     f'then {node.get("true", "END")}, else {node.get("false", "END")}'})
        else:
            items.append({'id': node_id, 'kind': 'other', 'type': TYPE_NAMES.get(kind, 'node'),
                          'summary': f'{TYPE_NAMES.get(kind, "node")} {node_id}'})
    return items


# ---------------------------------------------------------------- changing a file

def bad(message):
    return EditorError(message, 400, code='bad-request')


def check_int(item, field, default=None):
    value = item.get(field, default)
    if not isinstance(value, int) or isinstance(value, bool) or not -1 <= value <= 1_000_000:
        raise bad(f'{field} must be a number from -1 up (got {value!r})')
    return value


def check_text(value, field):
    if not isinstance(value, str):
        raise bad(f'{field} must be text (got {value!r})')
    if '\x00' in value:
        raise bad(f'{field} has a NUL character in it')
    try:
        value.encode('utf-8')
    except UnicodeEncodeError:
        raise bad(f'{field} has a broken character in it (half of an emoji or similar)')
    return value


def clean_item(item):
    """A line or signal from the page, checked, with only the fields a save uses."""
    if not isinstance(item, dict):
        raise bad('each item must be an object')
    kind = item.get('kind')
    node_id = item.get('id')
    if node_id is not None and not isinstance(node_id, str):
        raise bad(f'an item id must be text (got {node_id!r})')
    if kind == LINE:
        speaker = item.get('speaker', '')
        if isinstance(speaker, bool) or not isinstance(speaker, (int, str)):
            raise bad(f'speaker must be a character number or a name (got {speaker!r})')
        if isinstance(speaker, int):
            check_int(item, 'speaker')
        else:
            check_text(speaker, 'speaker')
        clean = {'id': node_id, 'kind': LINE, 'speaker': speaker, 'text': check_text(item.get('text', ''), 'text'),
                 'backgroundList': check_int(item, 'backgroundList', -1), 'background': check_int(item, 'background', -1)}
        if 'characterState' in item and item['characterState'] is not None:
            clean['characterState'] = check_int(item, 'characterState')
        return clean
    if kind == SIGNAL:
        return {'id': node_id, 'kind': SIGNAL, 'value': check_text(item.get('value', ''), 'value')}
    raise bad(f'an item must be a line or a signal (got kind {kind!r})')


def clean_change(change):
    if not isinstance(change, dict):
        raise bad('each change must be an object')
    op, key = change.get('op'), change.get('key')
    if op not in ('chain', 'add', 'delete'):
        raise bad(f'unknown change {op!r}: use chain, add or delete')
    if not isinstance(key, str) or not key:
        raise bad('a change needs the start key')
    clean = {'op': op, 'key': key}
    if op == 'add' and not START_KEY.fullmatch(key):
        raise bad(f'"{key}" is not a usable start key: use letters, digits and underscores')
    if op == 'add' and change.get('after') is not None:
        if not isinstance(change['after'], str):
            raise bad(f'{key}: after must be a start key')
        clean['after'] = change['after']
    if op in ('chain', 'delete'):
        if not isinstance(change.get('base'), str):
            raise bad(f'{key}: the change needs the fingerprint the start had when you opened it (base)')
        clean['base'] = change['base']
    if op in ('chain', 'add'):
        items = change.get('items', [])
        if not isinstance(items, list):
            raise bad(f'{key}: items must be a list')
        clean['items'] = []
        for index, item in enumerate(items):
            try:
                clean['items'].append(clean_item(item))
            except EditorError as e:
                # Say which line, so the page can show it (a NUL pasted in is invisible).
                raise EditorError(f'{key}, item {index + 1}: {e}', 400, code='bad-request', key=key, item=index)
    return clean


class Edit:
    """Changes to one read file, made in memory; text() is the file with them."""

    def __init__(self, doc):
        self.doc = doc
        self.order = list(doc.order)
        self.nodes = dict(doc.nodes)
        self.raw = dict(doc.raw)
        self.keys = dict(doc.keys)
        self.starts = list(doc.starts)
        self.starts_changed = False
        self.numbers = doc.numbers()
        self.touched = set()

    def new_id(self, kind):
        number = self.numbers.get(kind, 0) + 1
        self.numbers[kind] = number
        return f'{kind}_{number}'

    def put(self, node_id, value, after=None, index=None):
        """Sets a node. An unchanged one keeps its text; a new one goes right after its predecessor."""
        if node_id in self.nodes:
            if self.nodes[node_id] == value:
                return
            self.nodes[node_id] = value
            self.raw[node_id] = None
        else:
            self.nodes[node_id] = value
            self.raw[node_id] = None
            self.keys[node_id] = Name(node_id) if self.doc.name_keys else node_id
            if index is None:
                index = self.order.index(after) + 1 if after in self.order else len(self.order)
            self.order.insert(index, node_id)
        self.touched.add(node_id)

    def drop(self, node_id):
        if node_id in self.nodes:
            del self.nodes[node_id], self.raw[node_id], self.keys[node_id]
            self.order.remove(node_id)
            self.touched.add(node_id)

    def chain(self, key, items, old_ids):
        """Makes a start run through these items. Items keep their node when its id is one of this
        start's own nodes of the same kind; the rest get new ids. Returns the items as written."""
        start_id = dict(self.starts)[key]
        old = set(old_ids)
        ids, used = [], set()
        for item in items:
            kind = KIND_TYPE[item['kind']]
            node_id = item.get('id')
            if not (node_id in old and node_id not in used and node_type(node_id) == kind):
                node_id = self.new_id(kind)
            used.add(node_id)
            ids.append(node_id)
        places = self.layout(start_id, ids, list(old_ids)) if ids != list(old_ids) else {}
        start = dict(self.nodes[start_id])
        written = []
        for n, (node_id, item) in enumerate(zip(ids, items)):
            link = Name(ids[n + 1]) if n + 1 < len(ids) else 'END'
            node = dict(self.nodes[node_id]) if node_id in old else {}
            if item['kind'] == LINE:
                state = item.get('characterState', node.get('characterState', -1))
                node.update({'background': item['background'], 'backgroundList': item['backgroundList'],
                             'characterState': state, 'dialogue': item['text'], 'speaker': item['speaker'],
                             'options': {0: {'condition': {}, 'link': link, 'text': ''}}})
                if node_id not in old:
                    node['size'] = NODE_SIZE
                written.append({'id': node_id, 'kind': LINE, 'speaker': item['speaker'], 'text': item['text'],
                                'backgroundList': item['backgroundList'], 'background': item['background'],
                                'characterState': state})
            else:
                node.update({'link': link, 'signalValue': item['value']})
                written.append({'id': node_id, 'kind': SIGNAL, 'value': item['value']})
            if node_id in places:
                node['offset'] = vector_text(*places[node_id])
            self.put(node_id, node, after=ids[n - 1] if n else start_id)
        for node_id in old_ids:
            if node_id not in used:
                self.drop(node_id)
        start['link'] = Name(ids[0]) if ids else 'END'
        self.put(start_id, start)
        return written

    def box(self, node_id, at=None):
        x, y = at or offset_of(self.nodes.get(node_id))
        return (x, y) + tuple(size_of(node_id, self.nodes.get(node_id)))

    def layout(self, start_id, ids, old_ids):
        """Where a changed chain's nodes go in Godot's graph, as {node id: (x, y)} for each node that
        is new or moves. Nothing lands on another node:
        - a chain that was a row to the right of its start node (as the art packager lays them out),
          or had no nodes, is laid out as a row again, when that row is clear of every other node;
        - otherwise every kept node stays where it is (it may have been placed by hand, and hand-laid
          files are packed tight), and each new node goes to the right of the one before it, or the
          nearest free place to there."""
        chain = set(ids) | set(old_ids) | {start_id}
        others = [self.box(n) for n in self.order if n not in chain]
        sx, sy = offset_of(self.nodes[start_id])
        old = set(old_ids)
        xs = [offset_of(self.nodes[n])[0] for n in old_ids]
        was_row = all(offset_of(self.nodes[n])[1] == sy for n in old_ids) and all(a < b for a, b in zip([sx] + xs, xs))
        if was_row:
            row, x = {}, sx + FIRST_NODE_GAP
            for n in ids:
                row[n] = (x, sy)
                x += step_after(n, self.nodes.get(n))
            if not any(overlaps(self.box(n, at), o) for n, at in row.items() for o in others):
                return {n: at for n, at in row.items() if n not in old or at != offset_of(self.nodes[n])}
        pos = {n: offset_of(self.nodes[n]) for n in ids if n in old}
        taken = others + [self.box(n, at) for n, at in pos.items()] + [self.box(start_id)]
        placed = {}
        for i, node_id in enumerate(ids):
            if node_id in pos:
                continue
            px, py = pos[ids[i - 1]] if i else (sx, sy)
            w, h = size_of(node_id, None)
            x, y = free_spot(px + (step_after(ids[i - 1], self.nodes.get(ids[i - 1])) if i else FIRST_NODE_GAP), py, w, h, taken)
            pos[node_id] = placed[node_id] = (x, y)
            taken.append((x, y, w, h))
        return placed

    def add(self, key, items, after=None):
        """A new start key with its chain, in the start list after `after` (or at the end), and in
        the graph at the start nodes' x, below every node there is."""
        start_nodes = [n for n in self.order if node_type(n) == '0' and isinstance(self.nodes[n], dict)]
        lowest = max(start_nodes, key=lambda n: offset_of(self.nodes[n])[1], default=None)
        x, y = offset_of(self.nodes[lowest]) if lowest else (0.0, -NEW_START_GAP)
        y += NEW_START_GAP
        bottoms = [box[1] + box[3] for box in (self.box(n) for n in self.order if isinstance(self.nodes[n], dict))]
        if bottoms:
            y = max(y, max(bottoms) + ROW_GAP)
        start_id = self.new_id('0')
        node = {'link': 'END', 'offset': vector_text(x, y), 'start_id': key}
        if start_nodes:
            self.put(start_id, node, after=max(start_nodes, key=self.order.index))
        else:
            self.put(start_id, node, index=0)
        keys = [k for k, _ in self.starts]
        at = keys.index(after) + 1 if after in keys else len(self.starts)
        self.starts.insert(at, (key, start_id))
        self.starts_changed = True
        return self.chain(key, items, [])

    def delete(self, key, walk):
        for node_id in walk.ids:
            self.drop(node_id)
        self.drop(walk.start_id)
        self.starts = [(k, v) for k, v in self.starts if k != key]
        self.starts_changed = True

    def text(self):
        doc = self.doc
        pieces = []
        if self.starts_changed:
            entries = [doc.start_raw.get(k) if k in doc.start_raw and doc.start_ids[k] == v
                       else f'{write(k)}: {write(Name(v))}' for k, v in self.starts]
            pieces.append((doc.starts_span, godot_body(entries)))
        if self.touched:
            entries = [self.raw[n] if self.raw[n] is not None else f'{write(self.keys[n])}: {write(godot_order(self.nodes[n]))}'
                       for n in self.order]
            pieces.append((doc.nodes_span, godot_body(entries)))
        text = doc.text
        for (start, end), body in sorted(pieces, reverse=True):
            text = text[:start] + body + text[end:]
        return text


def plain_items(items):
    return [{k: v for k, v in item.items() if k in ('id', 'kind', 'speaker', 'text', 'backgroundList', 'background',
                                                     'characterState', 'value')} for item in items]


def verify(old, text, changes, written, touched):
    """Checks a file's new text says exactly what the save meant, and nothing else moved. Returns
    the problem, or None."""
    try:
        new = Doc(text)
    except EditorError as e:
        return str(e)
    if new.problem:
        return new.problem
    if not new.dangling() <= old.dangling():
        return f'a link points nowhere: {sorted(new.dangling() - old.dangling())[:3]}'
    changed = {c['key'] for c in changes}
    for change in changes:
        key = change['key']
        if change['op'] == 'delete':
            if key in new.start_ids:
                return f'{key} is still there'
            gone = old.walk(key)
            left = [n for n in gone.ids + [gone.start_id] if n in new.nodes]
            if left:
                return f'{key}: {left[0]} is still there'
            continue
        if key not in new.start_ids:
            return f'{key} is missing'
        walk = new.walk(key)
        if not walk.editable:
            return f'{key} is not a plain chain after saving: {walk.reason}'
        if plain_items(doc_items(new, walk)) != plain_items(written[key]):
            return f'{key} does not read back as written'
    for key, _ in old.starts:
        if key in changed:
            continue
        if key not in new.start_ids:
            return f'{key} went missing'
        before, after = old.walk(key), new.walk(key)
        if (before.fingerprint, before.reason, before.ids) != (after.fingerprint, after.reason, after.ids):
            return f'{key} changed, though the save did not touch it'
    for node_id in old.order:
        if node_id not in touched and new.raw.get(node_id) != old.raw[node_id]:
            return f'node {node_id} changed, though the save did not touch it'
    first = min(old.starts_span[0], old.nodes_span[0])
    if text[:first] != old.text[:first] or text[len(text) - (len(old.text) - old.nodes_span[1]):] != old.text[old.nodes_span[1]:]:
        return 'the file outside its starts and nodes changed'
    return None


def write_text(path, text):
    """Writes a file whole or not at all (through a temporary file), trying again for a moment when
    Windows says it is locked: OneDrive or an editor can hold a file briefly. Whether it is already
    the same is decided on the exact text (package.save_text reads with newlines translated, so a
    line break changed from \\r to \\n would look like no change and never be written)."""
    try:
        if read_text(path) == text:
            return
    except OSError:
        pass
    last = None
    tmp = path.with_name(path.name + '.tmp')
    for attempt in range(10):
        try:
            with open(tmp, 'w', encoding='utf-8', newline='') as f:
                f.write(text)
            os.replace(tmp, path)
            return
        except PermissionError as e:
            last = e
            time.sleep(0.15 * (attempt + 1))
        except OSError as e:
            tmp.unlink(missing_ok=True)
            raise EditorError(f'could not write {path.name} ({e}). The file is as it was.', 500, code='write-failed')
    try:
        tmp.unlink(missing_ok=True)
    except OSError:
        pass
    raise EditorError(f'could not write {path.name}: it stayed locked ({last}). Nothing was changed; try again.', 503,
                      code='locked')


# ---------------------------------------------------------------- the project around the dialogue

def resource_text_value(section, name):
    """A [resource] string property, unescaped."""
    pos = prop_at(section, name)
    if pos is None:
        return ''
    try:
        value = Reader(section, pos).value()
    except (P.PackageError, IndexError):
        return ''
    return value if isinstance(value, str) and not isinstance(value, Raw) else ''


def array_refs(text, name):
    """The (kind, id) of each ExtResource/SubResource in a top-level typed array property."""
    found = re.search(rf'^{name} = Array\[[^\n]*?\]\(\[(.*)\]\)$', text, re.MULTILINE)
    return re.findall(r'(ExtResource|SubResource)\("([^"]+)"\)', found.group(1)) if found else []


def sub_resources(text):
    """id -> body text of each [sub_resource] block."""
    return {m.group(1): m.group(2) for m in
            re.finditer(r'^\[sub_resource [^\n]*id="([^"]+)"\]\n(.*?)(?=^\[|\Z)', text, re.MULTILINE | re.DOTALL)}


def colour(section):
    found = re.search(r'^color = Color\(([^)]*)\)', section, re.MULTILINE)
    if not found:
        return '#ffffff'
    try:
        parts = [float(n) for n in found.group(1).split(',')][:3]
    except ValueError:
        return '#ffffff'
    return '#' + ''.join(f'{max(0, min(255, round(p * 255))):02x}' for p in parts)


def stage_list(section, refs, name):
    entries = []
    found = re.search(rf'^{name} = Array\[[^\n]*?\]\(\[(.*)\]\)$', section, re.MULTILINE)
    for index, ref in enumerate(re.findall(r'ExtResource\("([^"]+)"\)', found.group(1)) if found else []):
        res = refs.get(ref, '')
        entries.append({'index': index, 'name': res.rsplit('/', 1)[-1] if res else f'#{index}', 'path': res})
    return entries


def safe_note_html(text):
    """Notes come from a local file, with a little HTML (<b>, <code>). Everything is escaped except
    those few plain tags, so the page can show them as they are written."""
    text = html.escape(str(text), quote=False)
    return re.sub(r'&lt;(/?)(b|i|em|strong|code)&gt;', r'<\1\2>', text)


def snippet(text, at, length, around=40):
    start = max(0, at - around)
    end = min(len(text), at + length + around)
    piece = text[start:end].replace('\n', ' ')
    return ('…' if start else '') + piece + ('…' if end < len(text) else ''), at - start + (1 if start else 0)


# ---------------------------------------------------------------- the signals the game knows

SIGNAL_SOURCES = (
    ('src/vn/Main.gd', '_on_dialogue_manager_dialogue_signal'),
    ('src/vn/DialogueManager.gd', '_on_dialogue_player_dialogue_signal'),
    ('src/cinematic/cinematic_layer.gd', 'handleSignal'),
)
ATMOSPHERE_SCENE = 'src/cinematic/CinematicLayer.tscn'
# The script whose PICTURE_VIDEO_LISTS names the files listing each picture's videos (it plays them).
VIDEO_LISTS_SOURCE = 'src/vn/Background.gd'


def function_body(text, name):
    """(first line number, lines) of a GDScript function, up to the next top-level line."""
    lines = text.split('\n')
    for number, line in enumerate(lines):
        if re.match(rf'^(static\s+)?func\s+{re.escape(name)}\s*\(', line):
            body = []
            for later in lines[number + 1:]:
                if later.strip() and not later[0].isspace() and not later.startswith('#'):
                    break
                body.append(later)
            return number + 2, body
    return None, []


def split_comment(code):
    """GDScript code and its trailing # comment (a # inside a string doesn't count)."""
    quote = None
    for index, char in enumerate(code):
        if quote:
            if char == quote:
                quote = None
        elif char in '"\'':
            quote = char
        elif char == '#':
            return code[:index].strip(), code[index + 1:].strip()
    return code.strip(), ''


def read_signals(project):
    """The signal values the game reacts to, read from its own code so the list stays current:
    exact values (with the code's comment, or the call, as the description) and number patterns."""
    exact, patterns = {}, []
    for rel, function in SIGNAL_SOURCES:
        path = project / rel
        if not path.exists():
            continue
        first, body = function_body(read_text(path), function)
        for offset, line in enumerate(body):
            source = f'res://{rel}:{first + offset}'
            arm = re.match(r'^\s*"([^"]+)"\s*:\s*(.*)$', line)
            if arm:
                code, comment = split_comment(arm.group(2))
                exact.setdefault(arm.group(1), {'value': arm.group(1), 'description': comment or code, 'source': source})
                continue
            for prefix in re.findall(r'begins_with\("([^"]+)"\)', line):
                following = ' '.join(body[offset:offset + 4])
                if prefix == 'atmosphere_':
                    for name in atmospheres(project):
                        value = f'atmosphere_{name.lower()}'
                        exact.setdefault(value, {'value': value, 'description': f'starts the {name} atmosphere over the picture',
                                                 'source': f'res://{ATMOSPHERE_SCENE}'})
                    exact.setdefault('atmosphere_off', {'value': 'atmosphere_off', 'description': 'lets the atmosphere die away',
                                                        'source': source})
                    patterns.append({'value': 'atmosphere_<name>', 'prefix': prefix, 'kind': 'atmosphere',
                                     'description': 'an atmosphere by its node name in CinematicLayer.tscn', 'source': source})
                elif 'int(' in following:
                    kind = 'sound' if 'sound' in following.lower() or 'sfx' in prefix else 'music' if 'music' in following.lower() else 'number'
                    what = {'sound': "sound effect n of the stage's soundEffectList",
                            'music': "track n of the stage's musicList"}.get(kind, 'number n')
                    patterns.append({'value': f'{prefix}<n>', 'prefix': prefix, 'kind': kind,
                                     'description': f'plays {what}', 'source': source})
                else:
                    patterns.append({'value': f'{prefix}…', 'prefix': prefix, 'kind': 'prefix',
                                     'description': split_comment(line)[1] or line.strip(), 'source': source})
            for value in re.findall(r'value\s*==\s*"([^"]+)"', line):
                following = split_comment(body[offset + 1])[0] if offset + 1 < len(body) else ''
                exact.setdefault(value, {'value': value, 'description': split_comment(line)[1] or following,
                                         'source': source})
    return {'exact': exact, 'patterns': patterns}


def atmospheres(project):
    path = project / ATMOSPHERE_SCENE
    if not path.exists():
        return []
    return re.findall(r'^\[node name="([^"]+)"[^\n]*parent="Atmosphere"', read_text(path), re.MULTILINE)


# ---------------------------------------------------------------- the editor's view of a project

class FileEntry:
    def __init__(self, res, stamp, text):
        self.res = res
        self.stamp = stamp
        self.version = sha1(text)
        self.error = None
        self.doc = None
        try:
            self.doc = Doc(text)
        except EditorError as e:
            self.error = str(e)
        except Exception as e:  # odd in a way the reader didn't expect: unreadable, not a crash
            print_problem(res, e)
            self.error = f'could not read this dialogue file: {e}'
        self.view = None
        self.view_key = None
        self.search = None


class Editor:
    """The dialogue files of one Godot project, read on demand and cached until they change."""

    def __init__(self, project, image_root=None, backups=None, cache=None, config=None, done=None):
        self.project = Path(project).resolve()
        if not (self.project / 'project.godot').exists():
            raise EditorError(f'{self.project} is not a Godot project (no project.godot)', 500)
        self.image_root = Path(image_root).resolve() if image_root else self.project
        self.backups = Path(backups).resolve() if backups else TOOL_DIR / 'backups'
        self.cache_dir = Path(cache).resolve() if cache else TOOL_DIR / 'cache'
        self.config_path = Path(config).resolve() if config else TOOL_DIR / 'config.json'
        # Under the project given, so an editor on a copy of the project (the tests) marks the copy.
        self.done_path = Path(done).resolve() if done else self.project / 'tooling' / 'dialogue_editor' / DONE_FILE
        self.done_lock = threading.Lock()
        self.matches_path = self.done_path.with_name(MATCHES_FILE)
        self.matches_lock = threading.Lock()
        self.wallpapers_path = self.done_path.with_name(WALLPAPERS_FILE)
        self.wallpapers_lock = threading.Lock()
        self.lock = threading.RLock()
        self.save_lock = threading.Lock()
        self.thumb_slots = threading.BoundedSemaphore(max(2, min(8, os.cpu_count() or 2)))
        self._files = {}
        self._side = {}
        self._scan = (0.0, [], [])
        self._status = (0.0, None)
        self._pictures = {}
        self._resolved = {}

    # ---- paths

    def path(self, res, root=None):
        """The file a res:// path names. Anything that would leave the project is refused."""
        if not isinstance(res, str) or not res.startswith('res://'):
            raise EditorError('give a res:// path', 400, code='bad-path')
        root = root or self.project
        known = self._resolved.get((res, root))
        if known:
            return known
        rel = res[len('res://'):]
        if not rel or '\\' in rel or ':' in rel or '\x00' in rel or rel.startswith('/'):
            raise EditorError(f'{res} is not a usable res:// path', 400, code='bad-path')
        if any(part in ('', '.', '..') for part in rel.split('/')):
            raise EditorError(f'{res} leaves the project', 403, code='outside')
        path = (root / rel).resolve()
        if not path.is_relative_to(root):
            raise EditorError(f'{res} leaves the project', 403, code='outside')
        if len(self._resolved) < 50_000:
            self._resolved[(res, root)] = path
        return path

    def res(self, path):
        return 'res://' + Path(path).relative_to(self.project).as_posix()

    # ---- finding the files

    def scan(self, force=False):
        """(dialogue res paths, stage files) in the project; looked for again every few seconds.
        Folders Godot ignores (a dot name, or a .gdignore inside) are skipped."""
        with self.lock:
            when, dialogues, stages = self._scan
            if not force and dialogues and time.monotonic() - when < SCAN_EVERY:
                return dialogues, stages
            dialogues, stages = [], []
            for folder, dirs, files in os.walk(self.project):
                dirs[:] = sorted(d for d in dirs if not d.startswith('.') and not os.path.exists(os.path.join(folder, d, '.gdignore')))
                for name in sorted(files):
                    if not name.endswith('.tres'):
                        continue
                    full = os.path.join(folder, name)
                    try:
                        with open(full, 'rb') as f:
                            head = f.read(400)
                    except OSError:
                        continue
                    if b'script_class="DialogueData"' in head:
                        dialogues.append(self.res(full))
                    elif b'script_class="GameStage"' in head:
                        stages.append(full)
            self._scan = (time.monotonic(), dialogues, stages)
            return dialogues, stages

    def entry(self, res, known=True):
        """A dialogue file, read again only when it changed on disk."""
        path = self.path(res)
        if known and res not in self.scan()[0] and res not in self.scan(force=True)[0]:
            raise EditorError(f'{res} is not a dialogue file in this project', 404, code='not-found')
        with self.lock:
            stamp = stamp_of(path)
            if stamp is None:
                raise EditorError(f'{res} is not there any more', 404, code='not-found')
            cached = self._files.get(res)
            if cached and cached.stamp == stamp:
                return cached
            try:
                text = read_text(path)
            except (OSError, UnicodeDecodeError) as e:  # locked for a moment (OneDrive), or not text
                raise EditorError(f'could not read {res}: {e}', 503, code='unreadable')
            entry = FileEntry(res, stamp, text)
            self._files[res] = entry
            return entry

    def forget(self, res):
        with self.lock:
            self._files.pop(res, None)

    # ---- side files, cached by their own stamp

    def side(self, path, reader):
        """A file a dialogue names (characters, picture lists, stages), read again when it changes.
        Its date is looked at once a second at most: a search reads every file's view, and each
        view names dozens of these."""
        path = Path(path)
        now = time.monotonic()
        with self.lock:
            cached = self._side.get((path, reader.__name__))
            if cached and now - cached[2] < SIDE_EVERY:
                return cached[1], cached[0]
        stamp = stamp_of(path)
        with self.lock:
            if cached and cached[0] == stamp:
                self._side[(path, reader.__name__)] = (stamp, cached[1], now)
                return cached[1], stamp
        value = reader(path) if stamp is not None else None
        with self.lock:
            self._side[(path, reader.__name__)] = (stamp, value, now)
        return value, stamp

    def characters(self, res):
        """The dialogue's speakers by position: name, editor name, colour and state names."""
        if not res:
            return [], None
        try:
            path = self.path(res)
        except EditorError:
            return [], None
        listing, stamp = self.side(path, self._read_character_list)
        if not listing:
            return [], stamp
        stamps = [stamp]
        found = []
        for index, (kind, ref) in enumerate(listing['refs']):
            character = None
            if kind == 'ExtResource' and listing['paths'].get(ref):
                try:
                    character, char_stamp = self.side(self.path(listing['paths'][ref]), self._read_character)
                    stamps.append(char_stamp)
                except EditorError:
                    character = None
            elif kind == 'SubResource' and ref in listing['subs']:
                character = self._character_from(listing['subs'][ref], {}, {})
            character = character or {'name': '', 'editorName': '', 'color': '#ffffff', 'states': []}
            found.append({'index': index, **character})
        return found, tuple(stamps)

    @staticmethod
    def _read_character_list(path):
        text = read_text(path)
        return {'refs': array_refs(text, 'characters'), 'paths': P.ext_resources(text), 'subs': sub_resources(text)}

    def _read_character(self, path):
        text = read_text(path)
        return self._character_from(P.resource_section(text), P.ext_resources(text), sub_resources(text))

    def _character_from(self, section, refs, subs):
        states = []
        for kind, ref in array_refs(section, 'states'):
            if kind == 'SubResource' and ref in subs:
                states.append(resource_text_value(subs[ref], 'name'))
            elif kind == 'ExtResource' and refs.get(ref):
                try:
                    states.append(resource_text_value(P.resource_section(read_text(self.path(refs[ref]))), 'name'))
                except (EditorError, OSError):
                    states.append('')
            else:
                states.append('')
        return {'name': resource_text_value(section, 'name'), 'editorName': resource_text_value(section, 'editorName'),
                'color': colour(section), 'states': states}

    def lists(self, res):
        """The dialogue's picture lists by position, each with its pictures by position."""
        if not res:
            return [], None
        try:
            path = self.path(res)
        except EditorError:
            return [], None
        listing, stamp = self.side(path, self._read_lists)
        if not listing:
            return [], stamp
        stamps = [stamp]
        found = []
        for index, list_res in enumerate(listing):
            pictures, name = [], Path(list_res).stem if list_res else f'#{index}'
            if list_res:
                try:
                    content, list_stamp = self.side(self.path(list_res), self._read_list)
                    stamps.append(list_stamp)
                    if content:
                        name = content['name'] or name
                        pictures = content['pictures']
                except EditorError:
                    pass
            found.append({'index': index, 'name': name, 'path': list_res, 'pictures': pictures})
        return found, tuple(stamps)

    @staticmethod
    def _read_lists(path):
        text = read_text(path)
        refs = P.ext_resources(text)
        return [refs.get(ref, '') for kind, ref in array_refs(text, 'backgroundLists')]

    def _read_list(self, path):
        text = read_text(path)
        subs, refs = sub_resources(text), P.ext_resources(text)
        pictures = []
        for index, (kind, ref) in enumerate(array_refs(P.resource_section(text), 'images')):
            body = subs.get(ref) if kind == 'SubResource' else None
            if kind == 'ExtResource' and refs.get(ref):
                try:
                    body = P.resource_section(read_text(self.path(refs[ref])))
                except (EditorError, OSError):
                    body = None
            pictures.append({'index': index, 'name': resource_text_value(body or '', 'name'),
                             'image': resource_text_value(body or '', 'imagePath')})
        return {'name': resource_text_value(P.resource_section(text), 'name'), 'pictures': pictures}

    def picture_videos(self):
        """picture res path -> its videos [{video, loop, intro?}], as the game reads them: the files
        Background.gd's PICTURE_VIDEO_LISTS names, the first to list a picture winning. The game
        plays a picture's first video."""
        names, stamp = self.side(self.project / VIDEO_LISTS_SOURCE, self._read_video_list_names)
        found, stamps = {}, [stamp]
        for res in names or []:
            try:
                videos, stamp = self.side(self.path(res), self._read_picture_videos)
            except EditorError:
                continue
            stamps.append(stamp)
            for picture, listed in (videos or {}).items():
                found.setdefault(picture, listed)
        return found, tuple(stamps)

    @staticmethod
    def _read_video_list_names(path):
        try:
            listed = re.search(r'^const PICTURE_VIDEO_LISTS\s*=\s*\[(.*?)\]', read_text(path), re.MULTILINE | re.DOTALL)
        except (OSError, UnicodeDecodeError):
            return []
        return re.findall(r'"(res://[^"]+)"', listed.group(1)) if listed else []

    @staticmethod
    def _read_picture_videos(path):
        """A videos.gd (tooling/video_gen/finish.py writes it): "picture": [{"video": ..., "loop": ...}, ...]
        entries, each {...} being JSON as it stands."""
        try:
            text = read_text(path)
        except (OSError, UnicodeDecodeError):
            return {}
        found = {}
        for picture, body in re.findall(r'"(res://[^"]+)"\s*:\s*\[(.*?)\]', text, re.DOTALL):
            videos = []
            for entry in re.findall(r'\{[^{}]*\}', body):
                try:
                    video = json.loads(entry)
                except ValueError:
                    continue
                if isinstance(video, dict) and isinstance(video.get('video'), str):
                    videos.append(video)
            if videos:
                found[picture] = videos
        return found

    def picture_facts(self, image_res):
        """(exists, modified-time tag) of a picture, looked at again every little while."""
        now = time.monotonic()
        with self.lock:
            cached = self._pictures.get(image_res)
            if cached and now - cached[0] < STAT_EVERY:
                return cached[1]
        try:
            stamp = stamp_of(self.path(image_res, self.image_root))
        except EditorError:
            stamp = None
        facts = (stamp is not None, f'{stamp[0] // 1_000_000:x}' if stamp else '')
        with self.lock:
            self._pictures[image_res] = (now, facts)
        return facts

    def list_size(self, pictures):
        """The width and height of a list's first picture there is (the frame it plays in)."""
        for picture in pictures:
            if picture['image'] and self.picture_facts(picture['image'])[0]:
                try:
                    size, _ = self.side(self.path(picture['image'], self.image_root), self._image_size)
                    return size
                except EditorError:
                    return None
        return None

    @staticmethod
    def _image_size(path):
        try:
            with Image.open(path) as img:
                return list(img.size)
        except OSError:
            return None

    def stages(self):
        """dialogue res -> the game stages that play it (name, display name, file, sounds, music)."""
        found = {}
        stamps = []
        for path in self.scan()[1]:
            stage, stamp = self.side(path, self._read_stage)
            stamps.append(stamp)
            if stage and stage['dialogue']:
                found.setdefault(stage['dialogue'], []).append(stage)
        return found, tuple(stamps)

    def _read_stage(self, path):
        text = read_text(path)
        section = P.resource_section(text)
        refs = P.ext_resources(text)
        dialogue = re.search(r'^dialogue = ExtResource\("([^"]+)"\)', section, re.MULTILINE)
        landscape = re.search(r'^isLandscape = (true|false)$', section, re.MULTILINE)
        name = resource_text_value(section, 'name')
        return {'name': name, 'displayName': resource_text_value(section, 'displayName') or name,
                'path': self.res(path), 'dialogue': refs.get(dialogue.group(1)) if dialogue else None,
                'isLandscape': landscape.group(1) == 'true' if landscape else False,
                'sounds': stage_list(section, refs, 'soundEffectList'), 'music': stage_list(section, refs, 'musicList')}

    def signals(self):
        stamps = tuple(stamp_of(self.project / rel) for rel, _ in SIGNAL_SOURCES) + (stamp_of(self.project / ATMOSPHERE_SCENE),)
        with self.lock:
            cached = self._side.get('signals')
            if cached and cached[0] == stamps:
                return cached[1], stamps
        catalog = read_signals(self.project)
        with self.lock:
            self._side['signals'] = (stamps, catalog)
        return catalog, stamps

    def notes_sources(self):
        """The scene notes named in config.json: per source, the stage names it covers, its scene
        words per start key, and its sequences per key. A missing or unreadable file is no notes."""
        config, config_stamp = self.side(self.config_path, self._read_json)
        sources, stamps = [], [config_stamp]
        for name in (config or {}).get('notes', []) if isinstance(config, dict) else []:
            path = Path(os.path.expanduser(str(name)))
            if not path.is_absolute():
                path = self.config_path.parent / path
            scene, stamp = self.side(path, self._read_json)
            stamps.append(stamp)
            if not isinstance(scene, dict):
                continue
            game = scene.get('game') if isinstance(scene.get('game'), dict) else {}
            guide = game.get('guide') if isinstance(game.get('guide'), dict) else {}
            stage_names = set(guide.get('stages') or [])
            sequences = {}
            for stage in scene.get('stages') or []:
                if isinstance(stage, dict):
                    stage_names.add(stage.get('name'))
                    for sequence in stage.get('sequences') or []:
                        if isinstance(sequence, dict) and sequence.get('key'):
                            sequences.setdefault(sequence['key'], sequence)
            scenes = guide.get('scenes') if isinstance(guide.get('scenes'), dict) else {}
            sources.append({'stages': stage_names, 'scenes': scenes, 'sequences': sequences})
        return sources, tuple(stamps)

    @staticmethod
    def _read_json(path):
        try:
            with open(path, encoding='utf-8') as f:
                return json.load(f)
        except (OSError, ValueError):
            return None

    def notes_for(self, sources, stage_names, key):
        for source in sources:
            if not source['stages'] & stage_names:
                continue
            scene = source['scenes'].get(key) if isinstance(source['scenes'].get(key), dict) else {}
            sequence = source['sequences'].get(key, {})
            notes = {field: safe_note_html(scene[field]) for field in ('title', 'when', 'next') if scene.get(field)}
            notes.update({field: safe_note_html(sequence[field]) for field in ('context', 'state', 'designRow')
                          if sequence.get(field) not in (None, '')})
            if notes:
                return notes
        return None

    # ---- what the page asks for

    def files(self):
        dialogues, _ = self.scan()
        stages, _ = self.stages()
        found = []
        for res in dialogues:
            try:
                found.append(self.file_entry(res, stages))
            except EditorError as e:
                found.append({'path': res, 'error': str(e)})
            except Exception as e:  # a bug, or a file odd in a way not thought of: the others still show
                print_problem(res, e)
                found.append({'path': res, 'error': f'the editor hit a problem reading it: {e}'})
        return {'project': str(self.project), 'files': found}

    def file_entry(self, res, stages):
        """One file in the file list: its counts, stages and start keys in brief."""
        entry = self.entry(res, known=False)
        folder, _, name = res.rpartition('/')
        under = res.removeprefix('res://data/game_stages/')
        item = {'path': res, 'name': name, 'folder': folder, 'kind': under.split('/')[0] if under != res and '/' in under else '',
                'stages': [{'name': s['name'], 'displayName': s['displayName'], 'path': s['path']} for s in stages.get(res, [])],
                'version': entry.version}
        if entry.error:
            item.update({'error': entry.error, 'startCount': 0, 'lineCount': 0, 'placeholderCount': 0, 'editable': False})
            return item
        doc = entry.doc
        walks = [doc.walk(key) for key, _ in doc.starts]
        lines = {n for w in walks for n in w.ids if node_type(n) == '1' and isinstance(doc.nodes.get(n), dict)}
        placeholder = {n for n in lines if str(doc.nodes[n].get('dialogue', '')).startswith(PLACEHOLDER)}
        # Every start key in brief, so the page's quick-open can find a key in any file without
        # reading them all.
        starts = []
        for walk in walks:
            own = [n for n in walk.ids if n in lines]
            starts.append({'key': walk.key, 'editable': walk.editable, 'lineCount': len(own),
                           'placeholderCount': sum(1 for n in own if n in placeholder)})
        # lists: the file naming its picture lists. Files with the same one show the same pictures,
        # which is how the page's gallery knows whose lines to count.
        item.update({'startCount': len(walks), 'lineCount': len(lines), 'placeholderCount': len(placeholder),
                     'editable': any(w.editable for w in walks), 'starts': starts, 'lists': doc.background_lists or ''})
        if doc.problem:
            item['problem'] = doc.problem
        return item

    def file(self, res):
        return self.view(self.entry(res))[0]

    def view(self, entry):
        """A file as the page shows it, and its search entries; rebuilt when it or anything it
        names (characters, picture lists and their picture files, stages, signals, notes) changes."""
        if entry.error:
            raise EditorError(f'{entry.res}: {entry.error}', 422, code='unreadable')
        try:
            return self._view(entry)
        except EditorError:
            raise
        except Exception as e:  # a bug, or a file odd in a way not thought of: say so, keep going
            print_problem(entry.res, e)
            raise EditorError(f'{entry.res}: the editor hit a problem reading it: {e}', 500, code='internal')

    def _view(self, entry):
        doc = entry.doc
        characters, c_stamp = self.characters(doc.characters)
        lists, l_stamp = self.lists(doc.background_lists)
        all_stages, s_stamp = self.stages()
        catalog, g_stamp = self.signals()
        sources, n_stamp = self.notes_sources()
        videos, v_stamp = self.picture_videos()
        # A picture file that appears or is saved again changes the view too (its thumbnail URL).
        facts = {picture['image']: self.picture_facts(picture['image'])
                 for item in lists for picture in item['pictures'] if picture['image']}
        key = (entry.stamp, c_stamp, l_stamp, s_stamp, g_stamp, n_stamp, v_stamp, sha1(repr(sorted(facts.items()))))
        with self.lock:
            if entry.view_key == key:
                return entry.view, entry.search
        stages = all_stages.get(entry.res, [])
        stage_names = {s['name'] for s in stages}
        sounds = next((s['sounds'] for s in stages if s['sounds']), [])
        music = next((s['music'] for s in stages if s['music']), [])

        shown_lists = []
        with_video = 0
        for item in lists:
            pictures = []
            for picture in item['pictures']:
                exists, tag = facts[picture['image']] if picture['image'] else (False, '')
                query = urllib.parse.quote(picture['image'], safe='')
                pictures.append({'index': picture['index'], 'name': picture['name'], 'image': picture['image'],
                                 'thumb': f'/img?path={query}&w={THUMB_WIDTH}&v={tag}' if exists else None,
                                 'full': f'/img?path={query}&v={tag}' if exists else None,
                                 **({} if exists else {'missing': True})})
                # The videos the game has for the picture (it plays the first, over the still).
                if videos.get(picture['image']):
                    with_video += 1
                    pictures[-1]['videos'] = [{'file': v['video'].rsplit('/', 1)[-1], 'path': v['video'], 'loop': v.get('loop') is True,
                                               'intro': isinstance(v.get('intro'), str)} for v in videos[picture['image']]]
            shown_lists.append({'index': item['index'], 'name': item['name'], 'path': item['path'],
                                'size': self.list_size(item['pictures']), 'pictures': pictures})

        starts = [self.start_view(doc, key_, sources, stage_names) for key_, _ in doc.starts]
        signals = [dict(s) for s in catalog['exact'].values()]
        counts = signal_counts(doc)
        totals = Counter()
        with self.lock:
            for other in list(self._files.values()):
                if other.doc:
                    totals.update(signal_counts(other.doc))
        for s in signals:
            s['count'] = counts.get(s['value'], 0)
            s['countAll'] = totals.get(s['value'], 0)
        for pattern in catalog['patterns']:
            signals.append(dict(pattern))
            known = sounds if pattern['kind'] == 'sound' else music if pattern['kind'] == 'music' else []
            for item in known:
                value = f'{pattern["prefix"]}{item["index"]}'
                signals.append({'value': value, 'description': f'plays {item["name"]}', 'source': pattern['source'],
                                'count': counts.get(value, 0)})
        view = {'path': entry.res, 'version': entry.version, 'characters': characters, 'lists': shown_lists,
                'starts': starts, 'stages': [{k: s[k] for k in ('name', 'displayName', 'path', 'isLandscape')} for s in stages],
                'sounds': sounds, 'music': music, 'signals': signals, 'videos': with_video}
        if doc.problem:
            view['problem'] = doc.problem
        search = self.search_entries(entry.res, starts, characters, lists)
        with self.lock:
            entry.view, entry.search, entry.view_key = view, search, key
        return view, search

    def start_view(self, doc, key, sources, stage_names):
        # The warnings on lines and signals are the page's (itemWarnings in editor.html): they
        # follow each edit there, and one copy of the rules can't drift from another.
        walk = doc.walk(key)
        items = doc_items(doc, walk)
        lines = [i for i in items if i['kind'] == LINE]
        view = {'key': key, 'nodeId': walk.start_id, 'editable': walk.editable, 'fingerprint': walk.fingerprint,
                'lineCount': len(lines), 'placeholderCount': sum(1 for i in lines if i['text'].startswith(PLACEHOLDER)),
                'items': items}
        if not walk.editable:
            view['reason'] = f'{walk.reason}: {READ_ONLY_HINT}'
        if walk.editable and not items:
            view['warnings'] = [EMPTY_CHAIN_NOTE]
        notes = self.notes_for(sources, stage_names, key)
        if notes:
            view['notes'] = notes
        return view

    def search_entries(self, res, starts, characters, lists):
        """(lowercased text, result) for everything a search can find in one file."""
        entries = []
        for start in starts:
            key = start['key']
            entries.append((key.lower(), {'path': res, 'key': key, 'itemIndex': None, 'field': 'key', 'text': key}))
            for index, item in enumerate(start['items']):
                base = {'path': res, 'key': key, 'itemIndex': index, 'id': item['id']}
                if item['kind'] == LINE:
                    if item['text']:
                        entries.append((item['text'].lower(), {**base, 'field': 'text', 'text': item['text']}))
                    speaker = item['speaker']
                    if isinstance(speaker, int):
                        speaker = characters[speaker]['name'] if 0 <= speaker < len(characters) else ''
                    if speaker:
                        entries.append((speaker.lower(), {**base, 'field': 'speaker', 'text': speaker}))
                    bl, bg = item['backgroundList'], item['background']
                    if 0 <= bl < len(lists) and 0 <= bg < len(lists[bl]['pictures']):
                        name = lists[bl]['pictures'][bg]['name']
                        if name:
                            entries.append((name.lower(), {**base, 'field': 'picture', 'text': name}))
                elif item['kind'] == SIGNAL:
                    entries.append((item['value'].lower(), {**base, 'field': 'signal', 'text': item['value']}))
        return entries

    def search(self, query, res=None, placeholder=False, limit=300):
        """Case-insensitive substring search over start keys, line text, speakers, picture names and
        signal values; or, with placeholder, every line still a placeholder."""
        query = (query or '').strip()
        if not query and not placeholder:
            return {'query': query, 'results': [], 'truncated': False}
        needle = query.lower()
        files = [res] if res else self.scan()[0]
        results, truncated = [], False
        for path in files:
            try:
                _, entries = self.view(self.entry(path))
            except EditorError:
                if res:
                    raise
                continue
            for text, found in entries:
                if placeholder:
                    if found['field'] != 'text' or not found['text'].startswith(PLACEHOLDER) or needle not in text:
                        continue
                    at = text.find(needle) if needle else 0
                else:
                    at = text.find(needle)
                    if at < 0:
                        continue
                if len(results) >= limit:
                    truncated = True
                    break
                piece, start = snippet(found['text'], at, len(needle))
                results.append({**{k: v for k, v in found.items() if k != 'text'}, 'snippet': piece,
                                'match': [start, start + len(needle)]})
            if truncated:
                break
        return {'query': query, 'results': results, 'truncated': truncated}

    def versions(self):
        found = {}
        for res in self.scan()[0]:
            try:
                found[res] = self.entry(res, known=False).version
            except EditorError:
                pass  # missing or locked for the moment: the next look sees it
        return found

    # ---- starts marked done

    def done(self):
        """The starts marked done on the page: {'done': {res path: {start key: when}}}. They're kept
        in done.json beside the editor, not in the dialogue files, so a mark changes nothing in the
        game. A missing or unreadable file is no marks."""
        data = self._read_json(self.done_path)
        marks = data.get('done') if isinstance(data, dict) else None
        clean = {}
        for res, keys in (marks or {}).items() if isinstance(marks, dict) else []:
            if isinstance(res, str) and isinstance(keys, dict):
                kept = {k: str(v) for k, v in keys.items() if isinstance(k, str) and k}
                if kept:
                    clean[res] = kept
        return {'done': clean}

    def mark_done(self, res, key, done):
        """Marks a start done (or not) and returns every mark. The file needn't have the start yet
        (a new start not saved), and a mark outlives its start, harmlessly."""
        if not isinstance(res, str) or not res.startswith('res://') or not res.endswith('.tres') or len(res) > 500:
            raise EditorError('give the res:// path of a dialogue file', 400, code='bad-path')
        if not isinstance(key, str) or not key.strip() or len(key) > 200 or any(ord(ch) < 32 for ch in key):
            raise EditorError('give a start key', 400, code='bad-request')
        if not isinstance(done, bool):
            raise EditorError('done is true or false', 400, code='bad-request')
        with self.done_lock:
            marks = self.done()['done']
            keys = marks.setdefault(res, {})
            if done:
                keys.setdefault(key, datetime.datetime.now().strftime('%Y-%m-%d %H:%M'))
            else:
                keys.pop(key, None)
            marks = {r: dict(sorted(k.items())) for r, k in sorted(marks.items()) if k}
            self.done_path.parent.mkdir(parents=True, exist_ok=True)
            write_text(self.done_path, json.dumps({'about': DONE_ABOUT, 'done': marks}, indent=1, ensure_ascii=False) + '\n')
        return {'done': marks}

    # ---- the picture each poker match opens on (Ashely II)

    def match_pictures(self):
        """The picks so far: {'picks': {situation: {'list', 'picture'}}}. None is no picks."""
        data = self._read_json(self.matches_path)
        picks = data.get('picks') if isinstance(data, dict) else None
        clean = {}
        for key, value in (picks or {}).items() if isinstance(picks, dict) else []:
            if isinstance(key, str) and MATCH_ID.fullmatch(key) and isinstance(value, dict)                     and isinstance(value.get('list'), str) and isinstance(value.get('picture'), str):
                clean[key] = {'list': value['list'], 'picture': value['picture']}
        return {'picks': clean}

    def set_match_pictures(self, changes):
        """Sets (or clears, with null) the picture of each situation given; returns every pick."""
        if not isinstance(changes, dict) or not changes or len(changes) > 200:
            raise EditorError('send {set: {situation: {list, picture} or null}}', 400, code='bad-request')
        for key, value in changes.items():
            if not isinstance(key, str) or not MATCH_ID.fullmatch(key):
                raise EditorError(f'not a match situation: {key!r}', 400, code='bad-request')
            if value is not None and not (isinstance(value, dict) and all(
                    isinstance(value.get(f), str) and 0 < len(value[f]) <= 200 for f in ('list', 'picture'))):
                raise EditorError(f'{key}: give {{list, picture}} names, or null', 400, code='bad-request')
        with self.matches_lock:
            picks = self.match_pictures()['picks']
            for key, value in changes.items():
                if value is None:
                    picks.pop(key, None)
                else:
                    picks[key] = {'list': value['list'], 'picture': value['picture']}
            picks = dict(sorted(picks.items()))
            self.matches_path.parent.mkdir(parents=True, exist_ok=True)
            write_text(self.matches_path, json.dumps({'about': MATCHES_ABOUT, 'picks': picks}, indent=1, ensure_ascii=False) + '\n')
        return {'picks': picks}

    # ---- the pictures picked as wallpapers (the Gallery's Wallpapers)

    def wallpapers(self):
        """The picks so far: {'picks': {picture file: {'list', 'picture'}}, 'seeded': {lists file: when}}."""
        data = self._read_json(self.wallpapers_path)
        data = data if isinstance(data, dict) else {}
        picks, seeded = data.get('picks'), data.get('seeded')
        clean = {}
        for image, value in picks.items() if isinstance(picks, dict) else []:
            if isinstance(image, str) and WALLPAPER_IMAGE.fullmatch(image) and isinstance(value, dict) \
                    and isinstance(value.get('list'), str) and isinstance(value.get('picture'), str):
                clean[image] = {'list': value['list'], 'picture': value['picture']}
        seeds = {k: str(v) for k, v in seeded.items() if isinstance(k, str)} if isinstance(seeded, dict) else {}
        return {'picks': clean, 'seeded': seeds}

    def set_wallpapers(self, changes, seed=None):
        """Picks (or, with null, unpicks) each picture file given, and returns every pick. seed: the picture lists
        (their BackgroundLists file) these picks were made for when Wallpapers was first turned on there."""
        if not isinstance(changes, dict) or len(changes) > 5000:
            raise EditorError('send {set: {picture file: {list, picture} or null}}', 400, code='bad-request')
        for image, value in changes.items():
            if not isinstance(image, str) or not WALLPAPER_IMAGE.fullmatch(image):
                raise EditorError(f'not a picture file: {image!r}', 400, code='bad-request')
            if value is not None and not (isinstance(value, dict) and all(
                    isinstance(value.get(f), str) and 0 < len(value[f]) <= 200 for f in ('list', 'picture'))):
                raise EditorError(f'{image}: give {{list, picture}} names, or null', 400, code='bad-request')
        if seed is not None and not (isinstance(seed, str) and seed.startswith('res://') and seed.endswith('.tres') and len(seed) <= 500):
            raise EditorError('seed is the res:// path of a picture lists file', 400, code='bad-request')
        with self.wallpapers_lock:
            current = self.wallpapers()
            picks, seeded = current['picks'], current['seeded']
            for image, value in changes.items():
                if value is None:
                    picks.pop(image, None)
                else:
                    picks[image] = {'list': value['list'], 'picture': value['picture']}
            if seed:
                seeded.setdefault(seed, datetime.datetime.now().strftime('%Y-%m-%d %H:%M'))
            picks, seeded = dict(sorted(picks.items())), dict(sorted(seeded.items()))
            self.wallpapers_path.parent.mkdir(parents=True, exist_ok=True)
            write_text(self.wallpapers_path, json.dumps({'about': WALLPAPERS_ABOUT, 'seeded': seeded, 'picks': picks},
                                                        indent=1, ensure_ascii=False) + '\n')
        return {'picks': picks, 'seeded': seeded}

    def addon_patched(self):
        """Whether the project's dialogue addon reloads a file changed on disk instead of saving its
        own copy over it (the EXTERNAL_EDIT_SAFE patch in its files.gd)."""
        try:
            return PATCH_MARKER in read_text(self.project / ADDON_FILES)
        except OSError:
            return False

    def status(self, fresh=False):
        with self.lock:
            when, cached = self._status
            if cached and not fresh and time.monotonic() - when < STATUS_EVERY:
                return cached
        status = {'godotRunning': P.godot_running(), 'addonPatched': self.addon_patched()}
        with self.lock:
            self._status = (time.monotonic(), status)
        return status

    def warm(self):
        """Reads every file once, so the first search is quick. All files are read before any view
        is built, so each view's project-wide signal counts (countAll) cover every file."""
        entries = []
        for res in self.scan(force=True)[0]:
            try:
                entries.append(self.entry(res, known=False))
            except EditorError:
                pass
        count = 0
        for entry in entries:
            try:
                self.view(entry)
                count += 1
            except EditorError:
                pass
        return count

    # ---- showing a file on this computer

    def reveal(self, res, play=False):
        """Shows a picture or video of the project in its folder, the file selected; play opens it
        in the program this computer uses for it instead. Only pictures and videos, only inside
        the project: a page asks for this, and it must not be a way to start anything else."""
        if not isinstance(res, str) or len(res) > 500:
            raise EditorError('give the res:// path of a picture or a video', 400, code='bad-path')
        path = self.path(res, self.image_root)
        if not path.is_file() and self.image_root != self.project:
            path = self.path(res)
        suffix = path.suffix.lower()
        if suffix not in IMAGE_TYPES and suffix not in VIDEO_TYPES:
            raise EditorError(f'{res} is not a picture or a video', 400, code='not-picture')
        if not path.is_file():
            raise EditorError(f'{res} is not there', 404, code='missing')
        return {'path': str(path), 'play': bool(play), 'launched': launch(path, bool(play))}

    # ---- pictures

    def image(self, res, width=None):
        """(bytes, content type) of a picture, or a JPEG thumbnail of it at most width wide (cached)."""
        path = self.path(res, self.image_root)
        content_type = IMAGE_TYPES.get(path.suffix.lower())
        if not content_type:
            raise EditorError(f'{res} is not a picture', 400, code='not-picture')
        if not path.is_file():
            raise EditorError(f'{res} is not there', 404, code='not-found')
        if width is None:
            return path.read_bytes(), content_type
        width = max(16, min(2048, int(width)))
        stamp = stamp_of(path)
        name = sha1(f'{path}|{stamp}|{width}') + '.jpg'
        thumbs = self.cache_dir / 'thumbs'
        thumb = thumbs / name
        if thumb.exists():
            return thumb.read_bytes(), 'image/jpeg'
        with self.thumb_slots:
            if thumb.exists():
                return thumb.read_bytes(), 'image/jpeg'
            try:
                with Image.open(path) as img:
                    img.thumbnail((width, width * 4))
                    out = BytesIO()
                    img.convert('RGB').save(out, 'JPEG', quality=85)
            except OSError as e:
                raise EditorError(f'could not read {res}: {e}', 422, code='bad-picture')
            data = out.getvalue()
            ignore_folder(self.cache_dir)
            thumbs.mkdir(parents=True, exist_ok=True)
            tmp = thumbs / (name + f'.{threading.get_ident()}.tmp')
            tmp.write_bytes(data)
            os.replace(tmp, thumb)
            return data, 'image/jpeg'

    # ---- saving

    def save(self, res, changes, confirm_godot=False):
        """Applies a page's changes to one file. See the module notes for the rules."""
        entry = self.entry(res)
        path = self.path(res)
        if not isinstance(changes, list):
            raise bad('changes must be a list')
        changes = [clean_change(c) for c in changes]
        keys = [c['key'] for c in changes]
        if len(set(keys)) != len(keys):
            raise bad('a start key is in the changes twice')
        # With the addon patched an open copy in Godot reloads instead of overwriting, so there is
        # nothing to ask; only then is the (slow) look at running programs skipped.
        if not confirm_godot and changes and not self.addon_patched():
            status = self.status()
            if status['godotRunning'] and not status['addonPatched']:
                raise EditorError('Godot is running, and its dialogue addon would save its own open copy of this file '
                                  'over the edit. Close the file in Godot (or Godot), or save anyway.', 409,
                                  code='godot-unpatched', godotRunning=status['godotRunning'])
        with self.save_lock:
            # Another program (Godot, the art packager) may write the file while this save is being
            # made: then it starts again from what is on disk now, and the fingerprints decide.
            for _ in range(3):
                result = self.save_once(res, path, changes)
                if result is not None:
                    return result
            raise EditorError(f'{path.name} kept changing on disk while saving (Godot or another program is writing '
                              'it). Nothing was saved: press Ctrl+S again in a moment.', 409, code='busy')

    def save_once(self, res, path, changes):
        """One go at a save; None when the file changed on disk meanwhile (nothing was written)."""
        stamp = stamp_of(path)
        text = read_text(path)
        doc = Doc(text)
        if doc.problem:
            raise EditorError(f'{res}: {doc.problem}', 409, code='unsupported')
        conflicts = []
        for change in changes:
            key = change['key']
            if change['op'] == 'add':
                if key in doc.start_ids:
                    conflicts.append({'key': key, 'why': 'the file already has a start with this key'})
                continue
            if key not in doc.start_ids:
                conflicts.append({'key': key, 'why': 'this start is not in the file any more'})
                continue
            walk = doc.walk(key)
            if not walk.editable:
                conflicts.append({'key': key, 'why': f'{walk.reason}: {READ_ONLY_HINT}'})
            elif walk.fingerprint != change['base']:
                conflicts.append({'key': key, 'why': 'it changed on disk since you opened it'})
        if conflicts:
            raise EditorError('nothing was saved: ' + '; '.join(f'{c["key"]}: {c["why"]}' for c in conflicts), 409,
                              code='conflict', conflicts=conflicts)
        edit = Edit(doc)
        written = {}
        for change in changes:
            if change['op'] == 'chain':
                written[change['key']] = edit.chain(change['key'], change['items'], doc.walk(change['key']).ids)
            elif change['op'] == 'add':
                written[change['key']] = edit.add(change['key'], change['items'], change.get('after'))
            else:
                edit.delete(change['key'], doc.walk(change['key']))
        new_text = edit.text()
        deleted = [c['key'] for c in changes if c['op'] == 'delete']
        before = sha1(text)
        if new_text == text:
            return self.saved(res, False, None, written, deleted, before)
        problem = verify(doc, new_text, changes, written, edit.touched)
        if problem:
            raise EditorError(f'nothing was saved: the edit came out wrong ({problem}). Please report this.', 500,
                              code='check-failed')
        backup = self.backup(res, text)
        if stamp_of(path) != stamp:
            discard(backup)
            return None
        try:
            # Whole or not at all: a locked file raises here with the old text still in place.
            write_text(path, new_text)
        except EditorError:
            discard(backup)  # the file is as it was, and so is its newest backup
            raise
        try:
            back = read_text(path)
            problem = 'it read back different' if back != new_text else verify(doc, back, changes, written, edit.touched)
        except Exception as e:  # anything at all goes wrong now
            problem = f'reading it back failed: {e}'
        if problem:
            self.forget(res)
            self.put_back(path, text, new_text, problem, backup)
        self.forget(res)
        self.prune_backups(res)
        return self.saved(res, True, backup, written, deleted, before)

    def put_back(self, path, text, new_text, problem, backup):
        """After a save that didn't check out: the old file goes back, but only over exactly what
        this save wrote. If another program has written the file since, its version stays."""
        try:
            now = read_text(path)
        except OSError:
            now = None
        if now is not None and now != new_text:
            raise EditorError(f'another program wrote {path.name} just after this save ({problem}). Its version was '
                              f'left as it is, and your edit may not be in it: check, and save again. The file as it '
                              f'was before your save is in {backup}.', 409, code='overwritten', backup=str(backup))
        try:
            if now is None:
                raise EditorError('the file could not be read', 500)
            write_text(path, text)
        except EditorError as e:
            raise EditorError(f'the save did not check out ({problem}), and putting the old file back failed too ({e}): '
                              f'{path.name} may hold the unchecked new version. The file as it was before is in '
                              f'{backup}.', 500, code='restore-failed', backup=str(backup))
        raise EditorError(f'the save did not check out ({problem}), so the file was put back as it was', 500,
                          code='restored', backup=str(backup))

    def saved(self, res, changed, backup, written, deleted, before):
        view = self.file(res)
        starts = [s for s in view['starts'] if s['key'] in written]
        # before: the file's version just before this save, so the page can tell whether it had
        # seen every change made to the file outside it.
        return {'ok': True, 'changed': changed, 'version': view['version'], 'before': before, 'starts': starts,
                'deleted': deleted, 'backup': str(backup) if backup else None}

    def backup(self, res, text):
        """The file as it was, at <backups>/<its path>/<time>.tres.bak. Kept: the newest 50, and the
        first of each day for 60 days (so a long session can't push out the version it started
        from). The Godot addon puts its own copies in the same folder (<time>-outside-godot.tres.bak,
        an outside version it was about to write over): those are left alone."""
        ignore_folder(self.backups)
        folder = self.backups / res.removeprefix('res://')
        folder.mkdir(parents=True, exist_ok=True)
        now = datetime.datetime.now()
        target = folder / f'{now.strftime("%Y%m%d-%H%M%S-%f")}.tres.bak'
        with open(target, 'w', encoding='utf-8', newline='') as f:
            f.write(text)
        return target

    def prune_backups(self, res):
        """Old backups go once a save has gone in (a save that fails takes none away)."""
        folder = self.backups / res.removeprefix('res://')
        own = [p for p in sorted(folder.glob('*.tres.bak'))
               if not p.name.endswith(ADDON_BACKUP_SUFFIX) and re.match(r'\d{8}-', p.name)]
        keep = set(own[-KEEP_BACKUPS:])
        oldest_day = (datetime.datetime.now() - datetime.timedelta(days=KEEP_DAILY_DAYS)).strftime('%Y%m%d')
        first_of_day = {}
        for p in own:
            first_of_day.setdefault(p.name[:8], p)
        keep.update(p for day, p in first_of_day.items() if day >= oldest_day)
        for old in own:
            if old not in keep:
                discard(old)


def launch(path, play=False):
    """Shows path in its folder, selected (File Explorer, Finder, or just the folder elsewhere); or,
    with play, opens it in its usual program. Returns False without doing it when DE_NO_LAUNCH is
    set: the tests must not put windows on the screen."""
    if os.environ.get('DE_NO_LAUNCH'):
        return False
    path = Path(path)
    try:
        if os.name == 'nt':
            if play:
                os.startfile(str(path))
            else:
                # One string, not a list: Explorer reads its own command line, and wants the
                # comma straight after /select and the path in quotes (a path can't hold one).
                subprocess.Popen(f'explorer /select,"{path}"')
        elif sys.platform == 'darwin':
            subprocess.Popen(['open', str(path)] if play else ['open', '-R', str(path)])
        else:
            subprocess.Popen(['xdg-open', str(path if play else path.parent)])
    except OSError as e:
        raise EditorError(f'this computer could not {"open" if play else "show"} {path.name}: {e}', 500, code='launch')
    return True


def discard(path):
    try:
        path.unlink()
    except OSError:
        pass


def ignore_folder(folder):
    """A folder of the tool's own (backups, thumbnails) that Godot and git both leave alone."""
    folder.mkdir(parents=True, exist_ok=True)
    for name, content in (('.gdignore', ''), ('.gitignore', '*\n')):
        marker = folder / name
        if not marker.exists():
            marker.write_text(content, encoding='utf-8')


def signal_counts(doc):
    return Counter(str(n.get('signalValue')) for i, n in doc.nodes.items() if node_type(i) == '3' and isinstance(n, dict))


def print_problem(res, error):
    """A bug, or a file odd in a way not thought of, while reading one file: the console gets the
    whole story, and the page goes on with the other files."""
    print(f'problem reading {res}:', file=sys.stderr)
    traceback.print_exception(error, file=sys.stderr)
