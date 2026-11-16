"""Sort a pile of finished art into ordered folders: one folder per picture sequence of a scene.

A workspace folder holds one scene's sort:
    scene.json     the scene's stages and sequences, and where to look for evidence (written by hand)
    board.json     the decisions: which images are in each sequence, in order (written by the board)
    library/       every image added so far, full size, under its original name
    library.json   what is known about each image: size, prompt, the sequence it probably belongs to
    thumbs/        small copies for the board
    export/        the result: <stage>/<sequence>/01.png, 02.png, ... plus manifest.json

scene.json's "game" block says where the scene goes in a Godot game: see package.py.

Commands (-P stops Python importing files from the current folder):
    python -P -E art_sort.py add <workspace> <zip or folder>...   add images and guess where they go
    python -P -E art_sort.py board <workspace>                    open the sorting board in a browser
    python -P -E art_sort.py export <workspace>                   write export/ from board.json
    python -P -E art_sort.py package <workspace>                  put the sequences into the game (package.py)
    python -P -E art_sort.py guide <workspace>                    write the dialogue guide page (guide.py)

Guessing uses InvokeAI metadata. Each finished PNG records its prompt and the images its canvas was
built from. Those are matched against the campaign renders (folders named after design rows) to
find the row, and against the row's beat sheet for a starting order.
"""
import argparse
import datetime
import io
import json
import os
import re
import shutil
import sys
import threading
import urllib.parse
import webbrowser
import zipfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from PIL import Image

TOOL_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOL_DIR))  # -P keeps the tool's own folder off the import path
from package import PackageError, package  # noqa: E402
SAFE_NAME = re.compile(r'^[A-Za-z0-9][A-Za-z0-9._ -]{0,150}\.(png|webp|jpg|jpeg)$', re.IGNORECASE)
IMAGE_REF = re.compile(r'"image_name":\s*"([^"]+)"')
WORD = re.compile(r'[a-z]+')
THUMB_SIZE = 360
SPECIAL_LANES = ('_later', '_rejected')
# A prompt at least this close to a render's (shared words / all words, ignoring words most prompts
# share) is very likely the same shot: on Ashely II's 166 images with known rows, the closest render
# was in the right row every time down to 0.4.
LIKELY_SIMILARITY = 0.6


class SortError(Exception):
    pass


# ---------------------------------------------------------------- workspace files

def load_json(path, default):
    if not path.exists():
        return default
    with open(path, encoding='utf-8') as f:
        return json.load(f)


def save_json(path, data):
    """Writes a whole file or nothing: to a temporary file first, then swapped in."""
    tmp = path.with_name(path.name + '.tmp')
    with open(tmp, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, indent=1, ensure_ascii=False)
    os.replace(tmp, path)


class Workspace:
    def __init__(self, folder):
        self.root = Path(folder).resolve()
        self.scene_path = self.root / 'scene.json'
        if not self.scene_path.exists():
            raise SortError(f'{self.scene_path} is missing: a workspace needs a scene.json')
        self.scene = load_json(self.scene_path, None)
        self.library_dir = self.root / 'library'
        self.thumbs_dir = self.root / 'thumbs'
        self.library_path = self.root / 'library.json'
        self.board_path = self.root / 'board.json'
        self.export_dir = self.root / 'export'
        self.lock = threading.Lock()

    def sequences(self, board=None):
        """Every sequence lane, in scene order, with the board's own extra lanes after their stage's."""
        extra = (board or {}).get('extraLanes', [])
        for stage in self.scene['stages']:
            for sequence in stage['sequences']:
                yield stage['name'], sequence
            for lane in extra:
                if lane['stage'] == stage['name']:
                    yield stage['name'], lane

    def library(self):
        return load_json(self.library_path, {'images': {}})

    def board(self):
        board = load_json(self.board_path, {'version': 1, 'lanes': {}, 'extraLanes': []})
        for _, sequence in self.sequences(board):
            board['lanes'].setdefault(sequence['key'], {'items': [], 'done': False})
        for key in SPECIAL_LANES:
            board['lanes'].setdefault(key, {'items': [], 'done': False})
        return board

    def save_board(self, board):
        """Keeps the previous version as board.json.bak, so one bad save can always be undone."""
        if self.board_path.exists():
            shutil.copyfile(self.board_path, self.board_path.with_name('board.json.bak'))
        save_json(self.board_path, board)

    def backup_board(self):
        """A dated copy of board.json, taken each time the board opens; the newest 30 are kept."""
        if not self.board_path.exists():
            return
        backups = self.root / 'backups'
        backups.mkdir(exist_ok=True)
        stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
        shutil.copyfile(self.board_path, backups / f'board-{stamp}.json')
        for old in sorted(backups.glob('board-*.json'))[:-30]:
            old.unlink()


