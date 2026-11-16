"""Tests for the dialogue editor (dialogues.py and dialogue_editor.py).

    python -P -E tooling/dialogue_editor/tests/test_dialogues.py [-v] [-k name]

The real project is only ever read. Everything that saves works on a temporary copy of the
project's text files under the system temp folder (helpers.py), with pictures read from the real
project. Godot runs headless on that copy with its settings folders sandboxed.

The files the tests read line by line are a frozen snapshot (helpers.FIXTURES, tests/fixtures/):
writing with the editor doesn't change what these tests expect. The live project's other files are
checked only for what holds whatever they say (every start saves back byte for byte, Godot reads
them), and its numbers are printed, not checked.
    DE_KEEP=1        keep the copy afterwards (its path is printed)
    DE_SKIP_GODOT=1  skip the Godot checks
"""
import copy
import datetime
import hashlib
import http.client
import json
import os
import re
import shutil
import subprocess
import sys
import threading
import time
import unittest
import urllib.parse
from io import BytesIO
from pathlib import Path
from unittest import mock

TESTS_DIR = Path(__file__).resolve().parent
TOOL_DIR = TESTS_DIR.parent
sys.path.insert(0, str(TOOL_DIR))
sys.path.insert(0, str(TESTS_DIR))
import dialogue_editor as E  # noqa: E402
import dialogues as D  # noqa: E402
import helpers as H  # noqa: E402
from PIL import Image  # noqa: E402

REAL = H.REAL_PROJECT
os.environ['DE_NO_LAUNCH'] = '1'  # Show in folder / Play video open no window while the tests run
ASHELY_WIN = 'res://data/game_stages/vn/ashely2_win/d_ashely2_win.tres'
ASHELY_INTRO = 'res://data/game_stages/vn/ashely2_intro/d_ashely2_intro.tres'
ASHELY_LOSE = 'res://data/game_stages/vn/ashely2_lose/d_ashely2_lose.tres'
ASHELY_FILES = [ASHELY_INTRO, 'res://data/game_stages/poker/ashely2_match/d_ashely2_match.tres', ASHELY_WIN,
                ASHELY_LOSE, 'res://data/game_stages/vn/ashely2_ending/d_ashely2_ending.tres']
STR_KEYS = 'res://data/game_stages/dates/ashely_park_date/d_ashely_park_date.tres'
BIG = 'res://data/game_stages/vn/anna_class/d_anna_class.tres'
BRANCHING = 'res://data/game_stages/vn/intro/d_intro3.tres'
SETS = 'res://data/game_stages/poker/boa_poker_new_poker/d_boa_poker_new_poker.tres'
STRAYS = 'res://data/game_stages/dates/test_date_one/d_test_date_one.tres'
HAND_LAID = 'res://data/game_stages/dates/lisa_market_date/d_lisa_market_date.tres'
LOW_CHAINS = 'res://data/game_stages/phone_message/chad_unblock_lisa/d_chad_unblock_lisa.tres'
TRICKY = [
    'She said "hi" and left',
    'a back\\slash, a \\n that is not a line break, and a \\" too',
    'first line\nsecond line\n\nfourth, after a blank one',
    'unicode: café, naïve, “curly”, ’apostrophe’, emoji 😀, 日本語',
    '[i]italic[/i] [b]bold[/b] [color=#ff8800]orange[/color] [wait 0.4] [shake rate=20]x[/shake]',
    'Hi [name]! You have {{MONEY}} chips.[br]Next line',
    'ends with a backslash \\',
    '"',
    '   spaces around   ',
    '\ttab inside',
    '(Placeholder) still a placeholder',
]
S = {}  # the shared copy: root, copy, editor, originals, real hashes


def real_backups():
    """The backups in the editor's own folder, from real saves."""
    folder = TOOL_DIR / 'backups'
    return sorted(str(p) for p in folder.rglob('*.bak')) if folder.exists() else []


def setUpModule():
    root = H.temp_root()
    project = root / 'proj'
    count = H.make_copy(project)
    editor = D.Editor(project, image_root=REAL, backups=root / 'backups', cache=root / 'cache')
    originals = {res: editor.path(res).read_bytes() for res in editor.scan()[0]}
    real_hashes = {res: real_hash(res) for res in originals}
    S.update(root=root, copy=project, editor=editor, originals=originals, real_hashes=real_hashes, copied=count,
             real_backups=real_backups())
    print(f'\ntest copy: {project} ({count} text files, {len(originals)} dialogue files)', file=sys.stderr)


def real_hash(res):
    path = REAL / res[6:]
    return hashlib.sha1(path.read_bytes()).hexdigest() if path.exists() else None


def tearDownModule():
    # The real project must be exactly as it was (only read): anything else fails the run. The
    # user may have saved a file meanwhile, so the message says which.
    changed = [res for res, digest in S['real_hashes'].items() if real_hash(res) != digest]
    if os.environ.get('DE_KEEP'):
        print(f'kept {S["root"]}', file=sys.stderr)
    else:
        shutil.rmtree(S['root'], ignore_errors=True)
    if changed:
        raise AssertionError(f'real project dialogue files changed during the run: {changed} (if you saved them '
                             'yourself meanwhile, that was you; otherwise a test wrote to the real project)')
    print(f'\nreal project: all {len(S["real_hashes"])} dialogue files unchanged', file=sys.stderr)


# ---------------------------------------------------------------- helpers

def ed():
    return S['editor']


def disk(res):
    return ed().path(res).read_bytes()


def restore(res):
    path = ed().path(res)
    tmp = path.with_name(path.name + '.restore')
    tmp.write_bytes(S['originals'][res])
    os.replace(tmp, path)
    ed().forget(res)


def restore_all():
    for res, data in S['originals'].items():
        if disk(res) != data:
            restore(res)


def view(res):
    return ed().file(res)


def start(res, key):
    return copy.deepcopy(next(s for s in view(res)['starts'] if s['key'] == key))


def save(res, changes, confirm=True):
    return ed().save(res, json.loads(json.dumps(changes)), confirm_godot=confirm)


def chain(res, key, items, base=None):
    s = start(res, key)
    return save(res, [{'op': 'chain', 'key': key, 'base': base or s['fingerprint'], 'items': items}])


def reread(res):
    """The file as it is on disk now, read fresh (no cache)."""
    return D.Doc(D.read_text(ed().path(res)))


def disk_items(res, key):
    doc = reread(res)
    walk = doc.walk(key)
    return D.plain_items(D.doc_items(doc, walk)), walk, doc


def line(text, speaker='', bl=-1, bg=-1, node_id=None, state=None):
    item = {'id': node_id, 'kind': 'line', 'speaker': speaker, 'text': text, 'backgroundList': bl, 'background': bg}
    if state is not None:
        item['characterState'] = state
    return item


def signal(value, node_id=None):
    return {'id': node_id, 'kind': 'signal', 'value': value}


def backups_of(res):
    folder = S['root'] / 'backups' / res.removeprefix('res://')
    return sorted(folder.glob('*.tres.bak')) if folder.exists() else []


def row_offset(doc, start_id, n):
    x, y = D.offset_of(doc.nodes[start_id])
    return f'Vector2({D.number_text(x + D.FIRST_NODE_GAP + n * D.NODE_STEP)}, {D.number_text(y)})'


def boxes(doc, ids):
    return [(n, (*D.offset_of(doc.nodes[n]), *D.size_of(n, doc.nodes[n]))) for n in ids if isinstance(doc.nodes.get(n), dict)]


def overlapping(doc, mine, others):
    """Pairs (my node, other node) whose boxes in Godot's graph overlap."""
    theirs = boxes(doc, others)
    return {(a, b) for a, box in boxes(doc, mine) for b, other in theirs if D.overlaps(box, other)}


def expect_error(test, status, code, function, *args, **kwargs):
    with test.assertRaises(D.EditorError) as caught:
        function(*args, **kwargs)
    test.assertEqual(caught.exception.status, status, str(caught.exception))
    if code:
        test.assertEqual(caught.exception.extra.get('code'), code, str(caught.exception))
    return caught.exception


# ---------------------------------------------------------------- 1. round trip

class Test1RoundTrip(unittest.TestCase):
    def test_copy_is_the_project_with_the_fixtures(self):
        """The copy has the live project's dialogue files, the FIXTURES as frozen in tests/fixtures."""
        self.assertTrue(set(H.FIXTURES) <= set(S['originals']))
        for res, data in S['originals'].items():
            if res in H.FIXTURES:
                self.assertEqual(data, (H.FIXTURES_DIR / res[6:]).read_bytes(), res)
            else:
                self.assertEqual(hashlib.sha1(data).hexdigest(), S['real_hashes'][res], res)

    def test_every_editable_start_saves_back_byte_identical(self):
        """Each editable start of all 80 files saved back with its own items (same ids, through
        JSON as the page sends them) leaves the file byte-identical, and writes nothing."""
        saved = read_only = 0
        for res in ed().scan()[0]:
            path = ed().path(res)
            before, stat = disk(res), os.stat(path)
            for s in view(res)['starts']:
                if not s['editable']:
                    read_only += 1
                    continue
                result = save(res, [{'op': 'chain', 'key': s['key'], 'base': s['fingerprint'], 'items': s['items']}])
                self.assertFalse(result['changed'], f'{res} {s["key"]}')
                self.assertIsNone(result['backup'])
                saved += 1
            self.assertEqual(disk(res), before, res)
            self.assertEqual(disk(res), S['originals'][res], res)
            self.assertEqual(os.stat(path).st_mtime_ns, stat.st_mtime_ns, f'{res} was written')
        print(f'\n  round trip: {saved} editable starts saved back unchanged, {read_only} read-only', file=sys.stderr)
        self.assertGreater(saved, 500)
        self.assertEqual(list((S['root'] / 'backups').rglob('*.bak')) if (S['root'] / 'backups').exists() else [], [])

    def test_whole_file_in_one_save_is_identical(self):
        for res in ed().scan()[0]:
            starts = [s for s in view(res)['starts'] if s['editable']]
            changes = [{'op': 'chain', 'key': s['key'], 'base': s['fingerprint'], 'items': s['items']} for s in starts]
            result = save(res, changes)
            self.assertFalse(result['changed'], res)
            self.assertEqual(disk(res), S['originals'][res], res)

    def test_an_empty_save_writes_nothing(self):
        stat = os.stat(ed().path(ASHELY_WIN))
        result = save(ASHELY_WIN, [])
        self.assertFalse(result['changed'])
        self.assertEqual(os.stat(ed().path(ASHELY_WIN)).st_mtime_ns, stat.st_mtime_ns)

    # Every reason dialogues.py gives for a read-only start, by how it begins.
    REASONS = {'shares': r'it shares lines', 'variable': r'it (sets|checks) a variable', 'branches': r'it branches',
               'other': r"(it shares its start node|another node links back|its start node|it links to|it loops back|"
                        r"it runs into the start node|it has a|signal \S+ has unexpected|line \S+ has|\S+ is listed as a stray|"
                        r"\S+ is not a node|its nodes are not laid out|its start list is not laid out|node \S+ is in the file "
                        r"twice|a start key is in the file twice)"}

    def test_every_read_only_reason_is_a_known_one(self):
        """Over the whole project: each start is editable or has one of the known reasons. The
        numbers are printed (when this tool was written: 639 starts, 587 editable, 39 shared tails,
        12 with variables, 1 with choices)."""
        reasons = {name: 0 for name in self.REASONS}
        total = editable = 0
        for res in ed().scan()[0]:
            for s in view(res)['starts']:
                total += 1
                if s['editable']:
                    editable += 1
                    self.assertNotIn('reason', s)
                    continue
                self.assertTrue(s['reason'].endswith(': ' + D.READ_ONLY_HINT), s['reason'])
                kind = next((name for name, pattern in self.REASONS.items() if re.match(pattern, s['reason'])), None)
                self.assertIsNotNone(kind, f'{res} {s["key"]}: {s["reason"]}')
                reasons[kind] += 1
        print(f'\n  starts {total}, editable {editable}, read-only {reasons}', file=sys.stderr)
        self.assertEqual(total, editable + sum(reasons.values()))
        # The frozen files keep their known mix.
        fixed = [s for res in (BRANCHING, SETS) for s in view(res)['starts']]
        self.assertTrue(any('branches' in s.get('reason', '') for s in fixed))
        self.assertTrue(any('a variable' in s.get('reason', '') for s in fixed))
        self.assertTrue(any('shares lines' in s.get('reason', '') for s in fixed))


