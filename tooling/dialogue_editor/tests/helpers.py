"""Test helpers: a small copy of the project to save into, and Godot run headless on that copy.

The real project is never written. A copy holds only the text files (scenes, resources, scripts,
uids: a few MB of the project's 1.7 GB); pictures are read from the real project through
--image-root. Godot runs with APPDATA and LOCALAPPDATA pointed into the copy's sandbox folder, so
the user's editor settings and caches are never touched.

The dialogue files the tests look into line by line (FIXTURES) come from tests/fixtures/, a
snapshot taken once (make_fixtures.py), not from the live project: writing with the editor changes
those files, and the tests must not care. Every other file is the live project's, which the tests
check only for things that hold whatever is written (eg every start saves back byte for byte).
"""
import json
import os
import re
import shutil
import subprocess
import tempfile
import uuid
from pathlib import Path

TESTS_DIR = Path(__file__).resolve().parent
TOOL_DIR = TESTS_DIR.parent
REAL_PROJECT = TOOL_DIR.parents[1]
GODOT = Path(os.environ.get('GODOT_BIN', REAL_PROJECT.parents[1] / 'Godot_v4.4.1-stable_win64.exe'))
COPY_SUFFIXES = ('.tres', '.gd', '.uid', '.tscn', '.cfg', '.godot')
WALKER = TESTS_DIR / 'godot_walk.gd'
FIXTURES_DIR = TESTS_DIR / 'fixtures'
FIXTURES = [
    'res://data/game_stages/vn/ashely2_win/d_ashely2_win.tres',
    'res://data/game_stages/vn/ashely2_intro/d_ashely2_intro.tres',
    'res://data/game_stages/vn/ashely2_lose/d_ashely2_lose.tres',
    'res://data/game_stages/poker/ashely2_match/d_ashely2_match.tres',
    'res://data/game_stages/vn/ashely2_ending/d_ashely2_ending.tres',
    'res://data/game_stages/dates/ashely_park_date/d_ashely_park_date.tres',
    'res://data/game_stages/vn/anna_class/d_anna_class.tres',
    'res://data/game_stages/vn/anna_night/d_anna_night.tres',
    'res://data/game_stages/vn/intro/d_intro3.tres',
    'res://data/game_stages/poker/boa_poker_new_poker/d_boa_poker_new_poker.tres',
    'res://data/game_stages/dates/test_date_one/d_test_date_one.tres',
    'res://data/game_stages/dates/lisa_market_date/d_lisa_market_date.tres',
    'res://data/game_stages/phone_message/chad_unblock_lisa/d_chad_unblock_lisa.tres',
]


def inside(path, folder):
    """Whether path is folder or anything in it."""
    path, folder = Path(path).resolve(), Path(folder).resolve()
    return path == folder or path.is_relative_to(folder)


def temp_root():
    """A short folder under the system temp dir (deep paths hit Windows' 260-character limit)."""
    base = Path(os.environ.get('DE_TEST_TMP') or tempfile.gettempdir())
    root = base / f'de_{uuid.uuid4().hex[:8]}'
    root.mkdir(parents=True)
    return root


def make_copy(dest, project=REAL_PROJECT, fixtures=True):
    """Copies the project's text files to dest (skipping .godot, .git, tooling and anything Godot
    ignores), with a project.godot that leaves out the game's autoloads and editor plugins: the
    checks load dialogue resources only, not the game. Then the FIXTURES snapshot goes over the
    live copies of those files."""
    project = Path(project)
    dest = Path(dest)
    if inside(dest, project):
        raise ValueError(f'a test copy must not be inside the project it copies ({dest})')
    count = 0
    for folder, dirs, files in os.walk(project):
        rel = Path(folder).relative_to(project)
        dirs[:] = [d for d in dirs if not d.startswith('.') and not (rel == Path('.') and d == 'tooling')
                   and not os.path.exists(os.path.join(folder, d, '.gdignore'))]
        for name in files:
            if name.endswith(COPY_SUFFIXES):
                target = dest / rel / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(os.path.join(folder, name), target)
                count += 1
    settings = (dest / 'project.godot').read_text(encoding='utf-8')
    for section in ('autoload', 'editor_plugins'):
        settings = re.sub(rf'^\[{section}\]\n.*?(?=^\[|\Z)', '', settings, flags=re.MULTILINE | re.DOTALL)
    (dest / 'project.godot').write_text(settings, encoding='utf-8', newline='\n')
    if fixtures:
        for res in FIXTURES:
            source = FIXTURES_DIR / res.removeprefix('res://')
            if not source.exists():
                raise FileNotFoundError(f'{source} is missing: run tests/make_fixtures.py once')
            target = dest / res.removeprefix('res://')
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
    return count


def godot_env(sandbox):
    sandbox = Path(sandbox)
    env = dict(os.environ)
    for name in ('APPDATA', 'LOCALAPPDATA'):
        folder = sandbox / name.lower()
        folder.mkdir(parents=True, exist_ok=True)
        env[name] = str(folder)
    return env


def run_godot(copy, args, sandbox, timeout=300):
    """Runs Godot headless on the copy. Returns (exit code, combined output)."""
    command = [str(GODOT), '--headless', '--path', str(copy)] + list(args)
    done = subprocess.run(command, capture_output=True, text=True, encoding='utf-8', errors='replace',
                          env=godot_env(sandbox), timeout=timeout)
    return done.returncode, (done.stdout or '') + (done.stderr or '')


def godot_import(copy, sandbox):
    """Has Godot scan the copy once, so it knows the scripts' class names and the files' uids."""
    return run_godot(copy, ['--import'], sandbox)


def godot_walk(copy, sandbox, res_paths, dump=False):
    """Loads each dialogue file with Godot's ResourceLoader and walks every start as the game's
    dialogue box would (godot_walk.gd). Returns (exit code, output, {path: report})."""
    folder = Path(copy) / '_walk'
    folder.mkdir(exist_ok=True)
    shutil.copyfile(WALKER, folder / 'godot_walk.gd')
    listing = folder / 'files.txt'
    listing.write_text('\n'.join(res_paths) + '\n', encoding='utf-8')
    args = ['--script', 'res://_walk/godot_walk.gd', '--', str(listing)] + (['dump'] if dump else [])
    code, output = run_godot(copy, args, sandbox)
    reports = {}
    for line in output.splitlines():
        if line.startswith('WALK {'):
            report = json.loads(line[5:])
            reports[report['path']] = report
    return code, output, reports