# ---------------------------------------------------------------- adding images

def image_sources(paths):
    """(name, bytes reader) for each image file in the given zips and folders."""
    for source in paths:
        source = Path(source)
        if source.is_dir():
            for path in sorted(source.rglob('*')):
                if path.is_file() and SAFE_NAME.match(path.name):
                    yield path.name, path.read_bytes, source.name
        elif zipfile.is_zipfile(source):
            archive = zipfile.ZipFile(source)
            for info in sorted(archive.infolist(), key=lambda i: i.date_time):
                name = info.filename.rsplit('/', 1)[-1]
                if not info.is_dir() and SAFE_NAME.match(name):
                    yield name, (lambda info=info: archive.read(info)), source.name
        else:
            raise SortError(f'{source} is neither a folder nor a zip')


def describe(data):
    """Size, prompt and canvas sources of one image, from its InvokeAI metadata if it has any."""
    with Image.open(io.BytesIO(data)) as img:
        size = list(img.size)
        raw = img.info.get('invokeai_metadata', '')
    facts = {'size': size, 'prompt': '', 'refs': []}
    if raw:
        meta = json.loads(raw)
        facts['prompt'] = meta.get('positive_prompt', '')
        facts['seed'] = meta.get('seed')
        facts['model'] = (meta.get('model') or {}).get('name')
        facts['refs'] = sorted(set(IMAGE_REF.findall(raw)))
    return facts


def make_thumb(data, path):
    with Image.open(io.BytesIO(data)) as img:
        img = img.convert('RGB')
        img.thumbnail((THUMB_SIZE, THUMB_SIZE))
        img.save(path, 'JPEG', quality=86)


def add(workspace, sources):
    library = workspace.library()
    images = library['images']
    workspace.library_dir.mkdir(exist_ok=True)
    workspace.thumbs_dir.mkdir(exist_ok=True)
    added, already = [], 0
    for name, read, source_name in image_sources(sources):
        data = read()
        # The same name and size is taken to be the same image; a different image under a known name
        # (two folders of 01.png, say) gets a numbered name.
        stem, ext = name.rsplit('.', 1)
        numbered = re.compile(re.escape(stem) + r'(-\d+)?\.' + re.escape(ext))
        if any(numbered.fullmatch(n) and facts['bytes'] == len(data) for n, facts in images.items()):
            already += 1
            continue
        if name in images:
            name = next(f'{stem}-{n}.{ext}' for n in range(2, 10000) if f'{stem}-{n}.{ext}' not in images)
        (workspace.library_dir / name).write_bytes(data)
        make_thumb(data, workspace.thumbs_dir / (name + '.jpg'))
        facts = describe(data)
        facts.update({'bytes': len(data), 'source': source_name, 'added': datetime.date.today().isoformat()})
        images[name] = facts
        added.append(name)
        if len(added) % 25 == 0:
            print(f'  {len(added)} added...')
    evidence = Evidence(workspace) if workspace.scene.get('evidence') else None
    for name in added:
        images[name]['guess'] = evidence.guess(images[name]) if evidence else None
    save_json(workspace.library_path, library)
    board = workspace.board()
    placed = place_guesses(workspace, board, images, added)
    workspace.save_board(board)
    confidence = [images[n]['guess']['confidence'] if images[n].get('guess') else 'none' for n in added]
    print(f'added {len(added)} images ({already} were already in the library)')
    for level in ('certain', 'likely', 'unsure', 'none'):
        if confidence.count(level):
            print(f'  {level}: {confidence.count(level)}')
    print(f'{placed} placed in their sequences for you to check; {len(added) - placed} left in the tray')