# ---------------------------------------------------------------- 2. mutations

class Test2Mutations(unittest.TestCase):
    def setUp(self):
        restore_all()

    def check_untouched(self, res, before_doc, touched):
        """Every node the save didn't touch is still its old text, byte for byte."""
        after = reread(res)
        for node_id in before_doc.order:
            if node_id not in touched:
                self.assertEqual(after.raw.get(node_id), before_doc.raw[node_id], node_id)

    def chain_ids(self, res, key):
        return reread(res).walk(key).ids

    def test_insert_line(self):
        res, key = ASHELY_WIN, 'WIN_S1_TOP'
        before = reread(res)
        s = start(res, key)
        items = s['items']
        new = line('An inserted line', speaker=1, bl=items[2]['backgroundList'], bg=items[2]['background'])
        result = chain(res, key, items[:3] + [new] + items[3:])
        self.assertTrue(result['changed'])
        expected_id = f'1_{before.numbers()["1"] + 1}'
        got, walk, doc = disk_items(res, key)
        self.assertEqual([i['id'] for i in got], [i['id'] for i in items[:3]] + [expected_id] + [i['id'] for i in items[3:]])
        self.assertEqual(got[3]['text'], 'An inserted line')
        self.assertEqual(got[3]['speaker'], 1)
        self.assertEqual(result['starts'][0]['items'][3]['id'], expected_id)
        # Placed right after its predecessor's entry, sized like the packager's lines, the chain in a row.
        self.assertEqual(doc.order.index(expected_id), doc.order.index(items[2]['id']) + 1)
        self.assertEqual(doc.nodes[expected_id]['size'], 'Vector2(300, 640)')
        for n, node_id in enumerate(walk.ids):
            self.assertEqual(doc.nodes[node_id]['offset'], row_offset(doc, walk.start_id, n))
        self.check_untouched(res, before, set(walk.ids) | {walk.start_id})
        self.assertEqual(Path(result['backup']).read_bytes(), S['originals'][res])

    def test_delete_line(self):
        res, key = ASHELY_WIN, 'WIN_S1_TOP'
        before = reread(res)
        items = start(res, key)['items']
        gone = items[5]['id']
        chain(res, key, items[:5] + items[6:])
        got, walk, doc = disk_items(res, key)
        self.assertEqual([i['id'] for i in got], [i['id'] for i in items if i['id'] != gone])
        self.assertNotIn(gone, doc.nodes)
        self.assertEqual(doc.nodes[items[4]['id']]['options'][0]['link'], items[6]['id'])
        self.check_untouched(res, before, set(before.walk(key).ids) | {walk.start_id})

    def test_reorder_lines(self):
        res, key = ASHELY_WIN, 'WIN_S1_TOP'
        items = start(res, key)['items']
        moved = [items[0], items[2], items[1]] + items[3:]
        chain(res, key, moved)
        got, walk, doc = disk_items(res, key)
        self.assertEqual(got, D.plain_items(moved))
        self.assertEqual(sorted(walk.ids), sorted(i['id'] for i in items))
        self.assertEqual(doc.nodes[walk.start_id]['link'], items[0]['id'])
        self.assertEqual(doc.nodes[items[0]['id']]['options'][0]['link'], items[2]['id'])
        for n, node_id in enumerate(walk.ids):
            self.assertEqual(doc.nodes[node_id]['offset'], row_offset(doc, walk.start_id, n))

    def test_signals_add_remove_edit(self):
        res, key = ASHELY_INTRO, 'START'
        items = start(res, key)['items']
        signals = [i for i in items if i['kind'] == 'signal']
        self.assertGreaterEqual(len(signals), 2)
        before = reread(res)
        edited = []
        for item in items:
            if item['id'] == signals[0]['id']:
                continue  # removed
            if item['id'] == signals[1]['id']:
                item = dict(item, value='fade_next_quick')  # edited
            edited.append(item)
        edited.insert(0, signal('reposition_top'))  # added
        chain(res, key, edited)
        got, walk, doc = disk_items(res, key)
        new_id = f'3_{before.numbers()["3"] + 1}'
        self.assertEqual(got[0], {'id': new_id, 'kind': 'signal', 'value': 'reposition_top'})
        self.assertNotIn(signals[0]['id'], doc.nodes)
        self.assertEqual(doc.nodes[signals[1]['id']]['signalValue'], 'fade_next_quick')
        self.assertEqual(sorted(doc.nodes[new_id]), ['link', 'offset', 'signalValue'])
        self.assertIn(f'&"{new_id}": {{\n"link": ', D.read_text(ed().path(res)))
        self.assertEqual(got, D.plain_items([dict(i, id=i['id'] or new_id) for i in edited]))

    def test_speakers(self):
        res, key = ASHELY_WIN, 'WIN_S1_TOP'
        items = start(res, key)['items']
        for item, speaker in zip(items, [1, 'Security', '', -1, 0]):
            item['speaker'] = speaker
        chain(res, key, items)
        got, _, doc = disk_items(res, key)
        self.assertEqual([i['speaker'] for i in got[:5]], [1, 'Security', '', -1, 0])
        self.assertIsInstance(doc.nodes[items[0]['id']]['speaker'], int)
        text = D.read_text(ed().path(res))
        self.assertIn('"speaker": "Security"', text)
        self.assertIn('"speaker": -1', text)

    def test_pictures_including_keep_previous(self):
        res, key = ASHELY_WIN, 'WIN_S1_TOP'
        lists = view(res)['lists']
        items = start(res, key)['items']
        items[1]['background'] = -1                 # keep the picture already on screen
        items[2]['backgroundList'], items[2]['background'] = 5, len(lists[5]['pictures']) - 1
        chain(res, key, items)
        got, _, _ = disk_items(res, key)
        self.assertEqual((got[1]['backgroundList'], got[1]['background']), (items[1]['backgroundList'], -1))
        self.assertEqual((got[2]['backgroundList'], got[2]['background']), (5, len(lists[5]['pictures']) - 1))
        self.assertNotIn('warnings', start(res, key)['items'][2])  # the page works out warnings itself

    def test_tricky_text(self):
        res, key = ASHELY_WIN, 'WIN_S1_TOP'
        items = start(res, key)['items']
        for item, text in zip(items, TRICKY):
            item['text'] = text
        chain(res, key, items)
        got, _, _ = disk_items(res, key)
        self.assertEqual([i['text'] for i in got[:len(TRICKY)]], TRICKY)
        raw = D.read_text(ed().path(res))
        self.assertIn('"dialogue": "first line\nsecond line\n\nfourth, after a blank one"', raw)  # line breaks stay literal
        self.assertIn('"dialogue": "She said \\"hi\\" and left"', raw)
        self.assertIn('"dialogue": "ends with a backslash \\\\"', raw)
        self.assertIn('日本語', raw)
        self.assertEqual(start(res, key)['items'][len(TRICKY) - 1]['text'], TRICKY[-1])

    def test_empty_chain(self):
        res, key = ASHELY_WIN, 'WIN_S2_WALK'
        old = self.chain_ids(res, key)
        chain(res, key, [])
        doc = reread(res)
        walk = doc.walk(key)
        self.assertEqual(walk.ids, [])
        self.assertEqual(doc.nodes[walk.start_id]['link'], 'END')
        self.assertTrue(walk.editable)
        for node_id in old:
            self.assertNotIn(node_id, doc.nodes)
        self.assertIn('drops a start', start(res, key)['warnings'][0])
        chain(res, key, [line('back again')])  # and lines can go back in
        self.assertEqual([i['text'] for i in disk_items(res, key)[0]], ['back again'])

    def test_add_start(self):
        res = ASHELY_INTRO
        before = reread(res)
        lowest = max((n for n in before.order if n.startswith('0_')), key=lambda n: D.offset_of(before.nodes[n])[1])
        lx, ly = D.offset_of(before.nodes[lowest])
        result = save(res, [{'op': 'add', 'key': 'NEW_TEST_START',
                             'items': [line('one', 1, 3, 0), signal('fade_next'), line('two', 0, 3, 1)]}])
        doc = reread(res)
        start_id = f'0_{before.numbers()["0"] + 1}'
        self.assertEqual(doc.starts[-1], ('NEW_TEST_START', start_id))
        node = doc.nodes[start_id]
        self.assertEqual(node['start_id'], 'NEW_TEST_START')
        self.assertEqual(node['offset'], f'Vector2({D.number_text(lx)}, {D.number_text(ly + 700)})')
        last_start = max((n for n in before.order if n.startswith('0_')), key=before.order.index)
        self.assertEqual(doc.order.index(start_id), doc.order.index(last_start) + 1)
        walk = doc.walk('NEW_TEST_START')
        self.assertTrue(walk.editable)
        self.assertEqual([i['text'] if i['kind'] == 'line' else i['value'] for i in D.doc_items(doc, walk)], ['one', 'fade_next', 'two'])
        for n, node_id in enumerate(walk.ids):
            self.assertEqual(doc.nodes[node_id]['offset'], row_offset(doc, start_id, n))
        self.assertEqual(result['starts'][0]['key'], 'NEW_TEST_START')
        self.assertIn(f'"NEW_TEST_START": &"{start_id}"\n}}', D.read_text(ed().path(res)))
        # The same key again, and keys that aren't usable.
        e = expect_error(self, 409, 'conflict', save, res, [{'op': 'add', 'key': 'NEW_TEST_START', 'items': []}])
        self.assertEqual(e.extra['conflicts'][0]['key'], 'NEW_TEST_START')
        for bad_key in ('bad key', 'quote"', 'a-b', '', 'x' * 200):
            expect_error(self, 400, None, save, res, [{'op': 'add', 'key': bad_key, 'items': []}])
        save(res, [{'op': 'add', 'key': 'EMPTY_START', 'items': []}])
        self.assertEqual(reread(res).nodes[reread(res).start_ids['EMPTY_START']]['link'], 'END')
        # After a given start in the start list (the page adds one after the start you were on).
        first = reread(res).starts[0][0]
        save(res, [{'op': 'add', 'key': 'AFTER_FIRST', 'items': [line('x')], 'after': first}])
        self.assertEqual([k for k, _ in reread(res).starts][:2], [first, 'AFTER_FIRST'])
        expect_error(self, 400, None, save, res, [{'op': 'add', 'key': 'BAD_AFTER', 'items': [], 'after': 5}])
        # A key that only looks right: a trailing line break got past the old check.
        for bad_key in ('NEWKEY\n', 'NEWKEY\r\n', 'A\nB'):
            expect_error(self, 400, 'bad-request', save, res, [{'op': 'add', 'key': bad_key, 'items': []}])
        self.assertNotIn('NEWKEY', D.read_text(ed().path(res)))

    def test_delete_start(self):
        res, key = ASHELY_WIN, 'WIN_S2_WALK'
        before = reread(res)
        walk = before.walk(key)
        s = start(res, key)
        expect_error(self, 409, 'conflict', save, res, [{'op': 'delete', 'key': key, 'base': 'stale'}])
        result = save(res, [{'op': 'delete', 'key': key, 'base': s['fingerprint']}])
        self.assertEqual(result['deleted'], [key])
        doc = reread(res)
        self.assertNotIn(key, doc.start_ids)
        for node_id in walk.ids + [walk.start_id]:
            self.assertNotIn(node_id, doc.nodes)
        self.assertEqual(len(doc.order), len(before.order) - len(walk.ids) - 1)
        for other, _ in doc.starts:
            self.assertEqual(doc.walk(other).fingerprint, before.walk(other).fingerprint, other)
        self.check_untouched(res, before, set(walk.ids) | {walk.start_id})

    def test_conflict_refuses_and_leaves_the_file(self):
        res, key = ASHELY_WIN, 'WIN_S1_TOP'
        s = start(res, key)
        first = copy.deepcopy(s['items'])
        first[0]['text'] = 'saved from another tab'
        chain(res, key, first, base=s['fingerprint'])
        after_first, backups = disk(res), len(backups_of(res))
        second = copy.deepcopy(s['items'])
        second[1]['text'] = 'my stale edit'
        e = expect_error(self, 409, 'conflict', chain, res, key, second, s['fingerprint'])
        self.assertEqual(e.extra['conflicts'], [{'key': key, 'why': 'it changed on disk since you opened it'}])
        self.assertEqual(disk(res), after_first)
        self.assertEqual(len(backups_of(res)), backups)
        # One conflicting start refuses the whole save, the good change included.
        good = start(res, 'WIN_S3_SHORTS')
        good['items'][0]['text'] = 'would be fine alone'
        expect_error(self, 409, 'conflict', save, res, [
            {'op': 'chain', 'key': 'WIN_S3_SHORTS', 'base': good['fingerprint'], 'items': good['items']},
            {'op': 'chain', 'key': key, 'base': s['fingerprint'], 'items': second}])
        self.assertEqual(disk(res), after_first)

    def test_non_linear_starts_are_refused(self):
        for res in (BRANCHING, SETS):
            refused = [s for s in view(res)['starts'] if not s['editable']]
            self.assertTrue(refused, res)
            for s in refused[:3]:
                self.assertIn('edit this one in Godot', s['reason'])
                before = disk(res)
                e = expect_error(self, 409, 'conflict', save, res,
                                 [{'op': 'chain', 'key': s['key'], 'base': s['fingerprint'], 'items': []}])
                self.assertIn('edit this one in Godot', e.extra['conflicts'][0]['why'])
                expect_error(self, 409, 'conflict', save, res, [{'op': 'delete', 'key': s['key'], 'base': s['fingerprint']}])
                self.assertEqual(disk(res), before)
        branching = view(BRANCHING)['starts'][0]
        self.assertIn('branches', branching['reason'])
        self.assertTrue(any(i.get('choices') for i in branching['items']))
        shared = [s for res in ed().scan()[0] for s in view(res)['starts'] if 'shares lines' in s.get('reason', '')]
        self.assertTrue(shared)
        others = [s for s in view(SETS)['starts'] if 'variable' in s.get('reason', '')]
        self.assertTrue(any(i['kind'] == 'other' and i['type'] in ('set', 'condition') for s in others for i in s['items']))

    def test_another_start_changed_on_disk_is_no_conflict(self):
        res = ASHELY_WIN
        mine = start(res, 'WIN_S1_TOP')
        # Another save changes a different start in between...
        theirs = start(res, 'WIN_S3_SHORTS')
        theirs['items'][0]['text'] = 'written elsewhere'
        chain(res, 'WIN_S3_SHORTS', theirs['items'])
        # ...and so does an outside program writing the text directly (as the packager does).
        path = ed().path(res)
        text = D.read_text(path)
        node_id = theirs['items'][1]['id']
        doc = D.Doc(text)
        old_raw = doc.raw[node_id]
        new_raw = old_raw.replace(f'"dialogue": {D.P.quote(theirs["items"][1]["text"])}', '"dialogue": "packager wrote this"')
        self.assertNotEqual(old_raw, new_raw)
        D.P.save_text(path, text.replace(old_raw, new_raw))
        mine['items'][0]['text'] = 'my edit'
        chain(res, 'WIN_S1_TOP', mine['items'], base=mine['fingerprint'])
        got_mine = disk_items(res, 'WIN_S1_TOP')[0]
        got_theirs = disk_items(res, 'WIN_S3_SHORTS')[0]
        self.assertEqual(got_mine[0]['text'], 'my edit')
        self.assertEqual([i['text'] for i in got_theirs[:2]], ['written elsewhere', 'packager wrote this'])

    def test_ids_reuse(self):
        res, key = ASHELY_WIN, 'WIN_S1_TOP'
        before = reread(res)
        top = start(res, key)['items']
        walk_ids = start(res, 'WIN_S2_WALK')['items']
        stolen = dict(walk_ids[0], text='an id from another start')
        duplicate = dict(top[0], text='same id twice')
        wrong_kind = signal('fade_next', node_id=top[1]['id'])
        made_up = line('an id nobody has', node_id='1_999999')
        items = [top[0], duplicate, wrong_kind, stolen, made_up] + top[3:]  # top[1] and top[2] are dropped
        chain(res, key, items)
        got, walk, doc = disk_items(res, key)
        n1, n3 = before.numbers()['1'], before.numbers().get('3', 0)
        self.assertEqual(got[0]['id'], top[0]['id'])
        self.assertEqual(got[1]['id'], f'1_{n1 + 1}')
        self.assertEqual(got[2]['id'], f'3_{n3 + 1}')
        self.assertEqual(got[3]['id'], f'1_{n1 + 2}')
        self.assertEqual(got[4]['id'], f'1_{n1 + 3}')
        self.assertEqual([g['id'] for g in got[5:]], [i['id'] for i in top[3:]])
        self.assertNotIn(top[1]['id'], doc.nodes)  # a dropped line's id is not handed out again
        self.assertNotIn(top[2]['id'], doc.nodes)
        self.assertEqual(doc.raw[walk_ids[0]['id']], before.raw[walk_ids[0]['id']])  # the other start keeps its node
        # Ids named anywhere count as taken: the strays of test_date_one, eg.
        strays = reread(STRAYS)
        numbers = [int(n.split('_')[1]) for n in strays.strays if n.startswith('1_')]
        self.assertGreaterEqual(strays.numbers()['1'], max(numbers))

    def test_layout_rule(self):
        res, key = ASHELY_WIN, 'WIN_S1_TOP'
        before = reread(res)
        items = start(res, key)['items']
        items[3]['text'] = 'only the words change'
        chain(res, key, items)
        doc = reread(res)
        for node_id in before.walk(key).ids:
            self.assertEqual(doc.nodes[node_id]['offset'], before.nodes[node_id]['offset'])
            if node_id != items[3]['id']:
                self.assertEqual(doc.raw[node_id], before.raw[node_id])
        # A different sequence: laid out in a row again, reused lines keep their size.
        moved = start(res, key)['items']
        moved = moved[1:] + moved[:1]
        chain(res, key, moved)
        doc = reread(res)
        walk = doc.walk(key)
        for n, node_id in enumerate(walk.ids):
            self.assertEqual(doc.nodes[node_id]['offset'], row_offset(doc, walk.start_id, n))
            self.assertEqual(doc.nodes[node_id]['size'], before.nodes[node_id]['size'])

    def test_new_nodes_follow_the_files_key_style(self):
        doc = reread(STR_KEYS)
        self.assertFalse(doc.name_keys)
        s = next(s for s in view(STR_KEYS)['starts'] if s['editable'] and s['lineCount'] >= 2)
        items = s['items']
        chain(STR_KEYS, s['key'], items[:1] + [line('new in a str-key file')] + items[1:])
        new_id = f'1_{doc.numbers()["1"] + 1}'
        text = D.read_text(ed().path(STR_KEYS))
        self.assertIn(f'\n"{new_id}": {{\n', text)
        self.assertIn(f'"link": &"{new_id}"', text)
        self.assertTrue(reread(ASHELY_WIN).name_keys)

    def test_backups_written_and_pruned(self):
        res, key = ASHELY_INTRO, 'START'
        folder = S['root'] / 'backups' / res.removeprefix('res://')
        shutil.rmtree(folder, ignore_errors=True)
        # A copy the Godot addon saved (it is older than every save below): pruning leaves it alone.
        folder.mkdir(parents=True)
        addon_copy = folder / f'20000101-000000-000{D.ADDON_BACKUP_SUFFIX}'
        addon_copy.write_bytes(b'outside version')
        last_before = None
        for n in range(53):
            items = start(res, key)['items']
            items[0]['text'] = f'version {n}'
            last_before = disk(res)
            chain(res, key, items)
        backups = [b for b in backups_of(res) if b != addon_copy]
        # The newest 50, and the day's first, which is the file from before the session.
        self.assertEqual(len(backups), 51)
        self.assertEqual(backups[-1].read_bytes(), last_before)
        self.assertEqual(backups[0].read_bytes(), S['originals'][res])
        self.assertEqual(addon_copy.read_bytes(), b'outside version')
        # An older day's first backup stays too, and an older day's other ones go.
        old_first, old_second = folder / '20000102-090000-000000.tres.bak', folder / '20000102-100000-000000.tres.bak'
        today = datetime.date.today().strftime('%Y%m%d')
        recent_first = folder / f'{today[:4]}0101-000000-000000.tres.bak'
        for path in (old_first, old_second):
            path.write_bytes(b'long ago')
        items = start(res, key)['items']
        items[0]['text'] = 'one more'
        chain(res, key, items)
        self.assertFalse(old_second.exists())
        self.assertFalse(old_first.exists())  # more than 60 days ago
        recent_first.write_bytes(b'this year')
        recent_second = folder / f'{today[:4]}0101-000001-000000.tres.bak'
        recent_second.write_bytes(b'this year, later')
        items[0]['text'] = 'and one more'
        chain(res, key, items)
        if (datetime.date.today() - datetime.date(datetime.date.today().year, 1, 1)).days <= D.KEEP_DAILY_DAYS:
            self.assertTrue(recent_first.exists())
        self.assertFalse(recent_second.exists())
        recent_first.unlink(missing_ok=True)
        addon_copy.unlink()
        self.assertEqual((S['root'] / 'backups' / '.gitignore').read_text(), '*\n')
        self.assertTrue((S['root'] / 'backups' / '.gdignore').exists())

    def test_write_retries_while_the_file_is_locked(self):
        res, key = ASHELY_INTRO, 'START'
        real_replace = os.replace
        calls = []

        def locked_twice(src, dst):
            calls.append(dst)
            if len(calls) <= 2:
                raise PermissionError(13, 'The process cannot access the file (simulated OneDrive lock)')
            return real_replace(src, dst)
        items = start(res, key)['items']
        items[0]['text'] = 'after a lock'
        with mock.patch('os.replace', side_effect=locked_twice):
            chain(res, key, items)
        self.assertEqual(len(calls), 3)
        self.assertEqual(disk_items(res, key)[0][0]['text'], 'after a lock')
        self.assertFalse(ed().path(res).with_name(ed().path(res).name + '.tmp').exists())

    def test_write_that_cannot_happen_leaves_the_file(self):
        res, key = ASHELY_INTRO, 'START'
        items = start(res, key)['items']
        items[0]['text'] = 'never written'
        tmp = ed().path(res).with_name(ed().path(res).name + '.tmp')
        backups = backups_of(res)
        with mock.patch('os.replace', side_effect=PermissionError(13, 'locked for good')), mock.patch('time.sleep'):
            expect_error(self, 503, 'locked', chain, res, key, items)
        self.assertEqual(disk(res), S['originals'][res])
        self.assertFalse(tmp.exists())
        self.assertEqual(backups_of(res), backups)  # nothing was saved, so no backup was kept
        with mock.patch('os.replace', side_effect=OSError(28, 'No space left on device')):
            expect_error(self, 500, 'write-failed', chain, res, key, items)
        self.assertEqual(disk(res), S['originals'][res])
        self.assertFalse(tmp.exists())

    def test_a_save_that_reads_back_wrong_is_put_back(self):
        res, key = ASHELY_INTRO, 'START'
        items = start(res, key)['items']
        items[0]['text'] = 'checked and found wrong'
        with mock.patch.object(D, 'verify', side_effect=[None, 'simulated damage']):
            e = expect_error(self, 500, 'restored', chain, res, key, items)
        self.assertIn('put back', str(e))
        self.assertEqual(disk(res), S['originals'][res])
        with mock.patch.object(D, 'verify', return_value='caught before writing'):
            expect_error(self, 500, 'check-failed', chain, res, key, items)
        self.assertEqual(disk(res), S['originals'][res])

    def test_verify_catches_damage(self):
        doc = reread(ASHELY_WIN)
        edit = D.Edit(doc)
        items = [D.clean_item(i) for i in start(ASHELY_WIN, 'WIN_S1_TOP')['items']]
        items[0]['text'] = 'changed'
        written = {'WIN_S1_TOP': edit.chain('WIN_S1_TOP', items, doc.walk('WIN_S1_TOP').ids)}
        changes = [{'op': 'chain', 'key': 'WIN_S1_TOP'}]
        text = edit.text()
        self.assertIsNone(D.verify(doc, text, changes, written, edit.touched))
        other = doc.walk('WIN_S3_SHORTS').ids[0]
        damaged = text.replace(doc.raw[other], doc.raw[other].replace('"dialogue": "', '"dialogue": "X'))
        self.assertIn('WIN_S3_SHORTS', D.verify(doc, damaged, changes, written, edit.touched))
        self.assertIsNotNone(D.verify(doc, text.replace('"WIN_S2_WALK"', '"WIN_S2_WALKX"', 1), changes, written, edit.touched))
        self.assertIsNotNone(D.verify(doc, text + ' ', changes, written, edit.touched))

    def test_bad_requests(self):
        res, key = ASHELY_INTRO, 'START'
        s = start(res, key)
        base = s['fingerprint']
        cases = [
            [{'op': 'rename', 'key': key}],
            [{'op': 'chain', 'key': key, 'items': []}],                                   # no base
            [{'op': 'chain', 'key': key, 'base': base, 'items': [{'kind': 'other'}]}],
            [{'op': 'chain', 'key': key, 'base': base, 'items': [line('x', speaker=True)]}],
            [{'op': 'chain', 'key': key, 'base': base, 'items': [line('x', bl='3')]}],
            [{'op': 'chain', 'key': key, 'base': base, 'items': [line('x', bg=-2)]}],
            [{'op': 'chain', 'key': key, 'base': base, 'items': [line('nul\x00inside')]}],
            [{'op': 'chain', 'key': key, 'base': base, 'items': [signal(5)]}],
            [{'op': 'chain', 'key': key, 'base': base, 'items': 'not a list'}],
            [{'op': 'chain', 'key': key, 'base': base, 'items': []}, {'op': 'chain', 'key': key, 'base': base, 'items': []}],
            'not a list',
        ]
        for changes in cases:
            expect_error(self, 400, None, ed().save, res, changes, True)
        self.assertEqual(disk(res), S['originals'][res])
        expect_error(self, 409, 'conflict', save, res, [{'op': 'chain', 'key': 'NO_SUCH_KEY', 'base': 'x', 'items': []}])
        expect_error(self, 404, 'not-found', ed().save, 'res://project.godot', [], True)
        expect_error(self, 403, 'outside', ed().save, 'res://../secret.tres', [], True)
        expect_error(self, 400, 'bad-path', ed().save, 'C:/Windows/win.ini', [], True)

    def test_godot_running_without_the_patch_asks_first(self):
        res, key = ASHELY_INTRO, 'START'
        items = start(res, key)['items']
        items[0]['text'] = 'while Godot runs'
        change = [{'op': 'chain', 'key': key, 'base': start(res, key)['fingerprint'], 'items': items}]
        running = {'godotRunning': ['Godot_v4.4.1-stable_win64.exe'], 'addonPatched': False}
        with mock.patch.object(ed(), 'status', return_value=running), mock.patch.object(ed(), 'addon_patched', return_value=False):
            e = expect_error(self, 409, 'godot-unpatched', ed().save, res, change, False)
            self.assertEqual(e.extra['godotRunning'], running['godotRunning'])
            self.assertEqual(disk(res), S['originals'][res])
            self.assertTrue(ed().save(res, change, True)['changed'])
        restore(res)
        with mock.patch.object(ed(), 'status', return_value=dict(running, godotRunning=[])), \
                mock.patch.object(ed(), 'addon_patched', return_value=False):
            self.assertTrue(ed().save(res, change, False)['changed'])  # Godot not running
        restore(res)
        with mock.patch.object(ed(), 'status', side_effect=AssertionError('no need to look')), \
                mock.patch.object(ed(), 'addon_patched', return_value=True):
            self.assertTrue(ed().save(res, change, False)['changed'])  # patched: saves without asking
        # The marker itself, in the copy's addon file.
        addon = S['copy'] / D.ADDON_FILES
        text = addon.read_text(encoding='utf-8')
        try:
            addon.write_text(text.replace(D.PATCH_MARKER, 'MARKER_GONE') + '\n# EXTERNAL_EDIT_SAFE\n', encoding='utf-8')
            self.assertTrue(ed().addon_patched())
            addon.write_text(text.replace(D.PATCH_MARKER, 'MARKER_GONE'), encoding='utf-8')
            self.assertFalse(ed().addon_patched())
        finally:
            addon.write_text(text, encoding='utf-8')

    def test_a_file_not_laid_out_as_godot_writes_is_read_only(self):
        res = ASHELY_INTRO
        path = ed().path(res)
        crlf = S['originals'][res].replace(b'\n', b'\r\n')
        path.write_bytes(crlf)
        ed().forget(res)
        v = view(res)
        self.assertIn('problem', v)
        self.assertTrue(all(not s['editable'] for s in v['starts']))
        s = v['starts'][0]
        expect_error(self, 409, 'unsupported', save, res, [{'op': 'chain', 'key': s['key'], 'base': s['fingerprint'], 'items': []}])
        self.assertEqual(path.read_bytes(), crlf)

    def test_versions_follow_saves(self):
        res, key = ASHELY_INTRO, 'START'
        version = ed().versions()[res]
        self.assertEqual(version, hashlib.sha1(disk(res)).hexdigest())
        items = start(res, key)['items']
        items[0]['text'] = 'new version'
        result = chain(res, key, items)
        self.assertNotEqual(result['version'], version)
        self.assertEqual(ed().versions()[res], result['version'])
        self.assertEqual(result['version'], hashlib.sha1(disk(res)).hexdigest())

    def test_signal_catalog_comes_from_the_game_code(self):
        catalog, _ = ed().signals()
        # The ones the page itself acts on (fades and box positions in its preview and play).
        for value in ('fade_next', 'fade_next_quick', 'fade_next_slow', 'reposition_bottom', 'reposition_top', 'atmosphere_off'):
            self.assertIn(value, catalog['exact'])
        self.assertIn('sets up fade for the next background transition', catalog['exact']['fade_next']['description'])
        self.assertTrue(catalog['exact']['fade_next']['source'].startswith('res://src/vn/Main.gd:'))
        self.assertEqual({p['prefix'] for p in catalog['patterns']}, {'play_sfx_', 'play_music_', 'atmosphere_'})
        signals = view(ASHELY_WIN)['signals']
        self.assertTrue(any(x['value'] == 'fade_next' and x['description'] for x in signals))
        self.assertTrue(any(x.get('prefix') == 'play_sfx_' for x in signals))

    def test_notes(self):
        win = view(ASHELY_WIN)['starts']
        with_notes = [s for s in win if s.get('notes')]
        if not Path(os.path.expanduser('~/invoke-remote-data/sorted/ashely2/scene.json')).exists():
            self.skipTest('no Ashely II scene.json on this machine')
        # The notes are the scene's own words (outside the repo, live): only their shape is checked.
        self.assertTrue(with_notes)
        for s in with_notes:
            self.assertTrue(set(s['notes']) <= {'title', 'when', 'next', 'context', 'state', 'designRow'}, s['notes'])
        self.assertFalse(any(s.get('notes') for s in view(BIG)['starts']))  # notes are scoped to the scene's stages
        self.assertEqual(D.safe_note_html('<b>bold</b> <code>X</code> <script>x</script> & "q" it\'s'),
                         '<b>bold</b> <code>X</code> &lt;script&gt;x&lt;/script&gt; &amp; "q" it\'s')
        bare = D.Editor(S['copy'], image_root=REAL, backups=S['root'] / 'backups', cache=S['root'] / 'cache',
                        config=S['root'] / 'no_such_config.json')
        self.assertFalse(any(s.get('notes') for s in bare.file(ASHELY_WIN)['starts']))
        broken = S['root'] / 'broken_config.json'
        broken.write_text('{"notes": ["~/no/such/scene.json"', encoding='utf-8')
        bare = D.Editor(S['copy'], image_root=REAL, backups=S['root'] / 'backups', cache=S['root'] / 'cache', config=broken)
        self.assertFalse(any(s.get('notes') for s in bare.file(ASHELY_WIN)['starts']))

    def test_search(self):
        found = ed().search('WIN_X3_UNDER')
        self.assertTrue(any(r['field'] == 'key' and r['key'] == 'WIN_X3_UNDER__TOP_OFF' for r in found['results']))
        self.assertTrue(any(r['field'] == 'picture' for r in found['results']))
        found = ed().search('fade_next', limit=5000, res=BIG)
        self.assertGreater(len([r for r in found['results'] if r['field'] == 'signal']), 20)
        self.assertTrue(all('fade_next' in r['snippet'].lower() for r in found['results']))
        found = ed().search('win', res=ASHELY_WIN)
        self.assertTrue(found['results'] and all(r['path'] == ASHELY_WIN for r in found['results']))
        found = ed().search('professor', limit=5000, res=BIG)
        self.assertTrue(any(r['field'] == 'speaker' and r['snippet'] == 'Professor' for r in found['results']))
        found = ed().search('', res=ASHELY_WIN, placeholder=True, limit=5000)
        self.assertEqual(len(found['results']), sum(s['placeholderCount'] for s in view(ASHELY_WIN)['starts']))
        self.assertEqual(ed().search('qzx distinctive phrase')['results'], [])
        items = start(ASHELY_WIN, 'WIN_S1_TOP')['items']
        items[2]['text'] = 'Somewhere she said a QZX Distinctive Phrase here'
        chain(ASHELY_WIN, 'WIN_S1_TOP', items)
        hit = ed().search('qzx distinctive phrase')['results']
        self.assertEqual(len(hit), 1)
        self.assertEqual((hit[0]['key'], hit[0]['itemIndex'], hit[0]['field']), ('WIN_S1_TOP', 2, 'text'))
        a, b = hit[0]['match']
        self.assertEqual(hit[0]['snippet'][a:b].lower(), 'qzx distinctive phrase')
        self.assertTrue(ed().search('the', limit=10)['truncated'])

    # ---- Godot's graph: where saved nodes go

    def test_a_hand_laid_chain_keeps_its_places(self):
        """In a file laid out by hand, a changed chain's kept nodes stay put, and its new nodes land
        on no other start's nodes (a relayout in a row used to put them on top of other chains)."""
        res = HAND_LAID
        before = reread(res)
        checked = 0
        for s in view(res)['starts']:
            if not s['editable'] or not s['items']:
                continue
            restore(res)
            before = reread(res)
            walk = before.walk(s['key'])
            others = [n for n in before.order if n not in set(walk.ids) | {walk.start_id}]
            was = overlapping(before, walk.ids, others)
            items = s['items']
            middle = len(items) // 2
            new_items = items[:middle] + [line('a line put in the middle')] + items[middle:] + [line('and one at the end')]
            chain(res, s['key'], new_items)
            after = reread(res)
            now = after.walk(s['key'])
            self.assertEqual(overlapping(after, now.ids, others) - was, set(), s['key'])
            new = [n for n in now.ids if n not in before.nodes]
            self.assertEqual(len(new), 2)
            first = now.ids[0]
            if first in before.nodes and before.nodes[first].get('offset') == after.nodes[first].get('offset'):
                checked += 1
            self.check_untouched_except(res, before, set(walk.ids) | {walk.start_id} | set(new))
        self.assertGreater(checked, 0)

    def check_untouched_except(self, res, before, touched):
        after = reread(res)
        for node_id in before.order:
            if node_id not in touched:
                self.assertEqual(after.raw.get(node_id), before.raw[node_id], node_id)

    def test_relaid_chains_land_on_no_other_start(self):
        """Every editable start of every frozen file, one line added in the middle and one at the end
        (in memory): no new overlaps with other starts' nodes (281 chains did, laid out in a row)."""
        new_overlaps, chains = [], 0
        for res in H.FIXTURES:
            doc = reread(res)
            for key, _ in doc.starts:
                walk = doc.walk(key)
                if not walk.editable or not walk.ids:
                    continue
                edit = D.Edit(doc)
                items = [D.clean_item(i) for i in D.plain_items(D.doc_items(doc, walk))]
                middle = len(items) // 2
                items = items[:middle] + [D.clean_item(line('middle'))] + items[middle:] + [D.clean_item(line('end'))]
                written = edit.chain(key, items, walk.ids)
                ids = [i['id'] for i in written]
                others = [n for n in edit.order if n not in set(ids) | set(walk.ids) | {walk.start_id}]
                was = overlapping(doc, walk.ids, others)
                after = type('After', (), {'nodes': edit.nodes})()
                now = {(a, b) for a, box in boxes(after, ids) for b, other in boxes(after, others) if D.overlaps(box, other)}
                if now - was:
                    new_overlaps.append((res.rsplit('/', 1)[1], key, sorted(now - was)[:3]))
                chains += 1
        print(f'\n  {chains} chains with two lines added: {len(new_overlaps)} with new overlaps', file=sys.stderr)
        self.assertEqual(new_overlaps, [])

    def test_a_new_start_goes_below_every_node(self):
        """A file whose chains run down below its lowest start node: a new start and its lines go
        below all of it, at the start nodes' x, and its first line clears the start node."""
        res = LOW_CHAINS
        before = reread(res)
        save(res, [{'op': 'add', 'key': 'BELOW_ALL', 'items': [line('one'), signal('fade_next'), line('two')]}])
        doc = reread(res)
        walk = doc.walk('BELOW_ALL')
        mine = [walk.start_id] + walk.ids
        self.assertEqual(overlapping(doc, mine, before.order), set())
        bottom = max(y + h for _, (x, y, w, h) in boxes(before, before.order))
        self.assertGreaterEqual(D.offset_of(doc.nodes[walk.start_id])[1], bottom)
        lowest = max((n for n in before.order if n.startswith('0_')), key=lambda n: D.offset_of(before.nodes[n])[1])
        self.assertEqual(D.offset_of(doc.nodes[walk.start_id])[0], D.offset_of(before.nodes[lowest])[0])
        sx = D.offset_of(doc.nodes[walk.start_id])[0]
        self.assertGreaterEqual(D.offset_of(doc.nodes[walk.ids[0]])[0], sx + D.SCENE_SIZES['0'][0])

    # ---- saving: what goes wrong, and what is said about it

    def test_a_line_break_changed_from_cr_to_lf_is_written(self):
        """A \r in a line, changed to \n (as the page's text box does), is written: the check for
        'nothing changed' used to read the file with line breaks translated, and refused it."""
        res, key = ASHELY_WIN, 'WIN_S1_TOP'
        items = start(res, key)['items']
        items[0]['text'] = 'line one\rline two'
        chain(res, key, items)
        self.assertIn('line one\rline two', D.read_text(ed().path(res)))
        items = start(res, key)['items']
        self.assertEqual(items[0]['text'], 'line one\rline two')
        items[0]['text'] = 'line one\nline two'
        self.assertTrue(chain(res, key, items)['changed'])
        text = D.read_text(ed().path(res))
        self.assertIn('line one\nline two', text)
        self.assertNotIn('\r', text)

    def test_odd_text_is_refused_and_named(self):
        """A lone surrogate (half an emoji) is a 400 before anything is written, and a refused item
        says which start and line it is."""
        res, key = ASHELY_WIN, 'WIN_S1_TOP'
        items = start(res, key)['items']
        backups = backups_of(res)
        for bad_text in ('half \ud83d an emoji', 'pasted\x00text'):
            changed = copy.deepcopy(items)
            changed[4]['text'] = bad_text
            e = expect_error(self, 400, 'bad-request', chain, res, key, changed)
            self.assertEqual((e.extra['key'], e.extra['item']), (key, 4))
            self.assertIn(f'{key}, item 5', str(e))
        self.assertEqual(disk(res), S['originals'][res])
        self.assertEqual(backups_of(res), backups)

    def test_an_outside_write_during_a_save_is_kept(self):
        """The packager (or Godot) writes another start while a save is being made: the save starts
        again from the file as it is now, so both changes are in it."""
        res = ASHELY_WIN
        mine = start(res, 'WIN_S1_TOP')
        theirs = start(res, 'WIN_S3_SHORTS')
        theirs_items = copy.deepcopy(theirs['items'])
        theirs_items[0]['text'] = 'the packager wrote this meanwhile'
        real_backup = D.Editor.backup
        calls = []

        def backup_then_outside_write(editor, res_, text):
            target = real_backup(editor, res_, text)
            if not calls:
                calls.append(target)
                edit = D.Edit(D.Doc(text))
                edit.chain('WIN_S3_SHORTS', [D.clean_item(i) for i in theirs_items], D.Doc(text).walk('WIN_S3_SHORTS').ids)
                time.sleep(0.02)
                D.P.save_text(ed().path(res_), edit.text())
            return target
        mine['items'][0]['text'] = 'my edit'
        with mock.patch.object(D.Editor, 'backup', backup_then_outside_write):
            result = chain(res, 'WIN_S1_TOP', mine['items'], base=mine['fingerprint'])
        self.assertTrue(result['changed'])
        self.assertEqual(disk_items(res, 'WIN_S1_TOP')[0][0]['text'], 'my edit')
        self.assertEqual(disk_items(res, 'WIN_S3_SHORTS')[0][0]['text'], 'the packager wrote this meanwhile')
        self.assertFalse(calls[0].exists())  # the first go's backup went with it
        self.assertNotEqual(result['before'], hashlib.sha1(S['originals'][res]).hexdigest())

    def test_a_save_says_which_version_it_started_from(self):
        res, key = ASHELY_INTRO, 'START'
        items = start(res, key)['items']
        items[0]['text'] = 'versions'
        result = chain(res, key, items)
        self.assertEqual(result['before'], hashlib.sha1(S['originals'][res]).hexdigest())
        self.assertEqual(result['version'], hashlib.sha1(disk(res)).hexdigest())

    def test_a_failed_check_puts_back_only_its_own_write(self):
        res, key = ASHELY_INTRO, 'START'
        items = start(res, key)['items']
        items[0]['text'] = 'checked and found wrong'
        real_write = D.write_text
        # The old file can't be put back (it stays locked): the page is told the truth.
        writes = []

        def write_then_locked(path, text):
            writes.append(text)
            if len(writes) > 1:
                raise D.EditorError('it stayed locked', 503, code='locked')
            return real_write(path, text)
        with mock.patch.object(D, 'verify', side_effect=[None, 'simulated damage']), \
                mock.patch.object(D, 'write_text', side_effect=write_then_locked):
            e = expect_error(self, 500, 'restore-failed', chain, res, key, items)
        self.assertIn('may hold the unchecked new version', str(e))
        self.assertIn(e.extra['backup'], str(e))
        self.assertEqual(Path(e.extra['backup']).read_bytes(), S['originals'][res])
        restore(res)
        # Another program writes the file just after the save: its version stays.

        def write_then_other(path, text):
            real_write(path, text)
            D.P.save_text(path, text.replace('checked and found wrong', 'OTHER PROGRAM WROTE THIS'))
        with mock.patch.object(D, 'write_text', side_effect=write_then_other):
            e = expect_error(self, 409, 'overwritten', chain, res, key, items)
        self.assertIn('OTHER PROGRAM WROTE THIS', D.read_text(ed().path(res)))
        self.assertIn('another program wrote', str(e))

    def test_one_odd_file_does_not_stop_the_others(self):
        """A file the editor trips over (a bug, or something not thought of) is unreadable on its own;
        startup, the file list and search carry on with the rest."""
        real_view = D.Editor._view
        odd = ASHELY_LOSE

        def trips(editor, entry):
            if entry.res == odd:
                raise ValueError('invalid literal for int() with base 10: the odd one')
            return real_view(editor, entry)
        fresh = D.Editor(S['copy'], image_root=REAL, backups=S['root'] / 'backups', cache=S['root'] / 'cache')
        with mock.patch.object(D.Editor, '_view', trips), mock.patch('sys.stderr'):
            self.assertEqual(fresh.warm(), len(fresh.scan()[0]) - 1)
            found = fresh.search('the', limit=5000)['results']
            self.assertTrue(found and not any(r['path'] == odd for r in found))
            e = expect_error(self, 500, 'internal', fresh.file, odd)
            self.assertIn('the odd one', str(e))
            self.assertTrue(any(f['path'] == ASHELY_WIN for f in fresh.files()['files']))
        # The signal value that used to do this (a superscript digit) saves and shows like any other.
        items = start(ASHELY_INTRO, 'START')['items'] + [signal('play_sfx_²')]
        chain(ASHELY_INTRO, 'START', items)
        self.assertEqual(start(ASHELY_INTRO, 'START')['items'][-1]['value'], 'play_sfx_²')
        self.assertIsInstance(ed().search('zzzz_no_match'), dict)

    def test_a_picture_that_appears_shows(self):
        """The file's view follows its picture files: one put in later stops being 'missing'."""
        editor = D.Editor(S['copy'], image_root=S['copy'], backups=S['root'] / 'backups', cache=S['root'] / 'cache')
        lists = editor.file(ASHELY_WIN)['lists']
        picture = next(p for l in lists for p in l['pictures'] if p.get('missing'))
        target = S['copy'] / picture['image'][6:]
        try:
            target.parent.mkdir(parents=True, exist_ok=True)
            Image.new('RGB', (12, 16), (200, 30, 30)).save(target, 'WEBP')
            with mock.patch.object(D, 'STAT_EVERY', 0.05):
                time.sleep(0.1)
                shown = next(p for l in editor.file(ASHELY_WIN)['lists'] for p in l['pictures'] if p['image'] == picture['image'])
            self.assertFalse(shown.get('missing'))
            self.assertTrue(shown['thumb'])
        finally:
            target.unlink(missing_ok=True)

    def test_read_only_items_say_where_they_lead(self):
        """So the page's play can follow one way through a start with choices or conditions."""
        starts = view(SETS)['starts']
        branching = next(s for s in starts if any(i.get('type') == 'condition' for i in s['items']))
        condition = next(i for i in branching['items'] if i.get('type') == 'condition')
        self.assertEqual(len(condition['next']), 2)
        ids = {i['id'] for i in branching['items']}
        for item in branching['items']:
            self.assertTrue(all(n == 'END' or n in ids for n in item['next']), item)
        self.assertTrue(all('next' not in i for s in view(ASHELY_WIN)['starts'] for i in s['items']))