def fits_frame(size, frame):
    """Whether an image has the scene's shape (a few pixels off still counts)."""
    return abs(size[0] / size[1] - frame[0] / frame[1]) < 0.05 * frame[0] / frame[1]


def place_guesses(workspace, board, images, names):
    """Puts the newly added images whose sequence is known (and which have the scene's shape) at the
    end of that sequence, in their guessed order, marked "auto" until checked."""
    sequences = {s['key']: s for _, s in workspace.sequences(board)}
    frame = workspace.scene.get('frame')
    by_lane = {}
    for name in names:
        guess = images[name].get('guess')
        if not guess or guess['confidence'] not in ('certain', 'likely') or guess['sequence'] not in sequences:
            continue
        if not sequences[guess['sequence']].get('autoPlace', True):
            continue
        if frame and not fits_frame(images[name]['size'], frame):
            continue
        by_lane.setdefault(guess['sequence'], []).append(name)
    for key, lane_names in by_lane.items():
        lane_names.sort(key=lambda n: images[n]['guess']['order'])
        board['lanes'][key]['items'] += [{'image': n, 'auto': True} for n in lane_names]
    return sum(len(v) for v in by_lane.values())


# ---------------------------------------------------------------- guessing from InvokeAI evidence

def words(text):
    return set(WORD.findall(text.lower()))