# ---------------------------------------------------------------- 3. Godot reads what was saved

@unittest.skipIf(os.environ.get('DE_SKIP_GODOT') or not H.GODOT.exists(), 'Godot not available')
class Test3Godot(unittest.TestCase):
    """The saved files, loaded by Godot itself and walked the way the game's dialogue box does."""

    @classmethod
    def setUpClass(cls):
        restore_all()
        cls.sandbox = S['root'] / 'godot_sandbox'
        started = time.time()
        code, cls.import_output = H.godot_import(S['copy'], cls.sandbox)
        print(f'\n  godot --import on the copy: exit {code} in {time.time() - started:.1f}s', file=sys.stderr)
        files = ed().scan()[0]
        cls.base_code, cls.base_output, cls.baseline = H.godot_walk(S['copy'], cls.sandbox, files)
        cls.expected = {}
        cls.changed = cls.mutate()
        cls.code, cls.output, cls.reports = H.godot_walk(S['copy'], cls.sandbox, cls.changed, dump=True)
        done = [l for l in cls.output.splitlines() if l.startswith('WALK DONE')]
        print(f'  godot walk, baseline: {[l for l in cls.base_output.splitlines() if l.startswith("WALK DONE")]}; '
              f'after the saves: {done} ({len(cls.changed)} changed files)', file=sys.stderr)

    @classmethod
    def mutate(cls):
        """A spread of saves over five files of both key styles: every kind of edit the editor makes."""
        win = start(ASHELY_WIN, 'WIN_S1_TOP')
        items = win['items']
        for item, text in zip(items, TRICKY):
            item['text'] = text
        for item, speaker in zip(items, [1, 'Security', '', -1, 0, 1]):
            item['speaker'] = speaker
        items[6]['background'] = -1
        items[7]['backgroundList'], items[7]['background'] = 2, 0
        items = items[:3] + [line('inserted', 1, items[2]['backgroundList'], items[2]['background']), signal('fade_next')] \
            + items[3:9] + items[10:]
        items[1], items[2] = items[2], items[1]
        walk = start(ASHELY_WIN, 'WIN_S2_WALK')
        shorts = start(ASHELY_WIN, 'WIN_S3_SHORTS')
        save(ASHELY_WIN, [
            {'op': 'chain', 'key': 'WIN_S1_TOP', 'base': win['fingerprint'], 'items': items},
            {'op': 'chain', 'key': 'WIN_S2_WALK', 'base': walk['fingerprint'], 'items': []},
            {'op': 'delete', 'key': 'WIN_S3_SHORTS', 'base': shorts['fingerprint']},
            {'op': 'add', 'key': 'GODOT_CHECK_NEW', 'items': [signal('reposition_top'), line('new start, line one', 1, 3, 0),
                                                             line('line two "quoted"\nwith a break', 0, 3, -1)]}])
        intro = start(ASHELY_INTRO, 'START')
        intro_items = [i for i in intro['items'] if i['kind'] == 'line'] + [signal('fade_next_slow')]
        save(ASHELY_INTRO, [{'op': 'chain', 'key': 'START', 'base': intro['fingerprint'], 'items': intro_items}])
        lose = start(ASHELY_LOSE, 'LOSE_P3B_BENCH_GIRL')
        save(ASHELY_LOSE, [{'op': 'delete', 'key': 'LOSE_P3B_BENCH_GIRL', 'base': lose['fingerprint']},
                           {'op': 'add', 'key': 'EMPTY_ONE', 'items': []}])
        park = next(s for s in view(STR_KEYS)['starts'] if s['editable'] and s['lineCount'] >= 3)
        park_items = park['items'][:2] + [line('str-key file, new line', 0, 0, -1), signal('walk_on')] + park['items'][2:]
        save(STR_KEYS, [{'op': 'chain', 'key': park['key'], 'base': park['fingerprint'], 'items': park_items}])
        big = next(s for s in view(BIG)['starts'] if s['editable'] and s['lineCount'] >= 4)
        big_items = big['items']
        big_items[0]['text'] = 'anna_class edited: "quotes" \\ and\nbreaks'
        del big_items[1]
        big_items.append(line('appended at the end', 'Professor'))
        save(BIG, [{'op': 'chain', 'key': big['key'], 'base': big['fingerprint'], 'items': big_items}])
        cls.expected = {ASHELY_WIN: {'WIN_S1_TOP': items, 'WIN_S2_WALK': []}, ASHELY_INTRO: {'START': intro_items},
                        STR_KEYS: {park['key']: park_items}, BIG: {big['key']: big_items}, ASHELY_LOSE: {'EMPTY_ONE': []}}
        cls.deleted = {ASHELY_WIN: 'WIN_S3_SHORTS', ASHELY_LOSE: 'LOSE_P3B_BENCH_GIRL'}
        return [res for res, data in S['originals'].items() if disk(res) != data]

    def test_baseline_walks_clean(self):
        """Godot loads every dialogue file of the copy. The frozen ones walk clean; a problem in a
        live file is the game's (printed here), not the editor's."""
        self.assertEqual(sorted(self.baseline), sorted(ed().scan()[0]), self.base_output[-3000:])
        errors = {p: r['errors'] for p, r in self.baseline.items() if r['errors']}
        live = {p: e for p, e in errors.items() if p not in H.FIXTURES}
        if live:
            print(f'\n  the live project has dialogue problems Godot finds: {live}', file=sys.stderr)
        self.assertEqual({p: e for p, e in errors.items() if p in H.FIXTURES}, {})

    def test_changed_files_load_and_walk_clean(self):
        self.assertEqual(sorted(self.changed), sorted([ASHELY_WIN, ASHELY_INTRO, ASHELY_LOSE, STR_KEYS, BIG]))
        for res in self.changed:
            self.assertIn(res, self.reports, self.output[-3000:])
            self.assertEqual(self.reports[res]['errors'], [], res)
        self.assertEqual(self.code, 0)
        self.assertIn('GODOT_CHECK_NEW', self.reports[ASHELY_WIN]['keys'])
        self.assertNotIn('WIN_S3_SHORTS', self.reports[ASHELY_WIN]['keys'])
        self.assertNotIn('LOSE_P3B_BENCH_GIRL', self.reports[ASHELY_LOSE]['keys'])

    def test_godot_reads_what_the_editor_wrote(self):
        """Every editable start of every changed file, as Godot read it, is item for item what the
        editor reads, and the changed starts are what was saved (text, speakers, pictures, signals)."""
        compared = 0
        for res in self.changed:
            chains = self.reports[res]['chains']
            for s in view(res)['starts']:
                if not s['editable']:
                    continue
                self.assertEqual(chains[s['key']], D.plain_items(s['items']), f'{res} {s["key"]}')
                compared += 1
            for key, items in self.expected.get(res, {}).items():
                got = [{k: v for k, v in i.items() if k != 'id'} for i in chains[key]]
                want = []
                for item in items:
                    item = {k: v for k, v in D.clean_item(item).items() if k != 'id'}
                    if item['kind'] == 'line':
                        item.setdefault('characterState', -1)  # a new line's state
                    want.append(item)
                self.assertEqual(got, want, f'{res} {key}')
        print(f'\n  Godot and the editor agree on {compared} starts in the changed files', file=sys.stderr)
        texts = [i['text'] for i in self.reports[ASHELY_WIN]['chains']['WIN_S1_TOP'] if i['kind'] == 'line']
        for text in TRICKY[:9]:
            self.assertIn(text, texts)

    def test_the_walker_does_find_problems(self):
        """A file with a dangling link, a picture out of range and a missing speaker is reported, so a
        clean walk above means something."""
        text = S['originals'][ASHELY_INTRO].decode('utf-8')
        doc = D.Doc(text)
        walk = doc.walk('START')
        line_ids = [n for n in walk.ids if n.startswith('1_')]
        broken = text.replace(doc.raw[line_ids[0]], doc.raw[line_ids[0]].replace('"background": ', '"background": 9', 1))
        broken = broken.replace(doc.raw[line_ids[1]], doc.raw[line_ids[1]].replace('"speaker": ', '"speaker": 5', 1))
        last = doc.raw[walk.ids[-1]]
        broken = broken.replace(last, last.replace('"link": "END"', '"link": &"1_9999"'))
        target = S['copy'] / '_walk' / 'broken.tres'
        target.parent.mkdir(exist_ok=True)
        target.write_text(broken, encoding='utf-8', newline='')
        try:
            code, output, reports = H.godot_walk(S['copy'], self.sandbox, ['res://_walk/broken.tres'])
        finally:
            target.unlink()
        errors = reports['res://_walk/broken.tres']['errors']
        print(f'\n  walker on a broken file: {errors}', file=sys.stderr)
        self.assertNotEqual(code, 0)
        self.assertTrue(any('not in the file' in e for e in errors))
        self.assertTrue(any('picture' in e for e in errors))
        self.assertTrue(any('speaker' in e for e in errors))