class Evidence:
    """The campaign renders (each in a folder named after its design row) and each row's beat sheet."""

    def __init__(self, workspace):
        config = workspace.scene['evidence']
        self.row_pattern = re.compile(config['rowPattern'])
        self.sequence_of_row = {}
        self.row_rank = {}
        for _, sequence in workspace.sequences():
            for rank, row in enumerate(sequence.get('campaignRows', [])):
                self.sequence_of_row[row] = sequence['key']
                self.row_rank[row] = rank
        self.renders = self.index_renders(workspace, config)
        self.by_name = {}
        self.by_prompt = {}
        for render in self.renders:
            self.by_name.setdefault(render['name'], []).append(render)
            self.by_prompt.setdefault(render['prompt'], []).append(render)
        # Words most prompts share (quality tags, her look) say nothing about which shot it is.
        counts = {}
        for render in self.renders:
            for word in render['words']:
                counts[word] = counts.get(word, 0) + 1
        self.common = {w for w, c in counts.items() if c > len(self.renders) / 2}
        for render in self.renders:
            render['words'] -= self.common
        self.beats = self.read_beats(config)

    def row_of(self, run_path):
        for part in reversed(run_path.split('/')):
            match = self.row_pattern.search(part)
            if match:
                return match.group(1)
        return None

    def index_renders(self, workspace, config):
        """Every campaign render's prompt; cached by file, since reading thousands of PNGs is slow."""
        root = Path(os.path.expanduser(config['campaigns']))
        cache_path = workspace.root / 'cache' / 'renders.json'
        cache_path.parent.mkdir(exist_ok=True)
        cache = load_json(cache_path, {})
        fresh = {}
        for folder in sorted(root.glob(config['campaignPrefix'] + '*')):
            for path in folder.rglob('*.png'):
                rel = path.relative_to(root).as_posix()
                mtime = path.stat().st_mtime
                if rel in cache and cache[rel]['mtime'] == mtime:
                    fresh[rel] = cache[rel]
                    continue
                with Image.open(path) as img:
                    raw = img.info.get('invokeai_metadata', '')
                fresh[rel] = {'mtime': mtime, 'prompt': json.loads(raw).get('positive_prompt', '') if raw else ''}
        save_json(cache_path, fresh)
        renders = []
        for rel, entry in fresh.items():
            row = self.row_of(rel.rsplit('/', 1)[0])
            if row and entry['prompt']:
                renders.append({'name': rel.rsplit('/', 1)[-1], 'path': rel, 'row': row, 'mtime': entry['mtime'],
                                'prompt': entry['prompt'], 'words': words(entry['prompt'])})
        return renders

    def read_beats(self, config):
        """Each row's beat sheet (a list of beat descriptions, in story order), where a spec has one."""
        beats = {}
        root = Path(os.path.expanduser(config.get('specs', ''))) if config.get('specs') else None
        if not root or not root.is_dir():
            return beats
        for folder in root.iterdir():
            match = re.match(r'^(\d\d[a-z]?)-', folder.name)
            if not match or not folder.is_dir():
                continue
            for spec in folder.glob('spec.story-*.json'):
                options = load_json(spec, {}).get('arc_module_options', {})
                sheet = options.get('beat_sheet', {}).get('beats')
                if sheet:
                    beats[match.group(1)] = [words(b) - self.common for b in sheet]
        return beats

    def guess(self, facts):
        """The image's design row and sequence, how sure that is and why, other candidates, and a key
        for its starting order inside the sequence."""
        mine = words(facts['prompt']) - self.common
        scores = {}
        for render in self.renders:
            union = mine | render['words']
            score = len(mine & render['words']) / len(union) if union else 0
            if score > scores.get(render['row'], (0, None))[0]:
                scores[render['row']] = (score, render)
        ranked = sorted(scores.items(), key=lambda kv: -kv[1][0])

        lineage = [r for ref in facts['refs'] for r in self.by_name.get(ref, [])]
        same_prompt = self.by_prompt.get(facts['prompt'], []) if facts['prompt'] else []
        if lineage and len({r['row'] for r in lineage}) == 1:
            source, confidence = lineage[0], 'certain'
            why = f'its canvas was built on a render from {source["path"].rsplit("/", 1)[0]}'
        elif same_prompt and len({r['row'] for r in same_prompt}) == 1:
            source, confidence = same_prompt[0], 'certain'
            why = f'same prompt as a render from {source["path"].rsplit("/", 1)[0]}'
        elif ranked:
            score, source = ranked[0][1]
            confidence = 'likely' if score >= LIKELY_SIMILARITY else 'unsure'
            why = f'prompt {score:.0%} like a render from {source["path"].rsplit("/", 1)[0]}'
        else:
            return None
        row = source['row']
        alternatives = [{'sequence': self.sequence_of_row.get(r), 'row': r, 'score': round(s[0], 2)}
                        for r, s in ranked if r != row and self.sequence_of_row.get(r)][:3]
        beat = None
        if row in self.beats:
            beat_scores = [len(mine & b) / len(mine | b) if mine | b else 0 for b in self.beats[row]]
            if max(beat_scores) > 0:
                beat = beat_scores.index(max(beat_scores))
        return {'sequence': self.sequence_of_row.get(row), 'row': row, 'confidence': confidence, 'why': why,
                'alternatives': alternatives, 'beat': beat,
                'order': [self.row_rank.get(row, 0), 99 if beat is None else beat, source['mtime']]}


# ---------------------------------------------------------------- export

def export(workspace):
    """Writes every sequence that has images to export/<stage>/<sequence>/01.png... and a manifest
    saying which library image each file is. Only files a previous export wrote are replaced."""
    with workspace.lock:
        board = workspace.board()
        library = workspace.library()['images']
        out = workspace.export_dir
        manifest_path = out / 'manifest.json'
        old = load_json(manifest_path, {'sequences': []})
        ours = {'manifest.json'} | {f'{s["stage"]}/{s["sequence"]}/{f["file"]}' for s in old['sequences'] for f in s['files']} \
            | {f'{s["stage"]}/{s["sequence"]}/{s["script"]}' for s in old['sequences'] if s.get('script')}
        if out.exists():
            strangers = [p.relative_to(out).as_posix() for p in out.rglob('*')
                         if p.is_file() and p.relative_to(out).as_posix() not in ours]
            if strangers:
                raise SortError(f'export/ has {len(strangers)} files the sorter did not write (eg {strangers[0]}). '
                                'Move them out of export/ first: an export replaces the whole folder.')
            for rel in ours:
                (out / rel).unlink(missing_ok=True)
            for folder in sorted((p for p in out.rglob('*') if p.is_dir()), key=lambda p: -len(p.parts)):
                if not any(folder.iterdir()):
                    folder.rmdir()
        manifest = {'scene': workspace.scene.get('title', ''), 'exported': datetime.datetime.now().isoformat(timespec='seconds'),
                    'sequences': []}
        for stage, sequence in workspace.sequences(board):
            items = board['lanes'].get(sequence['key'], {}).get('items', [])
            if not items:
                continue
            folder = out / stage / sequence['key']
            folder.mkdir(parents=True, exist_ok=True)
            width = max(2, len(str(len(items))))
            files = []
            for number, item in enumerate(items, 1):
                if item['image'] not in library:
                    raise SortError(f'{sequence["key"]} lists {item["image"]}, which is not in the library')
                file = f'{number:0{width}d}.{item["image"].rsplit(".", 1)[-1].lower()}'
                shutil.copyfile(workspace.library_dir / item['image'], folder / file)
                files.append({'file': file, 'image': item['image']})
                if item.get('dialogue', '').strip():
                    files[-1]['dialogue'] = item['dialogue'].strip()
            entry = {'stage': stage, 'sequence': sequence['key'], 'files': files}
            if any('dialogue' in f for f in files):
                write_script(folder / 'dialogue.txt', stage, sequence, files)
                entry['script'] = 'dialogue.txt'
            manifest['sequences'].append(entry)
        out.mkdir(exist_ok=True)
        save_json(manifest_path, manifest)
        count = sum(len(s['files']) for s in manifest['sequences'])
        return {'images': count, 'sequences': len(manifest['sequences']), 'folder': str(out)}


def write_script(path, stage, sequence, files):
    """The sequence's placeholder dialogue as a readable script: each picture, then its lines."""
    about = [f'{sequence["key"]}  ({stage})']
    details = [f'row {sequence["designRow"]}' if sequence.get('designRow') else '', sequence.get('state', '')]
    if any(details):
        about.append(' · '.join(d for d in details if d))
    if sequence.get('context'):
        about.append(sequence['context'])
    blocks = ['\n'.join(about)]
    for f in files:
        blocks.append(f['file'] + '\n' + f.get('dialogue', '(no dialogue)'))
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n\n'.join(blocks) + '\n')


# ---------------------------------------------------------------- the board