# ---------------------------------------------------------------- 4. the HTTP API

class Server:
    def __init__(self, editor):
        self.server = E.make_server(editor, 0)
        self.port = self.server.server_address[1]
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()

    def request(self, method, path, body=None, headers=None):
        connection = http.client.HTTPConnection('127.0.0.1', self.port, timeout=120)
        headers = dict(headers or {})
        if isinstance(body, (dict, list)):
            body = json.dumps(body).encode('utf-8')
            headers.setdefault('Content-Type', 'application/json')
        connection.request(method, path, body=body, headers=headers)
        response = connection.getresponse()
        data = response.read()
        connection.close()
        kind = response.getheader('Content-Type', '')
        return response.status, response, json.loads(data) if kind.startswith('application/json') else data

    def stop(self):
        self.server.shutdown()
        self.server.server_close()


def query(res):
    return urllib.parse.quote(res, safe='')


class Test4Http(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        restore_all()
        cls.web = Server(ed())

    @classmethod
    def tearDownClass(cls):
        cls.web.stop()

    def get(self, path, **kw):
        return self.web.request('GET', path, **kw)

    def post(self, path, body, **kw):
        return self.web.request('POST', path, body, **kw)

    def test_page(self):
        status, response, body = self.get('/')
        self.assertEqual(status, 200)
        self.assertTrue(response.getheader('Content-Type').startswith('text/html'))
        self.assertIn(b'<', body)

    def test_files(self):
        status, _, body = self.get('/api/files')
        self.assertEqual(status, 200)
        self.assertEqual(len(body['files']), len(ed().scan()[0]))
        entry = next(f for f in body['files'] if f['path'] == ASHELY_WIN)
        for field in ('path', 'name', 'folder', 'stages', 'startCount', 'lineCount', 'placeholderCount', 'editable', 'version'):
            self.assertIn(field, entry)
        self.assertEqual(entry['stages'][0]['name'], 'ashely2_win')
        self.assertEqual(entry['startCount'], 31)
        self.assertTrue(entry['editable'])
        # The start keys in brief (for the page's quick-open) agree with the file's own view.
        status, _, view = self.get(f'/api/file?path={query(ASHELY_WIN)}')
        self.assertEqual(entry['starts'], [{'key': s['key'], 'editable': s['editable'], 'lineCount': s['lineCount'],
                                            'placeholderCount': s['placeholderCount']} for s in view['starts']])
        self.assertEqual(sum(f['startCount'] for f in body['files'] if 'starts' in f),
                         sum(len(f['starts']) for f in body['files'] if 'starts' in f))

    def test_file(self):
        status, _, body = self.get(f'/api/file?path={query(ASHELY_WIN)}')
        self.assertEqual(status, 200)
        self.assertEqual([c['name'] for c in body['characters']], ['You', 'Ashely'])
        self.assertRegex(body['characters'][1]['color'], r'^#[0-9a-f]{6}$')
        picture = body['lists'][5]['pictures'][0]
        self.assertTrue(picture['thumb'].startswith('/img?path=res%3A%2F%2F'))
        s = next(s for s in body['starts'] if s['key'] == 'WIN_S1_TOP')
        for field in ('key', 'nodeId', 'editable', 'fingerprint', 'items'):
            self.assertIn(field, s)
        self.assertEqual(set(s['items'][0]) - {'warnings'}, {'id', 'kind', 'speaker', 'text', 'backgroundList', 'background', 'characterState'})
        self.assertTrue(any(sig['value'] == 'fade_next' for sig in body['signals']))
        self.assertEqual(body['version'], hashlib.sha1(disk(ASHELY_WIN)).hexdigest())

    def test_paths_outside_the_project_are_refused(self):
        for path, status in [('res://../project.godot', 403), ('res://data/../../x.tres', 403), ('C:/Windows/win.ini', 400),
                             ('res://data\\..\\..\\x', 400), ('res://project.godot', 404), ('', 400),
                             ('res://data/x.tres:stream', 400), ('res:///etc/passwd', 400)]:
            code, _, body = self.get(f'/api/file?path={query(path)}')
            self.assertEqual(code, status, f'{path}: {body}')
            self.assertIn('error', body)
        code, _, _ = self.get('/api/file')
        self.assertEqual(code, 400)
        code, _, _ = self.get(f'/img?path={query("res://../outside.png")}&w=100')
        self.assertEqual(code, 403)
        code, _, _ = self.get(f'/img?path={query("res://project.godot")}')
        self.assertEqual(code, 400)
        code, _, _ = self.get(f'/img?path={query("res://data/no_such_picture.png")}')
        self.assertEqual(code, 404)

    def test_search_versions_status_signals(self):
        status, _, body = self.get('/api/search?q=WIN_S1_TOP')
        self.assertEqual(status, 200)
        self.assertTrue(any(r['field'] == 'key' for r in body['results']))
        self.assertTrue(set(body['results'][0]) >= {'path', 'key', 'itemIndex', 'field', 'snippet'})
        status, _, body = self.get(f'/api/search?q=&placeholder=1&path={query(ASHELY_LOSE)}')
        self.assertTrue(body['results'] and all(r['path'] == ASHELY_LOSE for r in body['results']))
        status, _, versions = self.get('/api/versions')
        self.assertEqual(len(versions), len(ed().scan()[0]))
        self.assertEqual(versions[ASHELY_WIN], hashlib.sha1(disk(ASHELY_WIN)).hexdigest())
        status, _, body = self.get('/api/status')
        self.assertEqual(set(body), {'godotRunning', 'addonPatched'})
        self.assertIsInstance(body['addonPatched'], bool)
        code, _, _ = self.get('/api/signals')  # gone: the page gets the signals with each file
        self.assertEqual(code, 404)
        code, _, _ = self.get('/api/nothing')
        self.assertEqual(code, 404)

    def test_done_marks(self):
        """Starts marked done go in done.json under the project given (here the copy), never in a
        dialogue file. A second mark keeps the first date; a start not in the file yet can be marked."""
        path = S['copy'] / 'tooling' / 'dialogue_editor' / 'done.json'
        path.unlink(missing_ok=True)
        dialogue = S['editor'].path(ASHELY_INTRO).read_bytes()
        self.assertEqual(self.get('/api/done')[:3:2], (200, {'done': {}}))
        status, _, body = self.post('/api/done', {'path': ASHELY_INTRO, 'key': 'START', 'done': True})
        self.assertEqual(status, 200, body)
        when = body['done'][ASHELY_INTRO]['START']
        self.post('/api/done', {'path': ASHELY_INTRO, 'key': 'NOT_SAVED_YET', 'done': True})
        _, _, body = self.post('/api/done', {'path': ASHELY_INTRO, 'key': 'START', 'done': True})
        self.assertEqual(body['done'][ASHELY_INTRO]['START'], when)
        self.assertEqual(sorted(body['done'][ASHELY_INTRO]), ['NOT_SAVED_YET', 'START'])
        self.assertEqual(json.loads(path.read_text(encoding='utf-8'))['done'], body['done'])
        self.assertEqual(self.get('/api/done')[2], body)
        for key in ('START', 'NOT_SAVED_YET'):
            _, _, body = self.post('/api/done', {'path': ASHELY_INTRO, 'key': key, 'done': False})
        self.assertEqual(body, {'done': {}})
        for bad in ({'path': 'C:/x.tres', 'key': 'A', 'done': True}, {'path': ASHELY_INTRO, 'key': ' ', 'done': True},
                    {'path': ASHELY_INTRO, 'key': 'A' + chr(10) + 'B', 'done': True}, {'path': ASHELY_INTRO, 'key': 'A', 'done': 'yes'}, [1]):
            self.assertEqual(self.post('/api/done', bad)[0], 400, bad)
        path.write_text('not json', encoding='utf-8')
        self.assertEqual(self.get('/api/done')[2], {'done': {}})
        path.unlink()
        self.assertEqual(S['editor'].path(ASHELY_INTRO).read_bytes(), dialogue)

    def test_reveal(self):
        """Show in folder / Play video: the server shows or opens a picture or video of the project,
        and nothing else, nor anything outside it. The tests open nothing (DE_NO_LAUNCH), and the
        launcher is watched instead."""
        picture = 'res://data/background_lists/ashely_poker2/WIN_S1_TOP/01.webp'
        video = 'res://data/background_lists/ashely_poker2/video/WIN_S1_TOP/04.ogv'
        status, _, body = self.post('/api/reveal', {'path': picture})
        self.assertEqual(status, 200, body)
        self.assertEqual((Path(body['path']), body['play'], body['launched']), (REAL / picture[6:], False, False))
        with mock.patch.object(D, 'launch', return_value=True) as launch:
            status, _, body = self.post('/api/reveal', {'path': video, 'play': True})
            self.assertEqual((status, body['play'], body['launched']), (200, True, True), body)
            self.post('/api/reveal', {'path': video, 'play': 'yes'})  # only true plays
            self.assertEqual([call.args for call in launch.call_args_list], [(REAL / video[6:], True), (REAL / video[6:], False)])
            for bad, code in (({'path': 'res://project.godot'}, 400), ({'path': ASHELY_INTRO}, 400), ({'path': 'C:/Windows/x.png'}, 400),
                              ({'path': 'res://../x.png'}, 403), ({'path': 'res://data/nothing_here.ogv'}, 404), ({}, 400), ([1], 400)):
                self.assertEqual(self.post('/api/reveal', bad)[0], code, bad)
            self.assertEqual(launch.call_count, 2)
        # What Explorer is given on Windows: the file selected, in quotes, back slashes.
        with mock.patch.dict(os.environ), mock.patch.object(D.subprocess, 'Popen') as popen, mock.patch.object(D.os, 'name', 'nt'):
            del os.environ['DE_NO_LAUNCH']
            self.assertTrue(D.launch(REAL / picture[6:]))
            self.assertEqual(popen.call_args.args, (f'explorer /select,"{REAL / picture[6:]}"',))

    def test_match_pictures(self):
        """The picture each poker match opens on: picks go in match_pictures.json beside done.json
        (under the project given), set or cleared several at once."""
        path = S['copy'] / 'tooling' / 'dialogue_editor' / 'match_pictures.json'
        path.unlink(missing_ok=True)
        self.assertEqual(self.get('/api/matches')[2], {'picks': {}})
        first = {'list': 'TABLE__DRESSED', 'picture': 'TABLE__DRESSED_03'}
        status, _, body = self.post('/api/matches', {'set': {'FIRST': first, 'DRESSED_0_1': first}})
        self.assertEqual(status, 200, body)
        self.assertEqual(body['picks'], {'DRESSED_0_1': first, 'FIRST': first})
        _, _, body = self.post('/api/matches', {'set': {'DRESSED_0_1': None}})
        self.assertEqual(body['picks'], {'FIRST': first})
        self.assertEqual(json.loads(path.read_text(encoding='utf-8'))['picks'], body['picks'])
        self.assertEqual(self.get('/api/matches')[2], body)
        for bad in ({'set': {}}, {'set': {'../x': first}}, {'set': {'FIRST': {'list': 'A'}}}, {'set': {'FIRST': 'TABLE__DRESSED_03'}}, {'set': []}, [1]):
            self.assertEqual(self.post('/api/matches', bad)[0], 400, bad)
        path.unlink()

    def test_wallpapers(self):
        """The pictures picked as wallpapers (the Gallery's Wallpapers): picks go in wallpaper_picks.json beside
        done.json by picture file, set or cleared several at once; seed marks the lists pre-picked once."""
        path = S['copy'] / 'tooling' / 'dialogue_editor' / 'wallpaper_picks.json'
        path.unlink(missing_ok=True)
        self.assertEqual(self.get('/api/wallpapers')[2], {'picks': {}, 'seeded': {}})
        one = 'res://data/background_lists/ashely_poker2/WIN_L4_KISS/32.webp'
        two = 'res://data/background_lists/ashely_poker2/WIN_L4_KISS/58.webp'
        lists = 'res://data/game_stages/vn/ashely2_intro/bgs.tres'
        status, _, body = self.post('/api/wallpapers', {'set': {one: {'list': 'WIN_L4_KISS', 'picture': 'WIN_L4_KISS_32'},
                                                                two: {'list': 'WIN_L4_KISS', 'picture': 'WIN_L4_KISS_58'}}, 'seed': lists})
        self.assertEqual(status, 200, body)
        self.assertEqual(sorted(body['picks']), [one, two])
        self.assertEqual(list(body['seeded']), [lists])
        _, _, body = self.post('/api/wallpapers', {'set': {two: None}})
        self.assertEqual(list(body['picks']), [one])
        self.assertEqual(list(body['seeded']), [lists], 'a pick leaves the seeds alone')
        saved = json.loads(path.read_text(encoding='utf-8'))
        self.assertEqual((saved['picks'], saved['seeded']), (body['picks'], body['seeded']))
        self.assertEqual(self.get('/api/wallpapers')[2], body)
        for bad in ({'set': {'../x.webp': None}}, {'set': {'res://a.tres': None}}, {'set': {one: {'list': 'A'}}},
                    {'set': {one: 'WIN_L4_KISS_32'}}, {'set': []}, {'set': {}, 'seed': 'bgs.tres'}, [1]):
            self.assertEqual(self.post('/api/wallpapers', bad)[0], 400, bad)
        path.unlink()

    def test_save_conflict_and_bad_requests(self):
        s = start(ASHELY_INTRO, 'START')
        items = copy.deepcopy(s['items'])
        items[0]['text'] = 'saved over HTTP'
        change = {'path': ASHELY_INTRO, 'confirmGodot': True,
                  'changes': [{'op': 'chain', 'key': 'START', 'base': s['fingerprint'], 'items': items}]}
        status, _, body = self.post('/api/save', change)
        self.assertEqual(status, 200, body)
        self.assertTrue(body['ok'] and body['changed'])
        self.assertEqual(body['starts'][0]['items'][0]['text'], 'saved over HTTP')
        self.assertTrue(Path(body['backup']).exists())
        _, _, versions = self.get('/api/versions')
        self.assertEqual(versions[ASHELY_INTRO], body['version'])
        status, _, body = self.post('/api/save', change)  # the same base again: stale now
        self.assertEqual(status, 409)
        self.assertEqual(body['code'], 'conflict')
        self.assertEqual(body['conflicts'][0]['key'], 'START')
        status, _, body = self.web.request('POST', '/api/save', b'{"path": ', {'Content-Type': 'application/json'})
        self.assertEqual((status, body['code']), (400, 'bad-json'))
        status, _, body = self.web.request('POST', '/api/save', b'[1, 2]', {'Content-Type': 'application/json'})
        self.assertEqual(status, 400)
        status, _, body = self.web.request('POST', '/api/save', json.dumps(change).encode(), {'Content-Type': 'text/plain'})
        self.assertEqual(status, 415)
        status, _, body = self.post('/api/save', change, headers={'Origin': 'http://evil.example'})
        self.assertEqual((status, body['code']), (403, 'origin'))
        status, _, body = self.post('/api/save', change, headers={'Origin': 'http://127.0.0.1:8765'})  # another local page
        self.assertEqual((status, body['code']), (403, 'origin'))
        status, _, body = self.post('/api/save', change, headers={'Origin': f'http://localhost:{self.web.port}'})
        self.assertEqual((status, body['code']), (409, 'conflict'))  # its own page gets through (to the stale base)
        status, _, body = self.get('/api/files', headers={'Host': f'evil.example:{self.web.port}'})
        self.assertEqual((status, body['code']), (403, 'host'))
        status, _, body = self.post('/api/save', dict(change, path='res://../x.tres'))
        self.assertEqual(status, 403)
        status, _, body = self.post('/api/nowhere', {})
        self.assertEqual(status, 404)
        # Half an emoji in the JSON: a 400 naming the line, not a 500 halfway through the save.
        broken = copy.deepcopy(change)
        broken['changes'][0]['base'] = start(ASHELY_INTRO, 'START')['fingerprint']
        broken['changes'][0]['items'][0]['text'] = 'half \ud83d'
        status, _, body = self.post('/api/save', broken)
        self.assertEqual((status, body['code'], body.get('item')), (400, 'bad-request', 0), body)
        # A Content-Length that isn't a number, or is negative: a 400 at once.
        for length in ('abc', '-1', '1e3'):
            connection = http.client.HTTPConnection('127.0.0.1', self.web.port, timeout=10)
            connection.putrequest('POST', '/api/save')
            connection.putheader('Content-Type', 'application/json')
            connection.putheader('Content-Length', length)
            connection.endheaders()
            started = time.perf_counter()
            response = connection.getresponse()
            data = json.loads(response.read())
            connection.close()
            self.assertEqual((response.status, data['code']), (400, 'bad-request'), length)
            self.assertLess(time.perf_counter() - started, 5)
        restore(ASHELY_INTRO)

    def test_pictures_and_thumbnails(self):
        _, _, body = self.get(f'/api/file?path={query(ASHELY_WIN)}')
        picture = next(p for l in body['lists'] for p in l['pictures'] if p['image'].endswith('.webp') and p.get('thumb'))
        started = time.perf_counter()
        status, response, first = self.get(picture['thumb'])
        cold = time.perf_counter() - started
        self.assertEqual(status, 200)
        self.assertEqual(response.getheader('Content-Type'), 'image/jpeg')
        with Image.open(BytesIO(first)) as img:
            self.assertLessEqual(img.size[0], 240)
        thumbs = list((S['root'] / 'cache' / 'thumbs').glob('*.jpg'))
        self.assertTrue(thumbs)
        self.assertTrue((S['root'] / 'cache' / '.gdignore').exists())
        started = time.perf_counter()
        status, _, second = self.get(picture['thumb'])
        warm = time.perf_counter() - started
        self.assertEqual(second, first)
        print(f'\n  thumbnail: {cold * 1000:.0f} ms made, {warm * 1000:.0f} ms from the cache', file=sys.stderr)
        status, response, full = self.get(picture['full'])
        self.assertEqual(status, 200)
        self.assertEqual(response.getheader('Content-Type'), 'image/webp')
        self.assertEqual(full, (REAL / picture['image'][6:]).read_bytes())
        code, _, _ = self.get(picture['thumb'].replace('&w=240', '&w=abc'))
        self.assertEqual(code, 400)

    def test_command_line(self):
        """The real command: --port 0 picks a free port; a second editor on a busy port says so."""
        command = [sys.executable, '-P', '-E', str(TOOL_DIR / 'dialogue_editor.py'), '--project', str(S['copy']),
                   '--image-root', str(REAL), '--no-open', '--backups', str(S['root'] / 'cli_backups'),
                   '--cache', str(S['root'] / 'cli_cache')]
        first = subprocess.Popen(command + ['--port', '0'], stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                 text=True, encoding='utf-8')
        try:
            url = None
            lines = []
            deadline = time.time() + 120
            while time.time() < deadline:
                text = first.stdout.readline()
                if not text:
                    break
                lines.append(text)
                found = re.search(r'dialogue editor: http://127\.0\.0\.1:(\d+)/', text)
                if found:
                    url = int(found.group(1))
                    break
            self.assertIsNotNone(url, ''.join(lines))
            connection = http.client.HTTPConnection('127.0.0.1', url, timeout=30)
            connection.request('GET', '/api/files')
            response = connection.getresponse()
            self.assertEqual(response.status, 200)
            self.assertEqual(len(json.loads(response.read())['files']), len(ed().scan()[0]))
            connection.close()
            second = subprocess.run(command + ['--port', str(url)], capture_output=True, text=True, timeout=120)
            self.assertEqual(second.returncode, 0, second.stdout + second.stderr)
            self.assertIn('already in use', second.stdout)
            print(f'\n  command line: {lines[0].strip()} / busy port: {second.stdout.strip()}', file=sys.stderr)
        finally:
            first.terminate()
            first.wait(timeout=30)
            first.stdout.close()


# ---------------------------------------------------------------- 5. timing on the real project (read only)

class Test5Timing(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Backups and thumbnails would go to the temp folder; no route used here writes either.
        cls.editor = D.Editor(REAL, backups=S['root'] / 'real_backups', cache=S['root'] / 'real_cache')
        started = time.perf_counter()
        cls.count = cls.editor.warm()
        cls.startup = time.perf_counter() - started
        cls.web = Server(cls.editor)

    @classmethod
    def tearDownClass(cls):
        cls.web.stop()

    def timed(self, path):
        started = time.perf_counter()
        status, _, body = self.web.request('GET', path)
        return status, time.perf_counter() - started, body

    def test_read_routes_are_quick(self):
        rows = []
        files = self.editor.scan()[0]
        biggest = max(files, key=lambda r: self.editor.path(r).stat().st_size)
        smallest = min(files, key=lambda r: self.editor.path(r).stat().st_size)
        for path in ['/api/files', f'/api/file?path={query(biggest)}', f'/api/file?path={query(smallest)}',
                     '/api/search?q=the', '/api/search?q=START', '/api/search?q=fade_next',
                     '/api/search?q=&placeholder=1', '/api/versions']:
            times = []
            for _ in range(3):
                status, seconds, body = self.timed(path)
                self.assertEqual(status, 200, path)
                times.append(seconds)
            rows.append((path, min(times), max(times), len(json.dumps(body))))
            self.assertLess(max(times), 1.0, path)
        status, seconds, _ = self.timed('/api/status')
        rows.append(('/api/status (runs tasklist, cached 3 s)', seconds, seconds, 0))
        print(f'\n  real project: read {self.count} files at startup in {self.startup:.2f}s', file=sys.stderr)
        for path, fastest, slowest, size in rows:
            print(f'    {path[:60]:60} {fastest * 1000:7.1f} ms .. {slowest * 1000:7.1f} ms  {size / 1024:8.1f} KB', file=sys.stderr)
        # The real backups are the user's own saves: the tests only must not add any.
        self.assertEqual(real_backups(), S['real_backups'])


# ---------------------------------------------------------------- 6. the Ashely II files (real project, read only)

class Test6AshelySanity(unittest.TestCase):
    def test_ashely_files_read_cleanly(self):
        editor = D.Editor(REAL, backups=S['root'] / 'real_backups', cache=S['root'] / 'real_cache')
        files = sorted(r for r in editor.scan()[0] if '/ashely2_' in r)
        if not files:
            self.skipTest('no Ashely II dialogue files in the project')
        print('', file=sys.stderr)
        for res in files:
            v = editor.file(res)
            starts = v['starts']
            lines = sum(s['lineCount'] for s in starts)
            print(f'  {res.rsplit("/", 1)[1]:24} starts {len(starts):2} (editable {sum(s["editable"] for s in starts):2}), '
                  f'lines {lines:3} ({sum(s["placeholderCount"] for s in starts):3} placeholders), '
                  f'signals {sum(1 for s in starts for i in s["items"] if i["kind"] == "signal")}, '
                  f'characters {[c["name"] for c in v["characters"]]}, {len(v["lists"])} picture lists '
                  f'({sum(len(l["pictures"]) for l in v["lists"])} pictures), notes on {sum(1 for s in starts if s.get("notes"))}, '
                  f'stage {[s["name"] for s in v["stages"]]}', file=sys.stderr)
            self.assertTrue(all(s['editable'] or s.get('reason') for s in starts), res)
            self.assertTrue(v['characters'] and all(c['name'] for c in v['characters']), res)
            self.assertTrue(v['lists'], res)
            missing = [p['image'] for l in v['lists'] for p in l['pictures'] if p.get('missing')]
            if missing:
                print(f'    pictures the lists name that are not there: {missing[:5]}', file=sys.stderr)


# ---------------------------------------------------------------- 7. the game facts the page keeps by hand

class Test7GameFacts(unittest.TestCase):
    """editor.html keeps the game's box positions, font sizes, box signals and fade times (FRAMES,
    REPOSITION, FADES), copied from src/vn/DialogueManager.tscn, DialogueManager.gd and
    Background.gd. When the game's change, this says which to copy again."""

    @classmethod
    def setUpClass(cls):
        cls.page = (TOOL_DIR / 'editor.html').read_text(encoding='utf-8')
        cls.scene = (REAL / 'src/vn/DialogueManager.tscn').read_text(encoding='utf-8')

    def rect(self, path):
        found = re.search(rf'^\[node name="{path.rsplit("/", 1)[1]}" type="ReferenceRect" parent="{path.rsplit("/", 1)[0]}"\]\n(.*?)(?=^\[|\Z)',
                          self.scene, re.MULTILINE | re.DOTALL)
        self.assertIsNotNone(found, path)
        body = found.group(1)
        number = lambda name: float((re.search(rf'^{name} = (-?[\d.]+)', body, re.MULTILINE) or [0, 0])[1])
        return number('offset_left'), number('offset_top'), number('offset_right'), number('offset_bottom'), body

    def test_box_positions_and_fonts(self):
        for frame, layout in (('portrait', 'Portrait'), ('landscape', 'Landscape')):
            spec = re.search(rf'{frame}: \{{ w: (\d+), h: (\d+), box: \[(\d+), (\d+)\], font: (\d+), speakerFont: (\d+),\s*'
                             r'places: \{(.*?)\} \}', self.page, re.DOTALL)
            self.assertIsNotNone(spec, frame)
            left, top, right, bottom, body = self.rect(f'Layouts/{layout}')
            self.assertEqual((int(spec[1]), int(spec[2])), (right - left, bottom - top), f'{frame} frame size')
            self.assertEqual(int(spec[5]), int(re.search(r'^fontSize = (\d+)', body, re.MULTILINE)[1]), f'{frame} font size')
            speaker = re.search(r'^speakerFontSize = (\d+)', body, re.MULTILINE)
            if speaker:
                self.assertEqual(int(spec[6]), int(speaker[1]), f'{frame} speaker font size')
            for name, x, y in re.findall(r'(\w+): \[(\d+), (\d+)\]', spec[7]):
                l, t, r, b, _ = self.rect(f'Layouts/{layout}/{name}')
                self.assertEqual((int(x), int(y)), (l, t), f'{frame} {name}')
                self.assertEqual((int(spec[3]), int(spec[4])), (r - l, b - t), f'{frame} {name} box size')

    def test_box_signals(self):
        """REPOSITION: each reposition_* signal and the layout it moves the box to (DialogueManager.gd)."""
        code = (REAL / 'src/vn/DialogueManager.gd').read_text(encoding='utf-8')
        game = dict(re.findall(r'"(reposition_\w+)"\s*:\s*setDialogueBox(\w+)\(\)', code))
        page = dict(re.findall(r'(reposition_\w+): \'(\w+)\'', re.search(r'const REPOSITION = \{(.*?)\};', self.page, re.DOTALL)[1]))
        self.assertTrue(game)
        self.assertEqual(page, game)

    def test_fade_times(self):
        code = (REAL / 'src/vn/Background.gd').read_text(encoding='utf-8')
        fades = dict(re.findall(r'(fade_next\w*): (\d+)', re.search(r'const FADES = \{(.*?)\};', self.page)[1]))
        for flag, value in (('shouldFade', 'fade_next'), ('shouldFadeQuick', 'fade_next_quick'), ('shouldFadeSlow', 'fade_next_slow')):
            seconds = re.search(rf'{flag} = false\s*\n(?:.*\n){{1,2}}?\s*\$FadeTimer\.start\(([\d.]+)\)', code)
            self.assertIsNotNone(seconds, flag)
            self.assertEqual(int(fades[value]), round(float(seconds[1]) * 1000), value)


if __name__ == '__main__':
    unittest.main()