CONTENT_TYPES = {'.png': 'image/png', '.webp': 'image/webp', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg'}


def make_handler(workspace):
    class Handler(BaseHTTPRequestHandler):
        def send(self, status, body, content_type='application/json', cache=False):
            if not isinstance(body, bytes):
                body = json.dumps(body).encode('utf-8')
            self.send_response(status)
            self.send_header('Content-Type', content_type)
            self.send_header('Content-Length', str(len(body)))
            self.send_header('Cache-Control', 'max-age=86400' if cache else 'no-store')
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            path = urllib.parse.unquote(urllib.parse.urlparse(self.path).path)
            if path == '/':
                self.send(200, (TOOL_DIR / 'board.html').read_bytes(), 'text/html; charset=utf-8')
            elif path == '/api/state':
                with workspace.lock:
                    self.send(200, {'scene': workspace.scene, 'library': workspace.library()['images'],
                                    'board': workspace.board(), 'workspace': str(workspace.root)})
            elif path.startswith('/thumbs/') or path.startswith('/library/'):
                folder, name = path[1:].split('/', 1)
                # Only names the library knows, so a request can never reach outside the workspace.
                image = name[:-4] if folder == 'thumbs' and name.endswith('.jpg') else name
                if image not in workspace.library()['images']:
                    return self.send(404, {'error': 'no such image'})
                file = (workspace.thumbs_dir if folder == 'thumbs' else workspace.library_dir) / name
                self.send(200, file.read_bytes(), CONTENT_TYPES.get(file.suffix.lower(), 'application/octet-stream'), cache=True)
            else:
                self.send(404, {'error': 'not found'})

        def do_POST(self):
            path = urllib.parse.urlparse(self.path).path
            body = self.rfile.read(int(self.headers.get('Content-Length', 0)))
            try:
                if path == '/api/board':
                    board = json.loads(body)
                    if not isinstance(board.get('lanes'), dict):
                        raise SortError('the board sent no lanes')
                    with workspace.lock:
                        workspace.save_board(board)
                    self.send(200, {'saved': True})
                elif path == '/api/export':
                    self.send(200, export(workspace))
                elif path == '/api/package':
                    self.send(200, package(workspace))
                elif path == '/api/open-export':
                    os.startfile(workspace.export_dir if workspace.export_dir.exists() else workspace.root)
                    self.send(200, {'opened': True})
                else:
                    self.send(404, {'error': 'not found'})
            except (SortError, PackageError, ValueError, OSError) as e:
                self.send(409, {'error': str(e)})

        def log_message(self, *args):
            pass

    return Handler


def board(workspace, port, open_browser):
    workspace.backup_board()
    try:
        server = ThreadingHTTPServer(('127.0.0.1', port), make_handler(workspace))
    except OSError:
        server = ThreadingHTTPServer(('127.0.0.1', 0), make_handler(workspace))
    url = f'http://127.0.0.1:{server.server_address[1]}/'
    print(f'board for {workspace.scene.get("title", workspace.root.name)}: {url}  (Ctrl+C to stop)')
    if open_browser:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    commands = parser.add_subparsers(dest='command', required=True)
    p_add = commands.add_parser('add', help='add images from zips or folders and guess where they go')
    p_add.add_argument('workspace')
    p_add.add_argument('sources', nargs='+')
    p_board = commands.add_parser('board', help='open the sorting board')
    p_board.add_argument('workspace')
    p_board.add_argument('--port', type=int, default=8765)
    p_board.add_argument('--no-open', action='store_true', help="don't open a browser")
    p_export = commands.add_parser('export', help='write export/ from the board')
    p_export.add_argument('workspace')
    p_package = commands.add_parser('package', help='put the sequences into the Godot game (Godot must be closed)')
    p_package.add_argument('workspace')
    p_guide = commands.add_parser('guide', help='write the dialogue guide page for the packaged scene')
    p_guide.add_argument('workspace')
    args = parser.parse_args()
    try:
        workspace = Workspace(args.workspace)
        if args.command == 'add':
            add(workspace, args.sources)
        elif args.command == 'board':
            board(workspace, args.port, not args.no_open)
        elif args.command == 'package':
            result = package(workspace)
            print('\n'.join(result['report']))
            print(f'{result["pictures"]} pictures in {result["sequences"]} sequences ({result["new"]} new), '
                  f'{result["chains"]} dialogue chains written. Record: {result["state"]}')
        elif args.command == 'guide':
            from guide import write_guide
            result = write_guide(workspace)
            print(f'dialogue guide: {result["file"]} ({result["written"]} of {result["lines"]} lines written)')
        else:
            result = export(workspace)
            print(f'exported {result["images"]} images in {result["sequences"]} sequences to {result["folder"]}')
    except (SortError, PackageError) as e:
        sys.exit(f'error: {e}')


if __name__ == '__main__':
    main()
