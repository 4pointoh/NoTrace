// The dialogue editor's page, driven in headless Chrome over the DevTools protocol (Node 22's own
// WebSocket: nothing to install). It writes only to a temporary copy of the project.
//
//   node tooling/dialogue_editor/tests/browser_test.mjs [--copy DIR] [--shots DIR] [--keep]
//
// Without --copy it makes a copy of the project's text files under the system temp folder (the
// pictures are read from the real project, read-only; the files it looks into line by line are
// the frozen snapshot in tests/fixtures, see helpers.py) and removes it afterwards. --copy must
// not be the real project or inside it. It starts the editor on a free port, runs every step
// below against it, and checks the saved file on disk. Screenshots are taken only with --shots,
// into that folder; they show the game's pictures, so keep them on this machine.
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const TESTS = path.dirname(fileURLToPath(import.meta.url));
const TOOL = path.dirname(TESTS);
const REAL = path.resolve(TOOL, '..', '..');
const CHROME = process.env.CHROME_BIN || 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const PYTHON = process.env.PYTHON_BIN || 'python';
const WIN = 'res://data/game_stages/vn/ashely2_win/d_ashely2_win.tres';
const INTRO3 = 'res://data/game_stages/vn/intro/d_intro3.tres';
const BOA = 'res://data/game_stages/poker/boa_poker_new_poker/d_boa_poker_new_poker.tres';

const args = process.argv.slice(2);
const opt = name => { const i = args.indexOf('--' + name); return i >= 0 ? args[i + 1] : null; };
const flag = name => args.includes('--' + name);
let tmpRoot = null;	// made by main(): importing this file makes nothing
let shotsDir = null;	// --shots DIR: the screenshots go there; none without it

const results = [];
const sleep = ms => new Promise(r => setTimeout(r, ms));
function check(name, ok, detail = '') {
	results.push({ name, ok: !!ok, detail });
	console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  — ' + detail : ''}`);
	return !!ok;
}

// ---------------------------------------------------------------- the copy and the server

function makeCopy(dest) {
	const code = `import sys; sys.path.insert(0, sys.argv[1]); import helpers; print(helpers.make_copy(sys.argv[2]))`;
	const out = execFileSync(PYTHON, ['-P', '-E', '-c', code, TESTS, dest], { encoding: 'utf-8' });
	return +out.trim();
}
// Whether a folder is the real project or inside it (a test must never save there).
function inReal(dir) {
	const rel = path.relative(path.resolve(REAL), path.resolve(dir));
	return rel === '' || (!rel.startsWith('..') && !path.isAbsolute(rel));
}
function startServer(project, root = tmpRoot) {
	if (inReal(project)) throw new Error(`refusing to run the editor on ${project}: it is the real project (or inside it)`);
	return new Promise((resolve, reject) => {
		const proc = spawn(PYTHON, ['-P', '-E', path.join(TOOL, 'dialogue_editor.py'), '--project', project, '--image-root', REAL,
			'--port', '0', '--no-open', '--backups', path.join(root, 'backups'), '--cache', path.join(root, 'cache'), '--done', path.join(root, 'done.json')],
			// DE_NO_LAUNCH: "Show in folder" and "Play video" answer without opening a window on this screen.
			{ stdio: ['ignore', 'pipe', 'pipe'], env: { ...process.env, DE_NO_LAUNCH: '1' } });
		let out = '';
		const timer = setTimeout(() => reject(new Error('the server did not start: ' + out)), 30000);
		proc.stdout.on('data', d => {
			out += d;
			const m = out.match(/dialogue editor: (http:\/\/127\.0\.0\.1:\d+\/)/);
			if (m) { clearTimeout(timer); resolve({ proc, url: m[1] }); }
		});
		proc.stderr.on('data', d => { out += d; process.stderr.write('[server] ' + d); });
		proc.on('exit', code => { clearTimeout(timer); reject(new Error(`the server exited (${code}): ${out}`)); });
	});
}
function startKeysOnDisk(project, res) {
	const code = `import sys, json; sys.path.insert(0, sys.argv[1]); import dialogues as D
print(json.dumps([k for k, _ in D.Doc(D.read_text(sys.argv[2])).starts]))`;
	return JSON.parse(execFileSync(PYTHON, ['-P', '-E', '-c', code, TOOL, path.join(project, res.replace('res://', ''))], { encoding: 'utf-8' }));
}
function chainOnDisk(project, res, key) {
	const code = `import sys, json; sys.path.insert(0, sys.argv[1]); import dialogues as D
doc = D.Doc(D.read_text(sys.argv[2])); w = doc.walk(sys.argv[3])
print(json.dumps({'editable': w.editable, 'items': D.doc_items(doc, w)}))`;
	const file = path.join(project, res.replace('res://', ''));
	return JSON.parse(execFileSync(PYTHON, ['-P', '-E', '-c', code, TOOL, file, key], { encoding: 'utf-8' }));
}

// ---------------------------------------------------------------- Chrome over CDP

export class Chrome {
	async launch(width, height) {
		this.ownRoot = tmpRoot ? null : fs.mkdtempSync(path.join(os.tmpdir(), 'debt_'));
		this.profile = path.join(tmpRoot || this.ownRoot, 'profile');
		this.proc = spawn(CHROME, ['--headless=new', '--remote-debugging-port=0', `--user-data-dir=${this.profile}`, '--no-first-run',
			'--no-default-browser-check', '--disable-extensions', '--disable-background-networking', '--disable-sync', '--disable-component-update',
			'--disable-default-apps', '--mute-audio', '--hide-scrollbars', `--window-size=${width},${height}`, 'about:blank'], { stdio: 'ignore' });
		const portFile = path.join(this.profile, 'DevToolsActivePort');
		for (let i = 0; i < 200 && !fs.existsSync(portFile); i++) await sleep(100);
		await sleep(200);
		const [port, wsPath] = fs.readFileSync(portFile, 'utf-8').split('\n');
		this.ws = new WebSocket(`ws://127.0.0.1:${port}${wsPath.trim()}`);
		await new Promise((resolve, reject) => { this.ws.onopen = resolve; this.ws.onerror = reject; });
		this.nextId = 1;
		this.pending = new Map();
		this.listeners = [];
		this.ws.onmessage = m => {
			const msg = JSON.parse(m.data);
			if (msg.id && this.pending.has(msg.id)) {
				const { resolve, reject } = this.pending.get(msg.id);
				this.pending.delete(msg.id);
				if (msg.error) reject(new Error(msg.error.message)); else resolve(msg.result);
			} else if (msg.method) {
				for (const l of this.listeners) l(msg);
			}
		};
		const { targetId } = await this.send('Target.createTarget', { url: 'about:blank' });
		const { sessionId } = await this.send('Target.attachToTarget', { targetId, flatten: true });
		this.session = sessionId;
	}
	send(method, params = {}, session) {
		const id = this.nextId++;
		const message = { id, method, params };
		if (session) message.sessionId = session;
		this.ws.send(JSON.stringify(message));
		return new Promise((resolve, reject) => this.pending.set(id, { resolve, reject }));
	}
	page(method, params) { return this.send(method, params, this.session); }
	// Another tab on the same browser (same storage, same BroadcastChannel): { session, targetId }.
	async newTab(url) {
		const { targetId } = await this.send('Target.createTarget', { url });
		const { sessionId } = await this.send('Target.attachToTarget', { targetId, flatten: true });
		await this.send('Runtime.enable', {}, sessionId);
		return { session: sessionId, targetId };
	}
	async evalIn(session, expression) {
		const r = await this.send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true }, session);
		if (r.exceptionDetails) throw new Error('page: ' + (r.exceptionDetails.exception?.description || r.exceptionDetails.text));
		return r.result.value;
	}
	async waitIn(session, expression, timeout = 8000, what = expression) {
		const until = Date.now() + timeout;
		while (Date.now() < until) {
			try { if (await this.evalIn(session, expression)) return true; } catch { /* not ready */ }
			await sleep(50);
		}
		throw new Error('timed out waiting for ' + what);
	}
	on(fn) { this.listeners.push(fn); }
	async eval(expression) {
		const r = await this.page('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
		if (r.exceptionDetails) throw new Error('page: ' + (r.exceptionDetails.exception?.description || r.exceptionDetails.text));
		return r.result.value;
	}
	async waitFor(expression, timeout = 8000, what = expression) {
		const until = Date.now() + timeout;
		while (Date.now() < until) {
			try { if (await this.eval(expression)) return true; } catch { /* not ready */ }
			await sleep(50);
		}
		throw new Error('timed out waiting for ' + what);
	}
	async key(key, { ctrl, shift, alt, text } = {}) {
		const VK = { Enter: 13, Backspace: 8, Delete: 46, ArrowUp: 38, ArrowDown: 40, ArrowLeft: 37, ArrowRight: 39, Escape: 27, F5: 116,
			PageUp: 33, PageDown: 34, Tab: 9, '/': 191, ' ': 32, '?': 191, Home: 36, End: 35, F2: 113 };
		const CODE = { Enter: 'Enter', Backspace: 'Backspace', Delete: 'Delete', ArrowUp: 'ArrowUp', ArrowDown: 'ArrowDown', ArrowLeft: 'ArrowLeft',
			ArrowRight: 'ArrowRight', Escape: 'Escape', F5: 'F5', PageUp: 'PageUp', PageDown: 'PageDown', Tab: 'Tab', '/': 'Slash', ' ': 'Space', '?': 'Slash',
			Home: 'Home', End: 'End', F2: 'F2' };
		let vk = VK[key], code = CODE[key];
		if (vk == null && /^[a-z0-9]$/i.test(key)) { vk = key.toUpperCase().charCodeAt(0); code = /\d/.test(key) ? 'Digit' + key : 'Key' + key.toUpperCase(); }
		const modifiers = (alt ? 1 : 0) | (ctrl ? 2 : 0) | (shift ? 8 : 0);
		const printable = text ?? (key.length === 1 && !ctrl && !alt ? key : key === 'Enter' && !ctrl && !alt ? '\r' : undefined);
		const base = { key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk, modifiers };
		await this.page('Input.dispatchKeyEvent', { type: printable ? 'keyDown' : 'rawKeyDown', ...base, ...(printable ? { text: printable, unmodifiedText: printable } : {}) });
		await this.page('Input.dispatchKeyEvent', { type: 'keyUp', ...base });
		await sleep(30);
	}
	async type(text) { await this.page('Input.insertText', { text }); await sleep(30); }
	async click(selector, { shift, index = 0 } = {}) {
		const box = await this.eval(`(() => { const n = document.querySelectorAll(${JSON.stringify(selector)})[${index}]; if (!n) return null; n.scrollIntoView({ block: 'nearest' }); const r = n.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; })()`);
		if (!box) throw new Error('nothing to click: ' + selector);
		const modifiers = shift ? 8 : 0;
		await this.page('Input.dispatchMouseEvent', { type: 'mouseMoved', x: box.x, y: box.y, modifiers });
		await this.page('Input.dispatchMouseEvent', { type: 'mousePressed', x: box.x, y: box.y, button: 'left', clickCount: 1, modifiers });
		await this.page('Input.dispatchMouseEvent', { type: 'mouseReleased', x: box.x, y: box.y, button: 'left', clickCount: 1, modifiers });
		await sleep(60);
	}
	async size(width, height) {
		await this.page('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: false });
		await sleep(150);
	}
	async shot(name, clipSelector) {
		if (!shotsDir) return null;
		await sleep(250);
		const params = { format: 'png' };
		if (clipSelector) {
			const r = await this.eval(`(() => { const r = document.querySelector(${JSON.stringify(clipSelector)}).getBoundingClientRect(); return { x: r.left, y: r.top, width: r.width, height: r.height }; })()`);
			params.clip = { ...r, scale: 1 };
		}
		const { data } = await this.page('Page.captureScreenshot', params);
		const file = path.join(shotsDir, name + '.png');
		fs.writeFileSync(file, Buffer.from(data, 'base64'));
		return file;
	}
	async close() {
		try { await this.send('Browser.close'); } catch { /* already gone */ }
		await sleep(300);
		try { this.proc.kill(); } catch { /* gone */ }
		if (this.ownRoot) try { fs.rmSync(this.ownRoot, { recursive: true, force: true, maxRetries: 5 }); } catch { /* still in use */ }
	}
}

// ---------------------------------------------------------------- page helpers

const model = `(() => { const st = curStart(); return st ? st.items.map(i => i.kind === 'line' ? { id: i.id, kind: i.kind, speaker: i.speaker, text: i.text, backgroundList: i.backgroundList, background: i.background } : { id: i.id, kind: i.kind, value: i.value }) : null; })()`;
const focusedIndex = `(() => { const n = document.activeElement; const row = n && n.closest && n.closest('.item'); const st = curStart(); return row ? st.items.findIndex(i => i.uid === row._uid) : -1; })()`;
async function setCaret(c, at) { await c.eval(`(() => { const n = document.activeElement; n.setSelectionRange(${at}, ${at}); return true; })()`); }
function same(a, b) { return JSON.stringify(a) === JSON.stringify(b); }
function strip(items) {
	return items.map(i => i.kind === 'line' ? { kind: 'line', speaker: i.speaker, text: i.text, backgroundList: i.backgroundList, background: i.background } : { kind: i.kind, value: i.value });
}

// ---------------------------------------------------------------- the run

async function main() {
	let project = opt('copy');
	const ownCopy = !project;
	if (project && inReal(project)) { console.log(`FAIL  --copy ${project} is the real project, or inside it: give a copy`); process.exitCode = 1; return; }
	tmpRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'debt_'));
	if (opt('shots')) { shotsDir = path.resolve(opt('shots')); fs.mkdirSync(shotsDir, { recursive: true }); }
	if (ownCopy) {
		project = path.join(tmpRoot, 'proj');
		const n = makeCopy(project);
		console.log(`copy: ${project} (${n} text files)`);
	}
	const { proc: server, url } = await startServer(project);
	console.log('server: ' + url);
	const c = new Chrome();
	const consoleErrors = [];
	const requests = [];
	let expectedErrors = 0;
	try {
		await c.launch(1600, 1000);
		c.on(msg => {
			if (msg.sessionId !== c.session) return;
			if (msg.method === 'Runtime.exceptionThrown') consoleErrors.push('exception: ' + (msg.params.exceptionDetails.exception?.description || msg.params.exceptionDetails.text));
			if (msg.method === 'Runtime.consoleAPICalled' && (msg.params.type === 'error' || msg.params.type === 'assert')) consoleErrors.push('console: ' + msg.params.args.map(a => a.value ?? a.description).join(' '));
			if (msg.method === 'Log.entryAdded' && msg.params.entry.level === 'error') consoleErrors.push('log: ' + msg.params.entry.text + ' ' + (msg.params.entry.url || ''));
			if (msg.method === 'Network.requestWillBeSent') requests.push(msg.params.request.url);
			if (msg.method === 'Page.javascriptDialogOpening') c.page('Page.handleJavaScriptDialog', { accept: true });
		});
		await c.page('Page.enable');
		await c.page('Runtime.enable');
		await c.page('Network.enable');
		await c.page('Log.enable');
		await c.size(1600, 1000);

		// ---- load
		const started = Date.now();
		await c.page('Page.navigate', { url });
		await c.waitFor(`typeof S !== 'undefined' && S.loaded && !!curStart()`, 15000, 'the page to load a file');
		check('load: page shows a file and a start', await c.eval(`$('fileName').textContent.length > 0 && $('rows') !== null && $('startList').children.length > 0`), `${Date.now() - started} ms`);
		// Fade is on unless turned off. The checks below count rows, so it goes off here; its own
		// checks (after the Replace button's) turn it on again.
		const fadeDefault = await c.eval(`[S.autoFade, $('fadeBtn').classList.contains('on'), $('fadeBtn').getAttribute('aria-pressed')]`);
		await c.eval(`(toggleFade(false), true)`);

		// ---- Ctrl+P to WIN_X3_UNDER__TOP_OFF
		await c.key('p', { ctrl: true });
		await c.waitFor(`!$('quick').hidden`);
		await c.type('x3undertop');
		await sleep(80);
		const firstHit = await c.eval(`S.quickResults[0] && S.quickResults[0].e.key + '|' + S.quickResults[0].e.path`);
		check('quick open: fuzzy "x3undertop" ranks WIN_X3_UNDER__TOP_OFF first', firstHit === `WIN_X3_UNDER__TOP_OFF|${WIN}`, firstHit);
		await c.shot('quick_open_1600');
		await c.key('Enter');
		await c.waitFor(`S.key === 'WIN_X3_UNDER__TOP_OFF' && S.path === ${JSON.stringify(WIN)} && $('rows').children.length === 7`, 8000, 'the start to open');
		const original = await c.eval(model);
		const selAll = await c.eval(`(() => { const n = document.activeElement; return n.tagName === 'TEXTAREA' && n.selectionStart === 0 && n.selectionEnd === n.value.length && n.value.startsWith('(Placeholder)'); })()`);
		check('quick open: opens the start with its first (placeholder) line focused and all selected', selAll && (await c.eval(focusedIndex)) === 0);
		await c.shot('main_1600');

		// ---- typing, Enter, split, Backspace, arrows, Alt moves, pictures, speakers
		await c.type('Hello there. How are you?');
		let m = await c.eval(model);
		check('typing replaces the placeholder', m[0].text === 'Hello there. How are you?' && !(await c.eval(`$('rows').children[0].classList.contains('placeholder')`)));
		await c.key('Enter');
		m = await c.eval(model);
		check('Enter at the end makes a new line below, focused, with the same picture', m.length === 8 && m[1].text === '' && (await c.eval(focusedIndex)) === 1 && m[1].backgroundList === m[0].backgroundList && m[1].background === m[0].background);
		await c.type('Second half here');
		await setCaret(c, 6);
		await c.key('Enter');
		m = await c.eval(model);
		const caretAfterSplit = await c.eval(`document.activeElement.selectionStart`);
		check('Enter mid-text splits the line at the caret', m.length === 9 && m[1].text === 'Second' && m[2].text === 'half here' && (await c.eval(focusedIndex)) === 2 && caretAfterSplit === 0, JSON.stringify([m[1].text, m[2].text]));
		await setCaret(c, 'half here'.length);
		await c.key('Enter');
		check('Enter at the end of a split line adds an empty line', (await c.eval(model)).length === 10 && (await c.eval(focusedIndex)) === 3);
		await c.key('Backspace');
		m = await c.eval(model);
		const caret = await c.eval(`[document.activeElement.selectionStart, document.activeElement.value.length]`);
		check('Backspace in an empty line deletes it and goes to the end of the previous line', m.length === 9 && (await c.eval(focusedIndex)) === 2 && caret[0] === caret[1]);
		await c.key('ArrowUp');
		const up = await c.eval(focusedIndex);
		await c.key('ArrowDown');
		const down = await c.eval(focusedIndex);
		check('↑ / ↓ at the edge of a line move to the previous / next line', up === 1 && down === 2, `${up} ${down}`);
		await c.key('ArrowDown', { alt: true });
		m = await c.eval(model);
		const movedDown = m[3].text === 'half here' && (await c.eval(focusedIndex)) === 3;
		await c.key('ArrowUp', { alt: true });
		m = await c.eval(model);
		check('Alt+↓ / Alt+↑ move the line down and back up, keeping the caret in it', movedDown && m[2].text === 'half here' && (await c.eval(focusedIndex)) === 2);
		const bl = m[2].backgroundList;
		await c.key('ArrowRight', { alt: true });
		const p1 = (await c.eval(model))[2].background;
		await c.key('ArrowRight', { alt: true });
		const p2 = (await c.eval(model))[2].background;
		await c.key('ArrowLeft', { alt: true });
		m = await c.eval(model);
		check('Alt+→ / Alt+← step the picture through its list', p1 === 1 && p2 === 2 && m[2].background === 1 && m[2].backgroundList === bl, `${p1} ${p2} ${m[2].background}`);
		await c.key('1', { alt: true });
		const s1 = (await c.eval(model))[2].speaker;
		await c.key('0', { alt: true });
		const s0 = (await c.eval(model))[2].speaker;
		await c.key('2', { alt: true });
		m = await c.eval(model);
		check('Alt+1 / Alt+0 / Alt+2 set You / narration / Ashely', s1 === 0 && s0 === '' && m[2].speaker === 1, JSON.stringify([s1, s0, m[2].speaker]));
		const chipText = await c.eval(`$('rows').children[2].querySelector('.speaker').textContent`);
		check('the speaker chip shows the character name', chipText === 'Ashely', chipText);

		// ---- '/' inserts a signal, then writing carries on (↓ left the caret at the start of the
		// line, where Enter would add a line above: go to its end first)
		await setCaret(c, 'half here'.length);
		await c.key('Enter');
		await c.key('/');
		await c.waitFor(`!$('menu').hidden && document.activeElement.classList.contains('m-input')`, 3000, 'the signal picker');
		await c.type('fade_next');
		await c.shot('signal_picker_1600');
		await c.key('Enter');
		m = await c.eval(model);
		check('/ in an empty line opens the signal picker; Enter inserts the signal before the line', m[3].kind === 'signal' && m[3].value === 'fade_next' && m[4].kind === 'line' && m[4].text === '' && (await c.eval(focusedIndex)) === 4 && (await c.eval(`$('menu').hidden`)), JSON.stringify(m[3]));
		await c.type('After the fade.');

		// ---- the picture panel
		const panelList = await c.eval(`+$('listSel').value`);
		await c.click('#picGrid .cell', { index: 4 });
		m = await c.eval(model);
		check('clicking a thumbnail in the panel sets the selected line\'s picture', m[4].background === 4 && m[4].backgroundList === panelList && (await c.eval(focusedIndex)) === 4, `${m[4].backgroundList}/${m[4].background}`);
		await c.shot('panel_1600', '#panel');

		// ---- undo / redo
		await c.key('z', { ctrl: true });
		const undone = (await c.eval(model))[4];
		await c.key('z', { ctrl: true, shift: true });
		const redone = (await c.eval(model))[4];
		await c.key('z', { ctrl: true });
		await c.key('z', { ctrl: true });
		const textUndone = (await c.eval(model))[4];
		await c.key('y', { ctrl: true });
		await c.key('y', { ctrl: true });
		m = await c.eval(model);
		check('Ctrl+Z / Ctrl+Shift+Z undo and redo a picture change', undone.background === 1 && redone.background === 4, `${undone.background} ${redone.background}`);
		check('Ctrl+Z undoes a burst of typing as one step; Ctrl+Y redoes', textUndone.text === '' && m[4].text === 'After the fade.' && m[4].background === 4, JSON.stringify([textUndone.text, m[4].text, m[4].background]));
		check('the start shows as unsaved', await c.eval(`isDirty(curStart()) && $('saveState').textContent.startsWith('Unsaved')`));

		// ---- save, and the file on disk
		const expected = [
			{ kind: 'line', speaker: '', text: 'Hello there. How are you?', backgroundList: original[0].backgroundList, background: original[0].background },
			{ kind: 'line', speaker: '', text: 'Second', backgroundList: original[0].backgroundList, background: original[0].background },
			{ kind: 'line', speaker: 1, text: 'half here', backgroundList: original[0].backgroundList, background: 1 },
			{ kind: 'signal', value: 'fade_next' },
			{ kind: 'line', speaker: 1, text: 'After the fade.', backgroundList: panelList, background: 4 },
			...strip(original.slice(1)),
		];
		check('the page holds the expected chain before saving', same(strip(await c.eval(model)), expected), JSON.stringify(strip(await c.eval(model))));
		await c.key('s', { ctrl: true });
		await c.waitFor(`!S.saving && $('saveState').textContent === 'Saved'`, 10000, 'the save');
		const disk = chainOnDisk(project, WIN, 'WIN_X3_UNDER__TOP_OFF');
		check('Ctrl+S: the file on disk has exactly the expected chain', disk.editable && same(strip(disk.items), expected), JSON.stringify(strip(disk.items)).slice(0, 400));
		check('saving reuses node ids of kept lines and gives the new ones ids', disk.items[0].id === original[0].id && same(disk.items.slice(5).map(i => i.id), original.slice(1).map(i => i.id)) && same((await c.eval(model)).map(i => i.id), disk.items.map(i => i.id)));
		check('after saving nothing is unsaved', await c.eval(`!anyDirty()`));

		// ---- play mode. Play opens the play tab (window.open is caught here; the tab itself is
		// tested further down); the play view is the same in this page, driven directly.
		await c.eval(`(window.__opened = [], window.open = (u, n) => { window.__opened.push([u, n]); return {}; }, true)`);
		await c.eval(`(focusItem(curStart().items[0].uid, 'end'), true)`);
		await c.key('F5');
		const [f5Url, f5Name] = await c.eval(`window.__opened[window.__opened.length - 1] || []`);
		const f5 = new URL(f5Url || '/', url).searchParams;
		check('F5 opens the play tab: one named tab for every Play, at the start and the selected line', f5Name === 'dialogueEditorPlay' && f5.get('play') === '1' && f5.get('key') === (await c.eval(`S.key`))
			&& f5.get('file') === (await c.eval(`S.path`)) && f5.get('at') === (await c.eval(`curStart().items[0].uid`)) && f5.get('tab') === (await c.eval(`TAB_ID`)) && (await c.eval(`$('play').hidden`)), f5Url);
		await c.eval(`(playFromSelection(), true)`);
		await c.waitFor(`!$('play').hidden`, 3000, 'play mode');
		const t0 = await c.eval(`$('playFrame').querySelector('.g-text').textContent`);
		await c.shot('play_1600');
		await c.key('ArrowRight');
		const t1 = await c.eval(`$('playFrame').querySelector('.g-text').textContent`);
		await c.key(' ');
		await c.key('ArrowRight');
		await sleep(900);	// the fade_next fade runs through black first
		const t3 = await c.eval(`$('playFrame').querySelector('.g-text').textContent`);
		const flashed = await c.eval(`[...$('playSignals').children].map(n => n.textContent).join(',')`);
		await c.shot('play_after_fade_1600');
		await c.key('ArrowLeft');
		const back = await c.eval(`$('playFrame').querySelector('.g-text').textContent`);
		await c.key('ArrowRight');
		await sleep(50);
		await c.key('Escape');
		await sleep(100);
		check('play: it opens at the selected line, → / Space step, ← goes back', t0 === 'Hello there. How are you?' && t1 === 'Second' && t3 === 'After the fade.' && back === 'half here', JSON.stringify([t0, t1, t3, back]));
		check('play: a signal on the way flashes its name', flashed.includes('fade_next'), flashed);
		check('play: Esc returns to the line you got to', (await c.eval(`$('play').hidden`)) && (await c.eval(focusedIndex)) === 4);

		// ---- global search, into a read-only start
		await c.key('k', { ctrl: true });
		await c.type('enough admiring');
		await c.waitFor(`!$('searchPop').hidden && SR.results.length > 0`, 5000, 'search results');
		// The frozen intro3 has it; a live file might one day too, so pick that hit by where it is.
		const hit = await c.eval(`(() => { const i = SR.results.findIndex(r => r.path === ${JSON.stringify(INTRO3)} && r.key === 'START' && r.field === 'text'); SR.active = Math.max(0, i); markSearch(); return i; })()`);
		check('search: Ctrl+K finds a line in another file', hit >= 0, String(hit));
		await c.shot('search_1600');
		await c.key('Enter');
		await c.waitFor(`S.path === ${JSON.stringify(INTRO3)} && S.key === 'START'`, 8000, 'the search result to open');
		await sleep(100);
		const ro = await c.eval(`({ banner: !!document.querySelector('.ro-banner'), text: document.querySelector('.ro-banner')?.textContent, textareas: $('rows').querySelectorAll('textarea').length, rows: $('rows').children.length, sel: curStart().items.findIndex(i => i.uid === curStart().sel), flashed: !!document.querySelector('.item.flash'), selText: (curStart().items.find(i => i.uid === curStart().sel) || {}).text })`);
		check('search: Enter opens the result\'s start and flashes the line', ro.sel >= 0 && /enough admiring/.test(ro.selText) && ro.flashed, JSON.stringify({ sel: ro.sel, flashed: ro.flashed }));
		check('read-only start (choices): a lock banner with the reason, no text boxes', ro.banner && /branches/.test(ro.text) && ro.textareas === 0 && ro.rows > 0, ro.text);
		await c.key('Escape');
		await c.key('x', { ctrl: false, text: 'x' });	// typing on a read-only start changes nothing
		check('read-only: the model is unchanged by keys', await c.eval(`!isDirty(curStart())`));
		await c.shot('readonly_intro3_1600');
		await c.key('p', { ctrl: true });
		await c.type('BOA_FINAL_STRIP');
		await sleep(60);
		await c.key('Enter');
		await c.waitFor(`S.path === ${JSON.stringify(BOA)} && S.key === 'BOA_FINAL_STRIP'`, 8000, 'the boa start');
		const boa = await c.eval(`({ text: document.querySelector('.ro-banner')?.textContent, other: [...$('rows').querySelectorAll('.item.other .ro-text')].map(n => n.textContent), textareas: $('rows').querySelectorAll('textarea').length })`);
		check('read-only start (variables): its set node shows as a summary', /sets a variable/.test(boa.text || '') && boa.other.some(t => t.startsWith('set ')) && boa.textareas === 0, JSON.stringify(boa));

		// ---- a conflict: the start changes on disk between loading and saving
		await c.key('p', { ctrl: true });
		await c.type('WIN_S2_WALK');
		await sleep(60);
		await c.key('Enter');
		await c.waitFor(`S.key === 'WIN_S2_WALK'`, 8000, 'WIN_S2_WALK');
		await c.type('My edit');
		const before = await (await fetch(url + 'api/file?path=' + encodeURIComponent(WIN))).json();
		const s2 = before.starts.find(s => s.key === 'WIN_S2_WALK');
		const items = s2.items.map((i, n) => n === 0 ? { ...i, text: 'Disk edit' } : i);
		const direct = await fetch(url + 'api/save', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ path: WIN, changes: [{ op: 'chain', key: 'WIN_S2_WALK', base: s2.fingerprint, items }] }) });
		check('conflict setup: another save changed WIN_S2_WALK on disk', direct.status === 200, String(direct.status));
		expectedErrors++;
		await c.key('s', { ctrl: true });
		await c.waitFor(`!S.saving && !!document.querySelector('.notice.error')`, 8000, 'the conflict notice');
		const conflict = await c.eval(`({ notice: document.querySelector('.notice.error .n-text').textContent, banner: document.querySelector('.conflict-banner')?.textContent || '', dirty: isDirty(curStart()), state: $('saveState').textContent })`);
		check('conflict: the 409 names the start and why, and the edit is kept', /WIN_S2_WALK/.test(conflict.notice) && /changed on disk/.test(conflict.notice) && conflict.dirty && /WIN_S2_WALK/.test(conflict.state), JSON.stringify(conflict));
		await c.shot('conflict_1600');
		const diskAfter409 = chainOnDisk(project, WIN, 'WIN_S2_WALK').items[0].text;
		check('conflict: nothing was written by the refused save', diskAfter409 === 'Disk edit', diskAfter409);
		const reloadButton = await c.eval(`[...document.querySelectorAll('.notice.error button')].findIndex(b => /Reload/.test(b.textContent))`);
		await c.click('.notice.error button', { index: reloadButton });
		await c.waitFor(`curStart().items[0].text === 'Disk edit' && !isDirty(curStart())`, 8000, 'the reloaded start');
		check('conflict: "Reload (drop my edits)" shows the disk version', (await c.eval(`!document.querySelector('.notice.error') && !document.querySelector('.conflict-banner')`)));

		// ---- the other way out of a conflict: keep mine, replacing the disk version
		await c.eval(`(focusItem(curStart().items[0].uid, 'end'), true)`);
		await c.type(' and mine');
		const again = await (await fetch(url + 'api/file?path=' + encodeURIComponent(WIN))).json();
		const s2b = again.starts.find(s => s.key === 'WIN_S2_WALK');
		const placeholder2 = s2b.items[1].text;
		const direct2 = await fetch(url + 'api/save', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ path: WIN, changes: [{ op: 'chain', key: 'WIN_S2_WALK', base: s2b.fingerprint, items: s2b.items.map((i, n) => n === 1 ? { ...i, text: 'Disk two' } : i) }] }) });
		expectedErrors++;
		await c.key('s', { ctrl: true });
		await c.waitFor(`!S.saving && !!document.querySelector('.conflict-banner')`, 8000, 'the second conflict');
		const mineButton = await c.eval(`[...document.querySelectorAll('.conflict-banner button')].findIndex(b => /mine/.test(b.textContent))`);
		await c.click('.conflict-banner button', { index: mineButton });
		await c.waitFor(`!curStart().conflict && isDirty(curStart())`, 8000, 'keeping mine');
		await c.key('s', { ctrl: true });
		await c.waitFor(`!S.saving && $('saveState').textContent === 'Saved'`, 8000, 'the save of mine');
		const mine = chainOnDisk(project, WIN, 'WIN_S2_WALK').items;
		check("conflict: 'Save mine over it' then Ctrl+S writes this page's version", direct2.status === 200 && mine[0].text === 'Disk edit and mine' && mine[1].text === placeholder2, JSON.stringify([mine[0].text, mine[1].text]));

		// ---- a new start, saved, then deleted
		await c.click('#newStartBtn');
		await c.type('test new start');
		await c.key('Enter');
		await c.waitFor(`S.key === 'TEST_NEW_START' && curStart().items.length === 1`, 5000, 'the new start');
		check('+ New start: makes the key (upper case, _ for spaces) with one line to write in', (await c.eval(focusedIndex)) === 0);
		await c.type('A brand new line.');
		await c.key('s', { ctrl: true });
		await c.waitFor(`!S.saving && $('saveState').textContent === 'Saved'`, 8000, 'saving the new start');
		const added = chainOnDisk(project, WIN, 'TEST_NEW_START');
		check('the new start is in the file on disk', added.editable && added.items.length === 1 && added.items[0].text === 'A brand new line.', JSON.stringify(added.items));
		await c.click('.head-actions .danger');
		await c.waitFor(`!$('dialog').hidden`, 3000, 'the delete question');
		await c.click('#dActions .primary');
		await c.waitFor(`curStart() && curStart().deleted`, 3000, 'the start to be marked deleted');
		await c.key('s', { ctrl: true });
		await c.waitFor(`!S.saving && $('saveState').textContent === 'Saved' && !S.docs.get(${JSON.stringify(WIN)}).starts.has('TEST_NEW_START')`, 8000, 'saving the delete');
		const keysAfter = startKeysOnDisk(project, WIN);
		check('Delete start + Ctrl+S takes it out of the file; the others stay', !keysAfter.includes('TEST_NEW_START') && keysAfter.length === 31, String(keysAfter.length));

		// ---- joining lines (Backspace at the start, Delete at the end), each undone
		await c.eval(`openStart(${JSON.stringify(WIN)}, 'WIN_S3_SHORTS').then(() => true)`);
		const s3 = await c.eval(model);
		await c.eval(`(focusItem(curStart().items[1].uid, 0), true)`);
		await c.key('Backspace');
		let j = await c.eval(model);
		const joinCaret = await c.eval(`document.activeElement.selectionStart`);
		const joined = j.length === s3.length - 1 && j[0].text === s3[0].text + ' ' + s3[1].text && (await c.eval(focusedIndex)) === 0 && joinCaret === s3[0].text.length + 1;
		await c.key('z', { ctrl: true });
		const unjoined = same(await c.eval(model), s3);
		await c.eval(`(focusItem(curStart().items[0].uid, curStart().items[0].text.length), true)`);
		await c.key('Delete');
		j = await c.eval(model);
		const pulled = j.length === s3.length - 1 && j[0].text === s3[0].text + ' ' + s3[1].text;
		await c.key('z', { ctrl: true });
		check("Backspace at a line's start joins it onto the line above; Delete at the end pulls the next one up; Ctrl+Z undoes both", joined && unjoined && pulled && same(await c.eval(model), s3));
		check('undoing back to the start as loaded leaves it unsaved-free', await c.eval(`!isDirty(curStart())`));

		// ---- the file picker
		await c.key('o', { ctrl: true });
		await c.waitFor(`!$('filePop').hidden`, 3000, 'the file picker');
		await c.type('intro3');
		await sleep(50);
		await c.shot('file_picker_1600');
		await c.key('Enter');
		await c.waitFor(`S.path === ${JSON.stringify(INTRO3)}`, 8000, 'intro3 to open');
		check('Ctrl+O: the file picker filters and opens a file', await c.eval(`$('filePop').hidden && $('fileName').textContent === displayName(S.filesByPath.get(${JSON.stringify(INTRO3)}))`), await c.eval(`$('fileName').textContent`));

		// ---- drafts survive a reload
		await c.key('p', { ctrl: true });
		await c.type('WIN_S1_TOP');
		await sleep(60);
		await c.key('Enter');
		await c.waitFor(`S.key === 'WIN_S1_TOP'`, 8000, 'WIN_S1_TOP');
		await c.type('Draft text that must survive');
		await sleep(700);
		await c.page('Page.reload');
		await sleep(500);
		await c.waitFor(`typeof S !== 'undefined' && S.loaded && !!document.querySelector('.notice[data-id="drafts"]')`, 15000, 'the drafts notice');
		const draftNotice = await c.eval(`document.querySelector('.notice[data-id="drafts"] .n-text').textContent`);
		check('drafts: after a reload the unsaved edit is offered back', /WIN_S1_TOP/.test(draftNotice), draftNotice);
		await c.shot('drafts_1600');
		await c.click('.notice[data-id="drafts"] button.primary');
		await c.waitFor(`S.key === 'WIN_S1_TOP' && curStart().items[0].text === 'Draft text that must survive'`, 8000, 'the restored draft');
		check('drafts: Restore puts the edit back, unsaved', await c.eval(`isDirty(curStart()) && $('saveState').textContent.startsWith('Unsaved')`));

		// ---- a clean start that changes on disk reloads quietly; Godot open without the patch asks first
		await c.eval(`openStart(${JSON.stringify(WIN)}, 'WIN_L2_NICE', { focus: false }).then(() => true)`);
		const nice = (await (await fetch(url + 'api/file?path=' + encodeURIComponent(WIN))).json()).starts.find(s => s.key === 'WIN_L2_NICE');
		const elsewhere = await fetch(url + 'api/save', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ path: WIN, changes: [{ op: 'chain', key: 'WIN_L2_NICE', base: nice.fingerprint, items: nice.items.map((i, n) => n === 0 ? { ...i, text: 'Changed by someone else' } : i) }] }) });
		await c.eval(`checkVersions().then(() => true)`);
		await c.waitFor(`curStart().items[0].text === 'Changed by someone else'`, 5000, 'the quiet reload');
		check("a start with no edits here that changed on disk reloads quietly (the edited one is kept)", elsewhere.status === 200 && (await c.eval(`!isDirty(curStart()) && isDirty(S.docs.get(${JSON.stringify(WIN)}).starts.get('WIN_S1_TOP'))`)));
		await c.eval(`(() => { const real = window.fetch; window.__bodies = []; let once = true; window.fetch = (u, o) => { if (String(u).includes('/api/save')) { window.__bodies.push(JSON.parse(o.body)); if (once) { once = false; return Promise.resolve(new Response(JSON.stringify({ error: 'Godot is running', code: 'godot-unpatched', godotRunning: ['Godot_v4.4.1-stable_win64.exe'] }), { status: 409, headers: { 'Content-Type': 'application/json' } })); } } return real(u, o); }; return true; })()`);
		await c.key('s', { ctrl: true });
		await c.waitFor(`!$('dialog').hidden`, 5000, 'the Godot question');
		const question = await c.eval(`$('dText').textContent`);
		await c.shot('godot_question_1600');
		await c.click('#dActions .primary');
		await c.waitFor(`!S.saving && $('saveState').textContent === 'Saved'`, 8000, 'the confirmed save');
		const bodies = await c.eval(`window.__bodies.map(b => !!b.confirmGodot)`);
		check('Godot open without the addon patch: the save asks, and "Save anyway" resends with confirmGodot', /not patched/.test(question) && same(bodies, [false, true]) && chainOnDisk(project, WIN, 'WIN_S1_TOP').items[0].text === 'Draft text that must survive', JSON.stringify(bodies));

		// ---- moving around without a text box: Esc, ↓, Enter; Alt+PageDown to the next start
		await c.eval(`(focusItem(curStart().items[0].uid, 'end'), true)`);
		await c.key('Escape');
		const blurred = await c.eval(`!document.activeElement || !document.activeElement.matches('textarea')`);
		await c.key('ArrowDown');
		const selectedNow = await c.eval(`curStart().items.findIndex(i => i.uid === curStart().sel)`);
		await c.key('Enter');
		check('Esc leaves the text box; ↓ then picks the next row and Enter writes in it', blurred && selectedNow === 1 && (await c.eval(focusedIndex)) === 1);
		const keyBefore = await c.eval(`S.key`);
		await c.key('PageDown', { alt: true });
		const keyAfter = await c.eval(`S.key`);
		await c.key('PageUp', { alt: true });
		check('Alt+PageDown / Alt+PageUp step through the starts', keyBefore === 'WIN_L2_NICE' && keyAfter === 'WIN_L3_SMILE' && (await c.eval(`S.key`)) === 'WIN_L2_NICE', `${keyBefore} ${keyAfter}`);

		// ---- more editing on WIN_S4_PANTIES: duplicate, delete, a named speaker, several lines'
		// picture at once, a literal slash, typing a signal, dragging a row; then the file on disk
		await c.eval(`openStart(${JSON.stringify(WIN)}, 'WIN_S4_PANTIES').then(() => true)`);
		const p0 = await c.eval(model);
		await c.eval(`(focusItem(curStart().items[0].uid, 'end'), true)`);
		await c.type('First, written.');
		await c.key('d', { ctrl: true });
		let e1 = await c.eval(model);
		const dup = e1.length === p0.length + 1 && e1[1].text === 'First, written.' && e1[1].id === null && (await c.eval(focusedIndex)) === 1;
		await c.key('k', { ctrl: true, shift: true });
		e1 = await c.eval(model);
		check('Ctrl+D duplicates the line below; Ctrl+Shift+K deletes it', dup && e1.length === p0.length && e1[1].text === p0[1].text);
		await c.click('#rows .item:nth-child(2) .speaker');
		await c.waitFor(`!$('menu').hidden && document.activeElement.classList.contains('m-input')`, 3000, 'the speaker menu');
		await c.type('Security');
		await c.key('Enter');
		e1 = await c.eval(model);
		const named = e1[1].speaker === 'Security' && (await c.eval(`$('menu').hidden`)) && (await c.eval(focusedIndex)) === 1;
		await c.click('#rows .item:nth-child(3) .speaker');
		await c.waitFor(`!$('menu').hidden`, 3000, 'the speaker menu again');
		const offered = await c.eval(`[...$('menu').querySelectorAll('.mi .mi-main')].map(n => n.textContent)`);
		await c.shot('speaker_menu_1600');
		await c.key('ArrowUp');	// the menu opens on the current speaker (Narration); one up is Ashely
		await c.key('Enter');
		e1 = await c.eval(model);
		check('the speaker menu: a typed name sets a custom speaker, and is offered again next time', named && offered.includes('Security') && e1[2].speaker === 1, JSON.stringify({ offered, s2: e1[2].speaker }));
		await c.click('#rows .item:nth-child(1) .thumb');
		await c.click('#rows .item:nth-child(3) .num', { shift: true });
		const multi = await c.eval(`S.multi.size`);
		await c.click('#picGrid .cell', { index: 5 });
		e1 = await c.eval(model);
		check('Shift+click selects a run of lines; a picture click sets all of them', multi === 3 && e1.slice(0, 3).every(i => i.background === 5) && e1[3].background === p0[3].background, `${multi} ${e1.slice(0, 4).map(i => i.background)}`);
		// Lines 1-3 now all hold picture 6 (index 5). A click on line 1's changes only line 1, and
		// the toast says lines 2-3 kept the old one; Shift+click changes the whole run.
		await c.key('Escape');
		await c.eval(`(S.multi.clear(), focusItem(curStart().items[0].uid, 'end'), true)`);
		const runEnd = e1.slice(3).findIndex(i => i.kind !== 'line' || i.background !== 5);
		await c.click('#picGrid .cell', { index: 6 });
		const single = await c.eval(model);
		const singleToast = await c.eval(`$('toast').textContent`);
		check('a picture click changes only the selected line; the toast names the lines still on the old picture', single[0].background === 6 && single[1].background === 5 && single[2].background === 5 && /^Lines 2–3 still show the old picture/.test(singleToast), `${single.slice(0, 4).map(i => i.background)} "${singleToast}"`);
		await c.key('z', { ctrl: true });
		await c.eval(`(S.multi.clear(), focusItem(curStart().items[0].uid, 'end'), true)`);
		await c.click('#picGrid .cell', { index: 6, shift: true });
		const runSet = await c.eval(model);
		const runToast = await c.eval(`$('toast').textContent`);
		const runLen = 3 + (runEnd < 0 ? e1.length - 3 : runEnd);
		check('Shift+click on a picture replaces it on the lines after it that showed the same picture, and no further', runSet.slice(0, runLen).every(i => i.background === 6) && runSet.slice(runLen).every((i, k) => i.background === e1[runLen + k].background) && /^Also set on lines 2–/.test(runToast), `${runSet.slice(0, 5).map(i => i.background)} "${runToast}"`);
		await c.key('z', { ctrl: true });
		e1 = await c.eval(model);
		check('Ctrl+Z undoes the whole run in one step', e1.slice(0, 3).every(i => i.background === 5) && e1[3].background === p0[3].background, `${e1.slice(0, 4).map(i => i.background)}`);
		// The Replace button: on, a plain click (and Alt+→) replaces the run; Shift+click only the line.
		const lineZero = `(S.multi.clear(), focusItem(curStart().items[0].uid, 'end'), true)`;
		const pressed = `[$('replaceBtn').classList.contains('on'), $('replaceBtn').getAttribute('aria-pressed'), !!(load(PREFS_KEY) || {}).replaceRun]`;
		await c.click('#replaceBtn');
		const onState = await c.eval(pressed);
		await c.eval(lineZero);
		await c.click('#picGrid .cell', { index: 6 });
		const onClick = await c.eval(model);
		const onNote = await c.eval(`$('pickNote').textContent`);
		await c.key('z', { ctrl: true });
		await c.eval(lineZero);
		await c.click('#picGrid .cell', { index: 6, shift: true });
		const onShift = await c.eval(model);
		const onShiftToast = await c.eval(`$('toast').textContent`);
		await c.key('z', { ctrl: true });
		await c.eval(lineZero);
		await c.key('ArrowRight', { alt: true });
		const onStep = await c.eval(model);
		await c.key('z', { ctrl: true });
		await c.click('#replaceBtn');
		const offState = await c.eval(pressed);
		e1 = await c.eval(model);
		check('Replace button: on, a picture click and Alt+→ replace the run; Shift+click changes only the line; it is remembered, and off again',
			same(onState, [true, 'true', true]) && /^Replace is on/.test(onNote)
			&& onClick.slice(0, runLen).every(i => i.background === 6) && onClick.slice(runLen).every((i, k) => i.background === e1[runLen + k].background)
			&& onShift[0].background === 6 && onShift[1].background === 5 && onShift[2].background === 5 && /Shift\+click changed only this line/.test(onShiftToast)
			&& onStep.slice(0, runLen).every(i => i.background === 6)
			&& same(offState, [false, 'false', false]) && e1.slice(0, 3).every(i => i.background === 5),
			JSON.stringify({ onState, onNote, click: onClick.slice(0, 5).map(i => i.background), shift: onShift.slice(0, 4).map(i => i.background), onShiftToast, step: onStep.slice(0, 4).map(i => i.background), offState }));

		// ---- the Fade button: a picture change gets a fade_next before its line, in the same undo
		// step; not on the first line; not where a fade already waits; taken out again when its line
		// stops changing picture, unless written by hand. Played on a made-up start of four lines,
		// A–D all on picture 2, then undone back to the real one.
		const beforeFade = await c.eval(model);
		await c.click('#fadeBtn');
		const fadeOn = await c.eval(`[S.autoFade, $('fadeBtn').classList.contains('on'), (load(PREFS_KEY) || {}).autoFade, $('pickNote').textContent]`);
		await c.eval(`(() => { const st = curStart(); const list = cur().view.lists.find(l => l.pictures.length >= 5);
			edit(st, items => items.splice(0, items.length, ...['A', 'B', 'C', 'D'].map(text => newLine({ text, backgroundList: list.index, background: 1 })))); return true; })()`);
		const sig = `curStart().items.map(i => i.kind === 'line' ? i.text + ':' + i.background : '[' + i.value + ']').join(' ')`;
		const pickLine = async t => { await c.eval(`(S.multi.clear(), S.panelList = null, focusItem(curStart().items.find(i => i.text === '${t}').uid, 'end'), true)`); await sleep(120); };
		const fades = {};
		await pickLine('B');
		await c.click('#picGrid .cell', { index: 3 });
		fades.picked = await c.eval(sig);	// B changes, and C now changes back
		await c.click('#keepBtn');
		fades.kept = await c.eval(sig);	// B keeps A's picture: no change at B or C, so both fades go
		await c.key('z', { ctrl: true });
		fades.keptUndone = await c.eval(sig);
		await c.key('z', { ctrl: true });
		fades.undone = await c.eval(sig);	// the picture and its fades in one step
		await c.eval(`(insertSignal(1, 'fade_next_slow'), true)`);
		await pickLine('B');
		await c.click('#picGrid .cell', { index: 3 });
		fades.waiting = await c.eval(sig);	// the slow fade already waits for B
		await c.click('#keepBtn');
		fades.handKept = await c.eval(sig);	// the hand-written slow fade stays
		for (let i = 0; i < 3; i++) await c.key('z', { ctrl: true });
		await pickLine('A');
		await c.click('#picGrid .cell', { index: 3 });
		fades.first = await c.eval(sig);	// none before the first line; B now changes
		await c.key('z', { ctrl: true });
		await c.click('#fadeBtn');
		await pickLine('B');
		await c.click('#picGrid .cell', { index: 3 });
		fades.off = await c.eval(sig);
		const fadeOff = await c.eval(`[S.autoFade, $('fadeBtn').classList.contains('on'), (load(PREFS_KEY) || {}).autoFade]`);
		await c.key('z', { ctrl: true });
		await c.key('z', { ctrl: true });
		const afterFade = await c.eval(model);
		check('Fade: on by default; a picture change gets a fade_next before its line and the next line\'s, in one undo step; not on the first line, nor where a fade waits; its fades go when the change does, hand-written ones stay; off, none; remembered',
			same(fadeDefault, [true, true, 'true']) && same(fadeOn.slice(0, 3), [true, true, true]) && /Fade is on/.test(fadeOn[3])
			&& fades.picked === 'A:1 [fade_next] B:3 [fade_next] C:1 D:1' && fades.kept === 'A:1 B:-1 C:1 D:1'
			&& fades.keptUndone === fades.picked && fades.undone === 'A:1 B:1 C:1 D:1'
			&& fades.waiting === 'A:1 [fade_next_slow] B:3 [fade_next] C:1 D:1' && fades.handKept === 'A:1 [fade_next_slow] B:-1 C:1 D:1'
			&& fades.first === 'A:3 [fade_next] B:1 C:1 D:1' && fades.off === 'A:1 B:3 C:1 D:1' && same(fadeOff, [false, false, false])
			&& same(afterFade, beforeFade),
			JSON.stringify({ fadeDefault, fadeOn, fades, fadeOff, restored: same(afterFade, beforeFade) }));

		// ---- Done: the button marks the open start (a ✓ in the start list and Ctrl+P, a count), the
		// server keeps it; the filter lists the done or the not-done starts; a second click unmarks.
		const doneKey = await c.eval(`S.key`);
		const doneState = `(() => { const row = [...$('startList').querySelectorAll('.start')].find(n => n.dataset.key === S.key); return { btn: $('doneBtn').textContent, on: $('doneBtn').classList.contains('on'), mark: !!(row && row.querySelector('.done-mark')), count: $('startsCount').textContent, rows: $('startList').querySelectorAll('.start').length }; })()`;
		const startKeys = `[...$('startList').querySelectorAll('.start')].map(n => n.dataset.key)`;
		const showStarts = which => c.eval(`($('doneFilter').value = '${which}', $('doneFilter').dispatchEvent(new Event('change')), true)`);
		const notDone = await c.eval(doneState);
		await c.click('#doneBtn');
		await c.waitFor(`isDone(S.path, S.key) && S.done[S.path][S.key] !== 'just now'`, 3000, 'the done mark saved');
		await sleep(100);
		const marked = await c.eval(doneState);
		const doneOnServer = await c.eval(`fetch('/api/done').then(r => r.json()).then(b => !!(b.done[S.path] || {})[S.key])`);
		await showStarts('done');
		const onlyDone = await c.eval(startKeys);
		await showStarts('todo');
		const notDoneKeys = await c.eval(startKeys);
		const rememberedFilter = await c.eval(`(load(PREFS_KEY) || {}).doneFilter`);
		await showStarts('all');
		await c.key('p', { ctrl: true });
		await c.waitFor(`!$('quick').hidden`);
		await c.type(doneKey.toLowerCase());
		await sleep(100);
		const quickMark = await c.eval(`!!$('quickList').querySelector('.qrow.active .done-mark')`);
		await c.key('Escape');
		await c.click('#doneBtn');
		await c.waitFor(`!isDone(S.path, S.key)`, 3000, 'the start unmarked');
		await sleep(100);
		const unmarked = await c.eval(doneState);
		const doneAfter = await c.eval(`fetch('/api/done').then(r => r.json()).then(b => b.done)`);
		check('Done: the button marks the open start (✓ in the start list and Ctrl+P, a count, kept by the server); the filter lists the done or the not-done starts; a second click unmarks',
			notDone.btn === 'Mark done' && !notDone.on && !notDone.mark && !/done/.test(notDone.count)
			&& marked.btn === 'Done' && marked.on && marked.mark && /· 1 done$/.test(marked.count) && doneOnServer
			&& same(onlyDone, [doneKey]) && notDoneKeys.length === notDone.rows - 1 && !notDoneKeys.includes(doneKey) && rememberedFilter === 'todo'
			&& quickMark && unmarked.btn === 'Mark done' && !unmarked.on && !unmarked.mark && same(doneAfter, {}),
			JSON.stringify({ notDone, marked, doneOnServer, onlyDone, notDoneKeys: notDoneKeys.length, rememberedFilter, quickMark, unmarked, doneAfter }));

		// ---- Match pictures: every situation a match starts in, by the score and what she has on; a
		// pick saves at once (Shift+click sets several), the picker follows the match's outfit, Delete clears.
		await c.click('#matchesBtn');
		await c.waitFor(`!$('matches').hidden && !!MX.doc && $('mxGrids').querySelectorAll('.mx-cell').length > 0`, 15000, 'the match pictures');
		const mx = () => c.eval(`({ cells: $('mxGrids').querySelectorAll('.mx-cell').length, count: $('mxCount').textContent, sel: [...MX.sel], list: $('mxList').value, pics: $('mxPics').querySelectorAll('.mx-pic').length, picks: MX.picks })`);
		const mx0 = await mx();
		await c.shot('matches_1600');
		await c.click('#mxPics .mx-pic', { index: 2 });
		await c.waitFor(`!!MX.picks.FIRST`, 3000, 'the first hand picked');
		const mx1 = await mx();
		await c.click('.mx-cell[data-id="DRESSED_0_0"]');
		await c.click('.mx-cell[data-id="DRESSED_0_1"]', { shift: true });
		await c.click('#mxPics .mx-pic', { index: 3 });
		await c.waitFor(`!!MX.picks.DRESSED_0_1`, 3000, 'two matches picked');
		const mx2 = await mx();
		await c.click('.mx-cell[data-id="TOP_OFF_1_0"]');
		const mx3 = await mx();
		await c.click('.mx-cell[data-id="DRESSED_0_0"]');
		await c.key('Delete');
		await c.waitFor(`!MX.picks.DRESSED_0_0`, 3000, 'a pick cleared');
		await c.key('ArrowRight');
		const mx4 = await mx();
		const mxServer = await c.eval(`fetch('/api/matches').then(r => r.json()).then(b => b.picks)`);
		await c.key('Escape');
		const mxClosed = await c.eval(`$('matches').hidden`);
		check('Match pictures: 33 situations by score and outfit; a pick saves at once, Shift+click sets several, the picker follows the outfit, Delete clears, ← → move, Esc closes',
			mx0.cells === 33 && mx0.count === '0 of 33 set' && same(mx0.sel, ['FIRST']) && mx0.list === 'TABLE__DRESSED' && mx0.pics > 3
			&& mx1.picks.FIRST && mx1.picks.FIRST.list === 'TABLE__DRESSED' && mx1.picks.FIRST.picture === 'TABLE__DRESSED_03' && mx1.count === '1 of 33 set'
			&& same(mx2.sel, ['DRESSED_0_0', 'DRESSED_0_1']) && mx2.picks.DRESSED_0_0?.picture === 'TABLE__DRESSED_04' && mx2.picks.DRESSED_0_1?.picture === 'TABLE__DRESSED_04' && mx2.count === '3 of 33 set'
			&& mx3.list === 'TABLE__TOP_OFF' && same(mx4.sel, ['DRESSED_0_1']) && !mx4.picks.DRESSED_0_0
			&& same(Object.keys(mxServer).sort(), ['DRESSED_0_1', 'FIRST']) && mxClosed,
			JSON.stringify({ mx0: { ...mx0, picks: undefined }, mx1: mx1.picks, mx2: { sel: mx2.sel, picks: mx2.picks, count: mx2.count }, mx3: mx3.list, mx4: { sel: mx4.sel, picks: mx4.picks }, mxServer, mxClosed }));

		// ---- Gallery: every picture of the file's lists on one page, with the lines set to each
		// (in every file naming the same lists); the filter, the big view, Use on the selected line,
		// a jump to a line showing a picture, and the gallery in a tab of its own.
		const gKey = await c.eval(`S.key`);
		const gBefore = await c.eval(model);
		await c.eval(`(focusItem(curStart().items[1].uid, 'end'), true)`);
		await c.key('g', { alt: true });
		await c.waitFor(`!$('gallery').hidden && G.ready`, 15000, 'the gallery');
		const gTiles = `$('gxMain').querySelectorAll('.gx-tile').length`;
		const gx0 = await c.eval(`({ tiles: ${gTiles}, pictures: galleryCount(), lists: $('gxMain').querySelectorAll('.gx-list').length, withPictures: cur().view.lists.filter(l => l.pictures.length).length,
			nav: $('gxNav').children.length, allLists: cur().view.lists.length, files: G.files.length, partial: G.partial, current: $('gxMain').querySelectorAll('.gx-tile.current').length,
			currentIs: ($('gxMain').querySelector('.gx-tile.current') || { dataset: {} }).dataset.id, lineShows: (s => s.list.index + '/' + s.pic.index)(shownPicture(cur(), curStart().items, 1)),
			counted: $('gxMain').querySelectorAll('.c-used').length, sum: $('gxSum').textContent, focus: document.activeElement.id, here: $('gxNav').querySelectorAll('.here').length, videos: $('gxMain').querySelectorAll('.gx-tile .gx-video').length,
			loops: [...$('gxMain').querySelectorAll('.gx-tile .gx-video')].filter(n => n.textContent === '▶ loop').length })`);
		await c.shot('gallery_1600');
		await c.type('x3 bj');
		const gx1 = await c.eval(`({ tiles: ${gTiles}, right: G.shown.every(e => /x3/i.test(e.list.name + e.pic.name) && /bj/i.test(e.list.name + e.pic.name)), dim: $('gxNav').querySelectorAll('.none').length })`);
		await c.key('Escape');
		const gx2 = await c.eval(`({ tiles: ${gTiles}, open: !$('gallery').hidden, q: $('gxFilter').value })`);
		await c.eval(`($('gxShow').value = 'unused', $('gxShow').dispatchEvent(new Event('change')), true)`);
		const gx3 = await c.eval(`({ tiles: ${gTiles}, none: G.shown.every(e => !e.used), said: +(/(\\d+) not used yet/.exec($('gxSum').textContent) || [])[1] })`);
		await c.eval(`($('gxShow').value = 'video', $('gxShow').dispatchEvent(new Event('change')), true)`);
		const gx3v = await c.eval(`({ tiles: ${gTiles}, all: G.shown.every(e => e.videos.length > 0), first: G.shown[0].videos[0], said: +(/(\\d+) with a video/.exec($('gxSum').textContent) || [])[1] })`);
		await c.shot('gallery_videos_1600');
		await c.eval(`($('gxShow').value = 'all', $('gxShow').dispatchEvent(new Event('change')), true)`);
		const gList = await c.eval(`cur().view.lists.find(l => l.name === 'WIN_S2_WALK').index`);
		await c.click(`.gx-tile[data-id="${gList}/2"]`);
		const gx4 = await c.eval(`({ open: !$('gxView').hidden, name: $('gxInfo').querySelector('.gx-pname').textContent, use: $('gxUse').textContent, big: $('gxBig').getAttribute('src') })`);
		await c.shot('gallery_view_1600');
		// Show in folder: the server is asked to show the picture's file (it opens nothing in a test).
		await c.click('#gxReveal');
		await c.waitFor(`/03\\.webp: shown in its folder/.test($('toast').textContent)`, 3000, 'the picture shown in its folder');
		const tail = `r => r && ({ file: r.path.replace(/\\\\/g, '/').split('/').slice(-2).join('/'), play: r.play, launched: r.launched })`;
		const gx4r = await c.eval(`revealFile(G.shown[G.at].pic.image).then(${tail})`);
		const gx4bad = await c.eval(`Promise.all(['res://project.godot', 'res://../x.png', 'res://data/nothing_here.png'].map(p => api('/api/reveal', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ path: p }) }).then(() => 200, e => e.status)))`);
		expectedErrors += 3;
		// A picture with a video: Play video and Show in folder for it too.
		await c.key('Escape');
		const gVideoAt = await c.eval(`G.shown.findIndex(e => e.videos.length > 1)`);
		await c.click(`.gx-tile[data-at="${gVideoAt}"]`);
		const gx4v = await c.eval(`({ rows: $('gxInfo').querySelectorAll('.gx-vid').length, videos: G.shown[G.at].videos.length, buttons: [...$('gxInfo').querySelector('.gx-vid').querySelectorAll('button')].map(b => b.textContent), first: G.shown[G.at].videos[0].file })`);
		await c.shot('gallery_view_video_1600');
		await c.click('.gx-vid button');
		await c.waitFor(`/^Opening .*\\.ogv/.test($('toast').textContent)`, 3000, 'the video opened');
		const gx4p = await c.eval(`revealFile(G.shown[G.at].videos[0].path, true).then(${tail})`);
		// Enter on a side button presses it (it doesn't put the picture on the line).
		await c.eval(`($('gxReveal').focus(), true)`);
		await c.key('Enter');
		const gx4e = await c.eval(`({ open: !$('gallery').hidden && !$('gxView').hidden, same: ${JSON.stringify(JSON.stringify(gBefore))} === JSON.stringify(${model}) })`);
		await c.key('Escape');
		await c.click(`.gx-tile[data-id="${gList}/2"]`);
		await c.key('ArrowRight');
		const gx5 = await c.eval(`$('gxInfo').querySelector('.gx-pname').textContent`);
		await c.key('Enter');
		const gx6 = await c.eval(`({ closed: $('gallery').hidden, line: curStart().items[1].backgroundList + '/' + curStart().items[1].background, toast: $('toast').textContent })`);
		const gFocus = await c.eval(focusedIndex);
		await c.key('z', { ctrl: true });
		const gUndone = same(await c.eval(model), gBefore);
		// A picture another start of this file is set to: its line is one click away.
		await c.click('#galleryBtn');
		await c.waitFor(`!$('gallery').hidden && G.ready`, 15000, 'the gallery again');
		const gAt = await c.eval(`G.shown.findIndex(e => e.uses.length && e.uses[0].path === S.path && e.uses[0].key !== S.key)`);
		const gUse = await c.eval(`(e => ({ id: e.id, key: e.uses[0].key, line: e.uses[0].lines[0] }))(G.shown[${gAt}])`);
		await c.click(`.gx-tile[data-at="${gAt}"]`);
		await c.click('.gx-where button');
		await c.waitFor(`$('gallery').hidden && S.key === ${JSON.stringify(gUse.key)}`, 5000, 'the jump to the line');
		const gx7 = await c.eval(`(() => { const st = curStart(), i = currentIndex(st), item = st.items[i]; return { line: lineNumbers(st).get(item.uid), shows: item.backgroundList + '/' + item.background }; })()`);
		await c.eval(`openStart(${JSON.stringify(WIN)}, ${JSON.stringify(gKey)}, { focus: false }).then(() => true)`);
		const gTab = await c.newTab(url + '?gallery=1#file=' + encodeURIComponent(WIN));
		await c.waitIn(gTab.session, `typeof G !== 'undefined' && G.ready`, 15000, 'the gallery tab');
		const gx8 = await c.evalIn(gTab.session, `({ tab: document.body.classList.contains('gallery-tab'), title: document.title, tiles: ${gTiles}, files: G.files.length,
			noUse: !document.querySelector('.gx-use') && getComputedStyle($('gxClose')).display === 'none', drafts: localStorage.getItem(DRAFTS_KEY) })`);
		await c.send('Target.closeTarget', { targetId: gTab.targetId });
		const gDrafts = await c.eval(`localStorage.getItem(DRAFTS_KEY)`);
		check('Gallery: Alt+G shows every picture of every list, opening on the selected line\'s; lines are counted across the files sharing the lists; the filter and "Not used yet" narrow it; pictures with a video are marked (loop or once) and "With a video" lists them; a picture opens big, with Show in folder for it and Play video for its videos, ← → step, Enter puts it on the selected line (one undo step); a use jumps to its line; its own tab only shows',
			gx0.tiles === gx0.pictures && gx0.tiles > 300 && gx0.lists === gx0.withPictures && gx0.nav === gx0.allLists && gx0.files >= 5 && !gx0.partial && gx0.current === 1 && gx0.currentIs === gx0.lineShows
			&& gx0.counted > 20 && /^\d+ pictures in \d+ lists · \d+ with a video · \d+ not used yet · counting the lines of \d+ files$/.test(gx0.sum) && gx0.focus === 'gxFilter' && gx0.here === 1
			&& gx1.tiles > 0 && gx1.tiles < 60 && gx1.right && gx1.dim > 30 && gx2.tiles === gx0.tiles && gx2.open && gx2.q === ''
			&& gx3.tiles > 0 && gx3.tiles < gx0.tiles && gx3.none && gx3.said === gx3.tiles
			&& gx0.videos > 50 && gx0.loops > 0 && gx0.loops < gx0.videos && gx3v.tiles === gx0.videos && gx3v.all && gx3v.said === gx0.videos && /\.ogv$/.test(gx3v.first.file) && typeof gx3v.first.loop === 'boolean'
			&& gx4.open && gx4.name === 'WIN_S2_WALK_03' && gx4.use === 'Use on line 2' && /WIN_S2_WALK/.test(decodeURIComponent(gx4.big || '')) && gx5 === 'WIN_S2_WALK_04'
			&& gx4r && gx4r.file === 'WIN_S2_WALK/03.webp' && !gx4r.play && !gx4r.launched && same(gx4bad, [400, 403, 404])
			&& gx4v.rows === gx4v.videos && gx4v.videos > 1 && same(gx4v.buttons, ['Play video', 'Show in folder']) && gx4p && gx4p.file.endsWith('/' + gx4v.first) && gx4p.play && !gx4p.launched && gx4e.open && gx4e.same
			&& gx6.closed && gx6.line === `${gList}/3` && /^WIN_S2_WALK_04 on line 2|still shows? the old picture/.test(gx6.toast) && gFocus === 1 && gUndone
			&& gx7.line === gUse.line && gx7.shows === gUse.id
			&& gx8.tab && /^Gallery · /.test(gx8.title) && gx8.tiles === gx0.tiles && gx8.files === gx0.files && gx8.noUse && gx8.drafts === gDrafts,
			JSON.stringify({ gx0, gx1, gx2, gx3, gx3v, gx4, gx4r, gx4bad, gx4v, gx4p, gx4e, gx5, gx6, gFocus, gUndone, gUse, gx7, gx8: { ...gx8, drafts: undefined }, draftsSame: gx8.drafts === gDrafts }));

		// ---- Wallpapers: turned on, the pictures with a video are picked to start from (once per picture lists);
		// a star (or W) picks or unpicks one; "Wallpapers" lists the picks; all kept in wallpaper_picks.json.
		const wallFile = path.join(tmpRoot, 'wallpaper_picks.json');	// beside --done (startServer)
		fs.rmSync(wallFile, { force: true });
		await c.click('#galleryBtn');
		await c.waitFor(`!$('gallery').hidden && G.ready && G.wall.ok === true`, 15000, 'the gallery for wallpapers');
		const wVideos = await c.eval(`cur().view.lists.reduce((n, l) => n + l.pictures.filter(p => (p.videos || []).length && p.image).length, 0)`);
		await c.click('#gxWall');
		await c.waitFor(`G.wall.on && G.wall.picks.size > 0 && $('gxMain').querySelectorAll('.gx-wall').length > 0`, 10000, 'the pre-picked wallpapers');
		const w0 = await c.eval(`({ picks: G.wall.picks.size, stars: $('gxMain').querySelectorAll('.gx-wall').length, framed: $('gxMain').querySelectorAll('.gx-tile.wall').length,
			tiles: $('gxMain').querySelectorAll('.gx-tile').length, pressed: $('gxWall').getAttribute('aria-pressed'), sum: $('gxSum').textContent,
			allVideo: G.shown.filter(e => e.wall).every(e => e.videos.length > 0) })`);
		const wAt = await c.eval(`G.shown.findIndex(e => !e.wall && e.pic.image)`);
		const wDiag = await c.eval(`(() => { const b = $('gxMain').querySelector('.gx-tile[data-at="${wAt}"] .gx-wall'); if (!b) return 'no star'; b.scrollIntoView({ block: 'center' });
			const r = b.getBoundingClientRect(), hit = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2);
			return { rect: [r.left, r.top, r.width, r.height].map(Math.round), hit: hit ? hit.tagName + '.' + hit.className : null }; })()`);
		await c.click(`.gx-tile[data-at="${wAt}"] .gx-wall`);
		try { await c.waitFor(`G.wall.picks.size === ${w0.picks + 1}`, 5000, 'a star picks a wallpaper'); }
		catch (err) { throw new Error(err.message + ' ' + JSON.stringify({ wAt, wDiag, after: await c.eval(`({ size: G.wall.picks.size, view: !$('gxView').hidden, toast: $('toast').textContent, ok: G.wall.ok })`) })); }
		const w1 = await c.eval(`({ picked: G.shown[${wAt}].wall, star: $('gxMain').querySelector('.gx-tile[data-at="${wAt}"] .gx-wall').textContent, framed: $('gxMain').querySelector('.gx-tile[data-at="${wAt}"]').classList.contains('wall') })`);
		await c.eval(`($('gxMain').querySelector('.gx-tile[data-at="${wAt}"]').focus(), true)`);
		await c.key('w');
		await c.waitFor(`G.wall.picks.size === ${w0.picks}`, 5000, 'W unpicks it');
		await c.eval(`($('gxShow').value = 'wall', $('gxShow').dispatchEvent(new Event('change')), true)`);
		const w2 = await c.eval(`({ tiles: $('gxMain').querySelectorAll('.gx-tile').length, allWall: G.shown.every(e => e.wall) })`);
		await c.shot('gallery_wallpapers_1600');
		await c.eval(`($('gxShow').value = 'all', $('gxShow').dispatchEvent(new Event('change')), true)`);
		await c.click('#gxWall');	// off, and on again: no second pre-pick
		await c.click('#gxWall');
		await c.waitFor(`G.wall.on`, 3000, 'Wallpapers on again');
		const w3 = await c.eval(`({ picks: G.wall.picks.size, seeded: Object.keys(G.wall.seeded) })`);
		const wSaved = JSON.parse(fs.readFileSync(wallFile, 'utf-8'));
		await c.click('#gxWall');
		await c.eval(`(closeGallery(), true)`);
		check('Wallpapers: turned on, every picture gets a star and the ones with a video are picked (gold frame) to start from; a star or W picks and unpicks; "Wallpapers" lists the picks; turned on again, nothing more is pre-picked; the picks are in wallpaper_picks.json',
			w0.picks === wVideos && w0.picks > 50 && w0.stars === w0.tiles && w0.framed === w0.picks && w0.pressed === 'true' && w0.allVideo && new RegExp(`★ ${w0.picks} wallpapers`).test(w0.sum)
			&& w1.picked && w1.star === '★' && w1.framed && w2.tiles === w0.picks && w2.allWall
			&& w3.picks === w0.picks && w3.seeded.length === 1 && /bgs\.tres$/.test(w3.seeded[0])
			&& Object.keys(wSaved.picks).length === w0.picks && same(Object.keys(wSaved.seeded), w3.seeded),
			JSON.stringify({ wVideos, w0, w1, w2, w3, saved: Object.keys(wSaved.picks || {}).length }));
		fs.rmSync(wallFile, { force: true });
		await c.key('Escape');
		await c.eval(`(focusItem(curStart().items[2].uid, curStart().items[2].text.length), true)`);
		await c.key('Enter');
		await c.key('/');
		await c.waitFor(`!$('menu').hidden`, 3000, 'the signal picker');
		await c.key('/');
		await c.type(' a slash line');
		e1 = await c.eval(model);
		check('typing / twice in an empty line gives a real slash', e1[3].kind === 'line' && e1[3].text === '/ a slash line' && (await c.eval(`$('menu').hidden`)), JSON.stringify(e1[3]));
		await c.click('#rows .item:nth-child(4) [data-act="signal"]');
		await c.waitFor(`!$('menu').hidden`, 3000, 'the signal picker from the button');
		await c.type('fade_next_qu');
		await c.key('Enter');
		e1 = await c.eval(model);
		const fromButton = e1[4].kind === 'signal' && e1[4].value === 'fade_next_quick' && (await c.eval(focusedIndex)) === 4;
		await c.eval(`(() => { const n = document.activeElement; n.select(); return true; })()`);
		await c.type('bogus_signal');
		await c.key('Escape');
		const bogus = await c.eval(`$('rows').children[4].querySelector('.warns').textContent`);
		await c.eval(`(() => { const n = $('rows').children[4].querySelector('input.sig'); n.focus(); n.select(); return true; })()`);
		await c.type('reposition_to');
		await c.waitFor(`!$('menu').hidden`, 3000, 'the suggestions');
		await c.key('Enter');
		e1 = await c.eval(model);
		check('a signal row: the ⚡ button inserts one; typing suggests known values; unknown ones are flagged', fromButton && /does nothing/.test(bogus) && e1[4].value === 'reposition_top', JSON.stringify({ fromButton, bogus, v: e1[4].value }));
		// drag line 1 below line 2 by its grip (Chrome hands the drag to the test, which drops it)
		await c.page('Input.setInterceptDrags', { enabled: true });
		const dragged = new Promise(resolve => c.on(msg => { if (msg.method === 'Input.dragIntercepted') resolve(msg.params.data); }));
		const grip = await c.eval(`(() => { const r = $('rows').children[0].querySelector('.grip').getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; })()`);
		const target = await c.eval(`(() => { const r = $('rows').children[1].getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.bottom - 6 }; })()`);
		await c.page('Input.dispatchMouseEvent', { type: 'mouseMoved', x: grip.x, y: grip.y });
		await c.page('Input.dispatchMouseEvent', { type: 'mousePressed', x: grip.x, y: grip.y, button: 'left', clickCount: 1 });
		await c.page('Input.dispatchMouseEvent', { type: 'mouseMoved', x: grip.x + 4, y: grip.y + 30, button: 'left' });
		await c.page('Input.dispatchMouseEvent', { type: 'mouseMoved', x: target.x, y: target.y, button: 'left' });
		const data = await Promise.race([dragged, sleep(2000).then(() => null)]);
		if (data) {
			for (const type of ['dragEnter', 'dragOver', 'drop']) await c.page('Input.dispatchDragEvent', { type, x: target.x, y: target.y, data });
		}
		await c.page('Input.dispatchMouseEvent', { type: 'mouseReleased', x: target.x, y: target.y, button: 'left', clickCount: 1 });
		await c.page('Input.setInterceptDrags', { enabled: false });
		await sleep(100);
		e1 = await c.eval(model);
		check('dragging a row by its grip moves it', !!data && e1[0].speaker === 'Security' && e1[1].text === 'First, written.', JSON.stringify(e1.slice(0, 2).map(i => i.text)));
		const wanted = strip(e1);
		await c.key('s', { ctrl: true });
		await c.waitFor(`!S.saving && $('saveState').textContent === 'Saved'`, 8000, 'saving WIN_S4_PANTIES');
		const p4 = chainOnDisk(project, WIN, 'WIN_S4_PANTIES');
		check('WIN_S4_PANTIES on disk is exactly what the page shows', p4.editable && same(strip(p4.items), wanted), JSON.stringify(strip(p4.items).slice(0, 6)));

		// ---- search: the placeholder-lines filter, limited to this file
		await c.key('Escape');
		await c.key('k', { ctrl: true });
		await c.eval(`($('search').value = '', true)`);
		await c.click('#srHere');
		await c.click('#srPlaceholder');
		await c.waitFor(`SR.placeholder && SR.here && SR.results.length > 0`, 5000, 'placeholder results');
		const ph = await c.eval(`({ n: SR.results.length, allHere: SR.results.every(r => r.path === S.path), allPlaceholder: SR.results.every(r => r.field === 'text' && r.snippet.includes('(Placeholder)')) })`);
		check('search: "Placeholder lines" + "This file only" list this file\'s unwritten lines', ph.allHere && ph.allPlaceholder && ph.n > 50, JSON.stringify(ph));
		await c.key('Escape');
		await c.key('Escape');

		// ---- the smaller screen
		await c.key('Escape');
		await c.size(1280, 800);
		await c.eval(`(openStart(${JSON.stringify(WIN)}, 'WIN_X3_UNDER__TOP_OFF', { focus: false }), true)`);
		await sleep(400);
		await c.shot('main_1280');
		const overflow = await c.eval(`document.documentElement.scrollWidth <= window.innerWidth && $('top').scrollWidth <= $('top').clientWidth + 1`);
		check('1280×800: nothing spills sideways', overflow);
		await c.key('?', { shift: true });
		await sleep(100);
		check('? opens the shortcut list', await c.eval(`!$('help').hidden`));
		await c.shot('help_1280');
		await c.key('Escape');
		await c.size(1600, 1000);

		// ---- a big start stays quick
		const big = 'res://data/game_stages/vn/anna_night/d_anna_night.tres';
		const t = Date.now();
		await c.eval(`openFile(${JSON.stringify(big)}, 'START').then(() => true)`);
		await c.waitFor(`S.path === ${JSON.stringify(big)} && $('rows').children.length > 700`, 15000, 'the 767-line start');
		const openMs = Date.now() - t;
		const typeMs = await c.eval(`(async () => { focusItem(curStart().items[300].uid, 'end'); const t = performance.now(); for (let i = 0; i < 20; i++) { document.execCommand('insertText', false, 'x'); } await new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r))); return performance.now() - t; })()`);
		await c.key('z', { ctrl: true });
		check('a 767-line start opens and types quickly', openMs < 4000 && typeMs < 1500, `open ${openMs} ms, 20 keystrokes ${Math.round(typeMs)} ms`);
		await c.shot('big_start_1600');

		// ---- find in this start (Ctrl+F): the browser's own find can't see into the line boxes.
		// The frozen anna_night START has "shower" 6 times, intro3 (read-only) "enough" twice.
		await c.eval(`(focusItem(curStart().items[5].uid, 'end'), true)`);
		await c.key('f', { ctrl: true });
		const findT = Date.now();
		await c.type('shower');
		await c.waitFor(`F.q === 'shower' && F.hits.length > 0`, 4000, 'the find to run');
		const findMs = Date.now() - findT;
		const found = await c.eval(`({ focus: document.activeElement.id, n: F.hits.length, count: $('findCount').textContent, marks: $('rows').querySelectorAll('.find-back mark').length, cur: $('rows').querySelectorAll('mark.cur').length,
			selIsHit: curStart().sel === F.hits[F.at].uid, badge: document.querySelector('.start.open .find-n')?.textContent, back: (() => { const b = document.querySelector('.find-back'); const t = b && b.parentNode.querySelector('textarea'); return b && t ? [b.textContent === t.value, Math.abs(b.getBoundingClientRect().left - t.getBoundingClientRect().left) < 1, Math.abs(b.getBoundingClientRect().width - t.getBoundingClientRect().width) < 1] : null; })() })`);
		check('find: Ctrl+F opens the bar; typing marks every match in the start and goes to the first', found.focus === 'findInput' && found.n === 6 && found.count === '1 of 6' && found.marks === 6 && found.cur === 1 && found.selIsHit && found.badge === '6' && found.back.every(Boolean), JSON.stringify({ ...found, findMs }));
		await c.shot('find_1600');
		const visible = `(() => { const r = rowCache.get(F.hits[F.at].uid).getBoundingClientRect(), p = $('scriptPane').getBoundingClientRect(); return r.top >= p.top + $('keyBar').offsetHeight - 1 && r.bottom <= p.bottom; })()`;
		await c.key('Enter');
		await c.key('Enter');
		const stepped = await c.eval(`({ at: F.at, count: $('findCount').textContent, selIsHit: curStart().sel === F.hits[F.at].uid, visible: ${visible} })`);
		await c.key('Enter', { shift: true });
		const stepBack = await c.eval(`({ at: F.at, count: $('findCount').textContent })`);
		check('find: Enter steps to the next match (scrolled into view, its line selected), Shift+Enter back', stepped.at === 2 && stepped.count === '3 of 6' && stepped.selIsHit && stepped.visible && stepBack.at === 1 && stepBack.count === '2 of 6', JSON.stringify({ stepped, stepBack }));
		await c.click('#findOnly');
		await sleep(100);
		const only = await c.eval(`({ hidden: $('rows').querySelectorAll('.item.find-out').length, items: curStart().items.length, shown: [...$('rows').children].filter(r => r.offsetHeight > 0).length, on: $('findOnly').classList.contains('on'), visible: ${visible} })`);
		check('find: "Only matching lines" hides every other line', only.on && only.shown === 6 && only.hidden === only.items - 6 && only.visible, JSON.stringify(only));
		await c.eval(`(focusItem(F.hits[F.at].uid, 'end'), true)`);
		await c.key('ArrowDown');
		const arrowed = await c.eval(`({ next: curStart().sel === F.hits[F.at + 1].uid })`);
		await c.eval(`($('findInput').focus(), $('findInput').select(), true)`);
		await c.type('showerzz');
		await sleep(80);
		const none = await c.eval(`({ count: $('findCount').textContent, hidden: $('rows').querySelectorAll('.item.find-out').length, marks: $('rows').querySelectorAll('mark').length })`);
		check('find: ↓ from a match goes to the next one shown; nothing found hides nothing', arrowed.next && none.count === 'No match' && none.hidden === 0 && none.marks === 0, JSON.stringify({ arrowed, none }));
		await c.key('Backspace');
		await c.key('Backspace');
		await c.key('Escape');
		const closed = await c.eval(`(() => { const f = document.activeElement; return { open: F.open, bar: $('findBar').hidden, hidden: $('rows').querySelectorAll('.item.find-out').length, marks: $('rows').querySelectorAll('mark, .find-back').length, tag: f.tagName, picked: f.value && f.value.slice(f.selectionStart, f.selectionEnd) }; })()`);
		check('find: Esc closes it, every line shows again and the caret holds the match', !closed.open && closed.bar && closed.hidden === 0 && closed.marks === 0 && closed.tag === 'TEXTAREA' && closed.picked.toLowerCase() === 'shower', JSON.stringify(closed));
		await c.eval(`(() => { $('findInput').value = 'zz'; const f = document.activeElement; const at = f.value.indexOf(' '); f.setSelectionRange(0, at); return true; })()`);
		const word = await c.eval(`(() => { const f = document.activeElement; return f.value.slice(f.selectionStart, f.selectionEnd); })()`);
		await c.key('f', { ctrl: true });
		const picked = await c.eval(`({ q: F.q, n: F.hits.length })`);
		check('find: Ctrl+F with words selected in a line finds those', picked.q === word && picked.n > 0, JSON.stringify({ word, picked }));
		await c.key('Escape');
		await c.eval(`openStart(${JSON.stringify(INTRO3)}, 'START', { focus: false }).then(() => true)`);
		await c.key('f', { ctrl: true });
		await c.type('enough');
		await c.waitFor(`F.q === 'enough'`, 4000, 'the find in intro3');
		const roFind = await c.eval(`({ ro: curStart().readOnly, n: F.hits.length, marks: [...$('rows').querySelectorAll('.ro-text mark')].map(m => m.textContent) })`);
		await c.key('Escape');
		const roClosed = await c.eval(`[...$('rows').querySelectorAll('.ro-text')].every(n => !n.children.length) && curStart().items.every(i => i.kind !== 'line' || rowCache.get(i.uid).querySelector('.ro-text').textContent === i.text)`);
		check('find: in a read-only start the matches are marked in its text, and the text is whole again after', roFind.ro && roFind.n === 2 && roFind.marks.length === 2 && roFind.marks.every(m => m.toLowerCase() === 'enough') && roClosed, JSON.stringify({ roFind, roClosed }));
		await c.eval(`(setFindOnly(false), true)`);

		// ================================================================ after the review: one step per fix
		{	// a block of its own: these names are its own
		const LOSE = 'res://data/game_stages/vn/ashely2_lose/d_ashely2_lose.tres';
		const open = async (file, key) => { await c.eval(`openStart(${JSON.stringify(file)}, ${JSON.stringify(key)}).then(() => true)`); await sleep(60); };
		const apiFile = async file => (await fetch(url + 'api/file?path=' + encodeURIComponent(file))).json();
		const apiSave = async (file, changes) => { const r = await fetch(url + 'api/save', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ path: file, changes }) }); return [r.status, await r.json()]; };
		const editOnDisk = async (file, key, text, n = 0) => {
			const s = (await apiFile(file)).starts.find(x => x.key === key);
			return apiSave(file, [{ op: 'chain', key, base: s.fingerprint, items: s.items.map((i, k) => k === n ? { ...i, text } : i) }]);
		};
		const stored = () => c.eval(`localStorage.getItem(DRAFTS_KEY) || ''`);
		const typeAtEnd = async (index, text) => { await c.eval(`(focusItem(curStart().items[${index}].uid, curStart().items[${index}].text.length), true)`); await c.type(text); };
		const dropEdits = async key => c.eval(`reloadStart(cur(), ${JSON.stringify(key)}).then(() => true)`);

		// ---- warnings, worked out in the page only (one table for every rule), and the preview's markup
		await open(WIN, 'WIN_X1_BUTT__PANTIES');
		const table = await c.eval(`(() => {
			const doc = cur();
			const L = f => ({ kind: 'line', speaker: '', text: 'x', backgroundList: -1, background: -1, characterState: -1, ...f });
			const G = value => ({ kind: 'signal', value });
			const n = doc.view.sounds.length;
			const cases = [
				[G('fade_next'), null], [G('fade_next '), 'space'], [G('play_sfx_x'), 'needs a number'], [G('play_sfx_\\u00b2'), 'needs a number'],
				[G('play_sfx_' + n), 'no number'], [G('no_such_signal'), 'does nothing'], [G('atmosphere_snow'), 'no atmosphere'], [G(''), 'empty signal'],
				[L({ speaker: 7 }), 'not one of the 2 characters'], [L({ backgroundList: 0, background: 999 }), 'is not in'],
				[L({ backgroundList: 99, background: 0 }), 'is not one of the'], [L({ backgroundList: -1, background: 2 }), 'of the last list'],
				[L({ text: '   ' }), 'empty line'], [L({ speaker: 1, characterState: 40 }), 'character state 40'], [L({ speaker: '{Boss}' }), '{ or }'],
				[L({ text: '[i]unclosed italics' }), 'never closed'], [L({ text: '[B]Bold caps[/B]' }), 'lower case'], [L({ text: 'Hi [Name]!' }), 'lower case'],
				[L({ text: 'a [/b] stray' }), 'closes nothing'], [L({ text: '[b]bold [i]both[/b][/i]' }), "doesn't close"],
				[L({ text: '[b]ok[/b] [color=#ff0000]red[/color] [wait 0.4] [shake rate=20]x[/shake] [name] [br] {{MONEY}} [lb]x[rb] [sigh]' }), null],
				[L({ text: '[wait 0.5]a line that begins with its own wait, [i]open' }), null],
			];
			return cases.map(([item, want]) => { const got = itemWarnings(doc, item); return { item: item.text ?? item.value, want, got, ok: want ? got.some(w => w.includes(want)) : got.length === 0 }; });
		})()`);
		check('warnings: the page\'s one set of rules (signals, pictures, speakers, markup the game shows as text, names Godot changes)', table.every(r => r.ok), JSON.stringify(table.filter(r => !r.ok)));
		const marked = await c.eval(`[bbcode('[B]Bold caps[/B]'), bbcode('[b]bold[/b]'), bbcode('[lb]bracketed[rb]'), bbcode('Hi [Name] and [name]'), bbcode('[BR]x')]`);
		check('preview markup is case-sensitive, as the game\'s; [lb] [rb] show brackets', !marked[0].includes('<b>') && marked[1].includes('<b>bold</b>') && marked[2] === '[bracketed]'
			&& marked[3].includes('[Name]') && marked[3].includes('‹name›') && marked[4].startsWith('[BR]'), JSON.stringify(marked));

		// ---- play: fades kept as Background.gd keeps them; one way through a branching start; signals at the end
		const fades = await c.eval(`(() => {
			const doc = cur(); const list = doc.view.lists.find(l => l.pictures.length >= 3);
			const L = bg => ({ kind: 'line', speaker: '', text: 'x', backgroundList: list.index, background: bg, characterState: -1 }), G = value => ({ kind: 'signal', value });
			return { a: walkStates(doc, [L(0), G('fade_next_quick'), L(0), G('fade_next'), L(1), L(2)]).map(s => s.fadeHere),
				b: walkStates(doc, [L(0), G('fade_next'), G('fade_next_quick'), L(0)]).map(s => s.fadeHere) };
		})()`);
		check('play: a quick fade not used yet waits for the next change; both fades waiting don\'t skip the same picture', same(fades.a, [null, null, null, null, 'fade_next', 'fade_next_quick']) && fades.b[3] === 'fade_next', JSON.stringify(fades));
		await open(BOA, 'BOA_FIRST_STRIP');
		await c.eval(`(playFromSelection({ fromTop: true }), true)`);
		const boaPlay = await c.eval(`({ n: P.frames.length, ready: P.frames.filter(f => f.item.text === 'Ready to continue?').length, note: $('playWhere').textContent })`);
		await c.key('Escape');
		check('play on a start with a condition: one way through, as the game goes (20 lines, one "Ready to continue?")', boaPlay.n === 20 && boaPlay.ready === 1 && /one way through/.test(boaPlay.note), JSON.stringify(boaPlay));
		await open(WIN, 'WIN_MR1_FINGER');
		await c.eval(`(insertSignal(curStart().items.length, 'reposition_top'), focusItem(curStart().items[curStart().items.length - 2].uid, 'end'), true)`);
		await c.eval(`(playFromSelection(), true)`);
		await c.waitFor(`!$('play').hidden`, 3000, 'play');
		await c.key('ArrowRight');
		const endCard = await c.eval(`({ end: !$('playEnd').hidden && $('playEnd').textContent, flashed: [...$('playSignals').children].map(n => n.textContent).join(',') })`);
		await c.key('Escape');
		check('play: signals after the last line flash on the END card', /reposition_top/.test(endCard.end || '') && endCard.flashed.includes('reposition_top'), JSON.stringify(endCard));
		await dropEdits('WIN_MR1_FINGER');

		// ---- the play tab: it shows the editor's unsaved words, follows typing, keeps its place,
		// and at the end card plays on into a line added in the editor
		await open(WIN, 'WIN_MR1_FINGER');
		await typeAtEnd(0, ' UNSAVED IN THE EDITOR');
		// The browser's own window.open (the page was reloaded since it was caught): F5 twice, one play tab.
		const playPages = async () => (await c.send('Target.getTargets')).targetInfos.filter(t => t.type === 'page' && /[?&]play=1/.test(t.url));
		await c.key('F5');
		await sleep(1200);
		await c.eval(`(focusItem(curStart().items[1].uid, 'end'), true)`);
		await c.key('F5');
		await sleep(1200);
		const realTabs = await playPages();
		check('Play twice: one play tab, reused, now at the line selected second', realTabs.length === 1 && new URL(realTabs[0].url).searchParams.get('at') === (await c.eval(`curStart().items[1].uid`)), JSON.stringify(realTabs.map(t => t.url)));
		for (const t of realTabs) await c.send('Target.closeTarget', { targetId: t.targetId });
		await c.eval(`(window.__opened = [], window.open = (u, n) => { window.__opened.push([u, n]); return {}; }, true)`);
		await c.eval(`(focusItem(curStart().items[0].uid, 'end'), true)`);
		await c.key('F5');
		const [playUrl] = await c.eval(`window.__opened[window.__opened.length - 1]`);
		const playTab = await c.newTab(new URL(playUrl, url).href);
		await c.waitIn(playTab.session, `typeof P !== 'undefined' && P.frames.length > 0`, 15000, 'the play tab');
		const pt = () => c.evalIn(playTab.session, `({ text: $('playFrame').querySelector('.g-text')?.textContent || '', at: P.at, n: P.frames.length, ended: P.ended, end: $('playEnd').hidden ? '' : $('playEnd').textContent, where: $('playWhere').textContent, play: !$('play').hidden, title: document.title })`);
		const pt1 = await pt();
		check('the play tab opens at the selected line with the editor\'s unsaved words', pt1.play && pt1.at === 0 && pt1.text.endsWith('UNSAVED IN THE EDITOR') && !/as saved/.test(pt1.where) && pt1.title === '▶ WIN_MR1_FINGER', JSON.stringify(pt1));
		await c.evalIn(playTab.session, `(playStep(1), true)`);
		await c.waitIn(playTab.session, `!P.fading`, 4000, 'a fade in the play tab');
		const secondLine = (await pt()).text;
		await typeAtEnd(0, ' AND MORE');
		await typeAtEnd(await c.eval(`curStart().items.findIndex((i, k) => k > 0 && i.kind === 'line')`), ' EDITED WHILE SHOWN');
		await c.waitIn(playTab.session, `$('playFrame').querySelector('.g-text').textContent.endsWith('EDITED WHILE SHOWN')`, 3000, 'the typed words in the play tab');
		const pt2 = await pt();
		await c.evalIn(playTab.session, `(playStep(-1), true)`);
		const firstAgain = (await pt()).text;
		check('typing in the editor shows in the play tab as it goes, and it keeps its place', pt2.at === 1 && pt2.text === secondLine + ' EDITED WHILE SHOWN' && firstAgain.endsWith('UNSAVED IN THE EDITOR AND MORE'), JSON.stringify({ pt2, firstAgain }));
		await c.evalIn(playTab.session, `(() => { for (let i = 0; i < 300 && !P.ended; i++) playStep(1); return true; })()`);
		const playEnded = await pt();
		await c.eval(`(insertLine(curStart().items.length, 'A NEW LAST LINE'), true)`);
		await c.waitIn(playTab.session, `!P.ended && $('playFrame').querySelector('.g-text').textContent === 'A NEW LAST LINE'`, 3000, 'the new line in the play tab');
		const pt3 = await pt();
		check('at the end card, a line added in the editor plays on from there', playEnded.ended && /a line added in the editor plays on/.test(playEnded.end) && !pt3.ended && pt3.n === playEnded.n + 1 && pt3.at === playEnded.n, JSON.stringify({ playEnded, pt3 }));
		await c.evalIn(playTab.session, `(window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true })), true)`);
		const playTabId = await c.evalIn(playTab.session, `TAB_ID`);
		await sleep(600);	// the editor's drafts are written 400 ms after an edit
		const draftTabs = await c.eval(`Object.keys(load(DRAFTS_KEY) || {})`);
		check('the play tab stays on Esc, and keeps no drafts of its own', (await pt()).play && !draftTabs.includes(playTabId) && draftTabs.includes(await c.eval(`TAB_ID`)), JSON.stringify({ draftTabs, playTabId }));
		await c.send('Target.closeTarget', { targetId: playTab.targetId });
		const lone = new URL(playUrl, url);
		lone.searchParams.set('tab', 'gone');
		const loneTab = await c.newTab(lone.href);
		await c.waitIn(loneTab.session, `typeof P !== 'undefined' && P.frames.length > 0`, 15000, 'a play tab with no editor');
		const lonely = await c.evalIn(loneTab.session, `({ where: $('playWhere').textContent, text: $('playFrame').querySelector('.g-text').textContent })`);
		await c.send('Target.closeTarget', { targetId: loneTab.targetId });
		check('a play tab whose editor tab is gone plays the start as saved, and says so', /as saved/.test(lonely.where) && !lonely.text.includes('UNSAVED'), JSON.stringify(lonely));
		await dropEdits('WIN_MR1_FINGER');

		// ---- the speaker menu: typing finds a speaker; a character's name is that character
		await open(WIN, 'WIN_X1_BUTT__PANTIES');
		const pickSpeaker = async typed => {
			await c.click('#rows .item:nth-child(1) .speaker');
			await c.waitFor(`!$('menu').hidden && document.activeElement.classList.contains('m-input')`, 3000, 'the speaker menu');
			await c.type(typed);
			const list = await c.eval(`[...$('menu').querySelectorAll('.mi')].map(n => n.textContent)`);
			await c.key('Enter');
			return { list, speaker: await c.eval(`curStart().items[0].speaker`) };
		};
		const ash = await pickSpeaker('Ash'), ashely = await pickSpeaker('ashely'), bob = await pickSpeaker('Bobby');
		check('speaker menu: "Ash" + Enter and "ashely" + Enter pick the character Ashely; an unknown name is offered as a new one', ash.speaker === 1 && ashely.speaker === 1
			&& bob.speaker === 'Bobby' && bob.list.some(t => /Use “Bobby” as a new name/.test(t)) && ash.list[0].startsWith('Ashely'), JSON.stringify({ ash, ashely, bob }));
		await dropEdits('WIN_X1_BUTT__PANTIES');

		// ---- writing keys: / on an unwritten line, ↓ onto a signal and typing on, ↓ then Enter, the
		// caret after a popup, the first and last line, play from the top
		await open(WIN, 'WIN_X1_BUTT__DRESSED');
		await c.eval(`(focusItem(curStart().items[1].uid, 'start'), true)`);
		await c.key('/');
		const slashMenu = await c.eval(`!$('menu').hidden && document.activeElement.classList.contains('m-input') && isPlaceholder(curStart().items[1].text)`);
		await c.key('Escape');
		check('/ on an unwritten line (its placeholder selected) opens the signal picker', slashMenu);
		await c.eval(`(insertSignal(2, 'fade_next'), focusItem(curStart().items[1].uid, 'end'), true)`);
		await c.key('ArrowDown');
		const onSignal = await c.eval(`document.activeElement === rowCache.get(curStart().items[2].uid)`);
		for (const ch of 'She') await c.key(ch, { text: ch });
		let w = await c.eval(model);
		check('↓ onto a signal stops on its row; typing there goes on into the next line, the signal unchanged', onSignal && w[2].value === 'fade_next' && w[3].text === 'She', JSON.stringify([w[2], w[3].text]));
		await c.key('ArrowUp');
		await c.key('ArrowDown');
		const atEnd = await c.eval(`document.activeElement.selectionStart === document.activeElement.value.length`);
		await c.key('Enter');
		w = await c.eval(model);
		const fresh = await c.eval(`(() => { const row = document.activeElement.closest('.item'); return { i: curStart().items.findIndex(i => i.uid === row._uid), warns: row.querySelector('.warns').textContent, hint: document.activeElement.placeholder, same: row.classList.contains('same-pic'), h: row.getBoundingClientRect().height }; })()`);
		check('↓ lands at the end of a line, so Enter then adds the line below; the new line shows no "empty line" while written in', atEnd && fresh.i === 4 && w[3].text === 'She' && !/empty line/.test(fresh.warns), JSON.stringify(fresh));
		check('an empty line\'s box says the writing keys; a line on the same picture as the one before shows a slim mark, not the picture', /Enter/.test(fresh.hint) && /Alt\+0/.test(fresh.hint) && fresh.same && fresh.h < 100, JSON.stringify(fresh));
		await c.type('abcdef');
		await setCaret(c, 2);
		await c.key('p', { ctrl: true });
		await c.waitFor(`!$('quick').hidden`);
		await c.key('Escape');
		const caretBack = await c.eval(`document.activeElement.selectionStart`);
		await c.click('#pvNext');
		await sleep(100);
		const caretAfterPicture = await c.eval(`document.activeElement.selectionStart`);
		check('the caret goes back where it was after Ctrl+P / Esc and after a picture button', caretBack === 2 && caretAfterPicture === 2, `${caretBack} ${caretAfterPicture}`);
		await c.key('End', { ctrl: true });
		const last = await c.eval(focusedIndex);
		await c.key('Home', { ctrl: true });
		const firstLine = await c.eval(focusedIndex);
		await c.eval(`(window.__opened = [], window.open = (u, n) => { window.__opened.push([u, n]); return {}; }, true)`);
		await c.key('F5', { shift: true });
		const [topUrl] = await c.eval(`window.__opened[window.__opened.length - 1]`);
		const fromTop = new URL(topUrl, url).searchParams.get('at') === '' ? 0 : -1;
		check('Ctrl+End / Ctrl+Home go to the last / first line; Shift+F5 plays from the top', last === (await c.eval(`curStart().items.length - 1`)) && firstLine === 0 && fromTop === 0, `${last} ${firstLine} ${fromTop}`);
		const caption = await c.eval(`$('pvCaption').textContent`);
		check('the panel shows the selected line as readable text under the picture', caption.includes((await c.eval(`curStart().items[0].text`)).slice(0, 30)), caption.slice(0, 80));
		await c.eval(`(focusItem(curStart().items[0].uid, 'start'), true)`);
		await c.key('End');
		await c.type(' MY NOTE: she laughs');
		const kept = await c.eval(`$('rows').children[0].querySelector('.warns').textContent`);
		check('a line written after its "(Placeholder)" still counts as unwritten: the row says so', /still starts with “\(Placeholder\)”/.test(kept), kept);
		await dropEdits('WIN_X1_BUTT__DRESSED');
		check('the picture preview says a click plays', await c.eval(`getComputedStyle($('pvFrame')).cursor === 'pointer' && /Play/.test($('pvFrame').title)`));

		// ---- undo stops at the start's edge first
		await open(WIN, 'WIN_MR1_KISS');
		await typeAtEnd(0, ' AAA');
		await open(WIN, 'WIN_L1_TRUTH__PANTIES');
		await typeAtEnd(0, ' BBB');
		await c.eval(`(document.activeElement.blur(), true)`);
		await c.key('z', { ctrl: true });
		const u1 = await c.eval(`[S.key, curStart().items[0].text.endsWith(' BBB')]`);
		await c.key('z', { ctrl: true });
		const u2 = await c.eval(`[S.key, S.docs.get(${JSON.stringify(WIN)}).starts.get('WIN_MR1_KISS').items[0].text.endsWith(' AAA'), $('toast').textContent]`);
		await c.key('z', { ctrl: true });
		const u3 = await c.eval(`[S.key, curStart().items[0].text.endsWith(' AAA')]`);
		check('Ctrl+Z past the start\'s own edits says so first, and goes into the other start only on the next press', same(u1, ['WIN_L1_TRUTH__PANTIES', false])
			&& u2[0] === 'WIN_L1_TRUTH__PANTIES' && u2[1] && /Nothing more to undo in WIN_L1_TRUTH__PANTIES/.test(u2[2]) && same(u3, ['WIN_MR1_KISS', false]), JSON.stringify([u1, u2, u3]));

		// ---- a long new key keeps its "new" tag readable; Alt+N adds after the open start; undo after saving keeps it
		await c.eval(`(addStart('WIN_X3_UNDER_AFTERGLOW_A_RATHER_LONG_KEY'), true)`);
		await sleep(150);
		const tag = await c.eval(`(() => { const row = [...$('startList').children].find(n => n.dataset.key === 'WIN_X3_UNDER_AFTERGLOW_A_RATHER_LONG_KEY'); const t = row.querySelector('.tag'); const r = t.getBoundingClientRect(), b = row.getBoundingClientRect(); return { text: t.textContent, fits: t.scrollWidth <= t.clientWidth + 1 && r.right <= b.right && r.width > 10 }; })()`);
		check('the "new" tag of a long key is whole (the key is what gets cut)', tag.text === 'new' && tag.fits, JSON.stringify(tag));
		await c.eval(`(document.activeElement.blur(), true)`);
		await c.key('z', { ctrl: true });
		await c.key('z', { ctrl: true });
		check('Ctrl+Z takes back an unsaved new start', !(await c.eval(`cur().starts.has('WIN_X3_UNDER_AFTERGLOW_A_RATHER_LONG_KEY')`)));
		await open(WIN, 'WIN_L2_NICE__TOP_OFF');
		await c.eval(`(document.activeElement && document.activeElement.blur && document.activeElement.blur(), $('scriptPane').focus(), true)`);
		await c.key('n', { alt: true });
		await c.waitFor(`!$('newStartForm').hidden && document.activeElement === $('newStartKey')`, 3000, 'the new start box');
		await c.type('alt n start');
		await c.key('Enter');
		await c.waitFor(`S.key === 'ALT_N_START' && curStart().items.length === 1`, 3000, 'the new start');
		const placedAfter = await c.eval(`cur().order.indexOf('ALT_N_START') === cur().order.indexOf('WIN_L2_NICE__TOP_OFF') + 1`);
		await c.type('Its first line.');
		await c.key('s', { ctrl: true });
		await c.waitFor(`!S.saving && $('saveState').textContent === 'Saved'`, 8000, 'saving ALT_N_START');
		const keysNow = startKeysOnDisk(project, WIN);
		check('Alt+N: a new start, after the open one, here and in the file', placedAfter && keysNow[keysNow.indexOf('WIN_L2_NICE__TOP_OFF') + 1] === 'ALT_N_START', keysNow.slice(-6).join(' '));
		// Its two own steps (the line, its words), then the boundary: it stays in the page throughout.
		for (let i = 0; i < 3; i++) await c.key('z', { ctrl: true });
		const stillThere = await c.eval(`cur().starts.has('ALT_N_START') && cur().order.includes('ALT_N_START')`);
		check('undo after saving a new start never takes it out of the page while it stays in the file', stillThere && startKeysOnDisk(project, WIN).includes('ALT_N_START'));
		await dropEdits('ALT_N_START');

		// ---- a start that turns read-only on disk while it has edits here keeps them (stranded)
		const join = (mode, node = '') => execFileSync(PYTHON, ['-P', '-E', '-c', `import sys; sys.path.insert(0, sys.argv[1]); import dialogues as D
path, a, b, mode, node = sys.argv[2:7]
text = D.read_text(path); doc = D.Doc(text)
target = doc.walk(a).ids[0]
node = node or doc.walk(b).ids[-1]
raw = doc.raw[node]
new = raw.replace('"link": "END"', '"link": &"' + target + '"') if mode == 'join' else raw.replace('"link": &"' + target + '"', '"link": "END"')
assert new != raw
D.P.save_text(D.Path(path), text.replace(raw, new))
print(node)`, TOOL, path.join(project, WIN.replace('res://', '')), 'WON__DRESSED', 'WON__TOP_OFF', mode, node], { encoding: 'utf-8' }).trim();
		await open(WIN, 'WON__DRESSED');
		await typeAtEnd(0, ' MY UNSAVED WORDS');
		await sleep(600);
		const joined = join('join');
		await c.eval(`checkVersions().then(() => true)`);
		const stranded = await c.eval(`(() => { const st = cur().starts.get('WON__DRESSED'); return { stranded: !!st.stranded, dirty: isDirty(st), any: anyDirty(), state: $('saveState').textContent, banner: !!document.querySelector('.stranded-banner'), text: st.items[0].text }; })()`);
		check('a start that turns read-only on disk keeps its edits: still unsaved, in the drafts, shown with its banner', stranded.stranded && stranded.dirty && stranded.any
			&& /^Unsaved/.test(stranded.state) && stranded.banner && stranded.text.endsWith('MY UNSAVED WORDS') && (await stored()).includes('MY UNSAVED WORDS'), JSON.stringify(stranded));
		await c.eval(`(document.activeElement && document.activeElement.blur(), true)`);
		await c.key('z', { ctrl: true });
		await sleep(300);
		const undone = await c.eval(`(() => { const st = cur().starts.get('WON__DRESSED'); return { dirty: isDirty(st), text: st.items[0].text }; })()`);
		check('Ctrl+Z leaves a stranded start\'s kept edits alone', undone.dirty && undone.text.endsWith('MY UNSAVED WORDS'), JSON.stringify(undone));
		await open(WIN, 'WIN_X3_BJ__TOP_OFF');
		await typeAtEnd(0, ' saved next to a stranded one');
		await c.key('s', { ctrl: true });
		await c.waitFor(`!S.saving`, 8000, 'the save');
		const others = chainOnDisk(project, WIN, 'WIN_X3_BJ__TOP_OFF').items[0].text;
		check('a stranded start doesn\'t stop the rest of its file saving', others.endsWith('saved next to a stranded one') && (await c.eval(`isDirty(cur().starts.get('WON__DRESSED'))`)), others);
		join('unjoin', joined);
		await c.eval(`checkVersions().then(() => true)`);
		const back = await c.eval(`(() => { const st = cur().starts.get('WON__DRESSED'); return { stranded: !!st.stranded, readOnly: st.readOnly, dirty: isDirty(st) }; })()`);
		await c.key('s', { ctrl: true });
		await c.waitFor(`!S.saving && $('saveState').textContent === 'Saved'`, 8000, 'the save');
		check('editable again on disk (same version): the kept edits save', !back.stranded && !back.readOnly && back.dirty && chainOnDisk(project, WIN, 'WON__DRESSED').items[0].text.endsWith('MY UNSAVED WORDS'), JSON.stringify(back));

		// ---- a save into a file changed outside a moment before: the page shows that change right after
		await open(WIN, 'WIN_X2_BREAST__TOP_OFF');
		await typeAtEnd(0, ' MY EDIT');
		const [outsideStatus] = await editOnDisk(WIN, 'WON__PANTIES', 'EXTERNAL EDIT (Godot or the packager)');
		await c.key('s', { ctrl: true });
		await c.waitFor(`!S.saving && cur().starts.get('WON__PANTIES').items[0].text.startsWith('EXTERNAL EDIT')`, 12000, 'the outside edit to show');
		check('saving into a file that changed outside just before: the change shows at once (no stale start to overwrite it later)', outsideStatus === 200 && !(await c.eval(`isDirty(cur().starts.get('WON__PANTIES'))`)));

		// ---- one file that can't be read doesn't stop the page noticing changes to the others
		await c.eval(`ensureDoc(${JSON.stringify(LOSE)}).then(() => true)`);
		const loseFile = path.join(project, LOSE.replace('res://', ''));
		const loseBytes = fs.readFileSync(loseFile);
		fs.writeFileSync(loseFile, loseBytes.subarray(0, loseBytes.length >> 1));
		expectedErrors++;
		await editOnDisk(WIN, 'WIN_L3_SMILE__TOP_OFF', 'CHANGED IN GODOT');
		await c.eval(`checkVersions().then(() => true)`);
		const seen = await c.eval(`({ text: cur().starts.get('WIN_L3_SMILE__TOP_OFF').items[0].text, notice: !!document.querySelector('.notice[data-id="unreadable-${LOSE}"]') })`);
		fs.writeFileSync(loseFile, loseBytes);
		await c.eval(`checkVersions().then(() => true)`);
		check('an unreadable file is named in a notice, and the other files\' changes still show', seen.text === 'CHANGED IN GODOT' && seen.notice && !(await c.eval(`!!document.querySelector('.notice[data-id="unreadable-${LOSE}"]')`)), JSON.stringify(seen));

		// ---- a pasted NUL (invisible) is left out, not a refused save
		await open(WIN, 'WIN_X3_UNDER__DRESSED');
		await c.eval(`(focusItem(curStart().items[4].uid, curStart().items[4].text.length), document.execCommand('insertText', false, ' pasted\\u0000text'), true)`);
		const nul = await c.eval(`curStart().items[4].text`);
		check('a NUL pasted into a line is left out at once', !nul.includes('\u0000') && nul.endsWith(' pastedtext'), JSON.stringify(nul.slice(-20)));
		await dropEdits('WIN_X3_UNDER__DRESSED');

		// ---- a conflict: compare with the disk version; a new start whose key the file got meanwhile saves under another key
		await open(WIN, 'WIN_X4_SEX__DRESSED');
		await typeAtEnd(1, ' mine');
		await editOnDisk(WIN, 'WIN_X4_SEX__DRESSED', 'THEIRS ON DISK', 2);
		expectedErrors++;
		await c.key('s', { ctrl: true });
		await c.waitFor(`!S.saving && !!document.querySelector('.conflict-banner')`, 8000, 'the conflict');
		const compareAt = await c.eval(`[...document.querySelectorAll('.conflict-banner button')].findIndex(b => b.textContent === 'Compare')`);
		await c.click('.conflict-banner button', { index: compareAt });
		await c.waitFor(`!$('dialog').hidden && !!$('dText').querySelector('table.compare')`, 5000, 'the comparison');
		const compared = await c.eval(`({ diff: [...$('dText').querySelectorAll('tr.diff')].map(r => r.textContent), head: $('dText').querySelector('tr').textContent })`);
		await c.key('Escape');
		check('conflict: Compare shows the disk version next to mine, the lines that differ marked', compared.diff.length === 2 && compared.diff.some(t => t.includes('THEIRS ON DISK')) && compared.diff.some(t => t.endsWith(' mine')), JSON.stringify(compared));
		await dropEdits('WIN_X4_SEX__DRESSED');
		await c.eval(`(addStart('NEWCLASH'), true)`);
		await c.waitFor(`S.key === 'NEWCLASH' && curStart().items.length === 1`, 3000, 'NEWCLASH');
		await c.type('My clash line.');
		const [clashStatus] = await apiSave(WIN, [{ op: 'add', key: 'NEWCLASH', items: [{ kind: 'line', text: 'theirs', speaker: '', backgroundList: -1, background: -1 }] }]);
		expectedErrors++;
		await c.key('s', { ctrl: true });
		await c.waitFor(`!S.saving && !!document.querySelector('.conflict-banner')`, 8000, 'the key clash');
		const asMine = await c.eval(`[...document.querySelectorAll('.conflict-banner button')].findIndex(b => /Save mine as NEWCLASH_MINE/.test(b.textContent))`);
		await c.click('.conflict-banner button', { index: asMine });
		await c.key('s', { ctrl: true });
		await c.waitFor(`!S.saving && $('saveState').textContent === 'Saved'`, 8000, 'the save as NEWCLASH_MINE');
		check('a new start whose key the file got meanwhile: "Save mine as …" keeps both', clashStatus === 200 && chainOnDisk(project, WIN, 'NEWCLASH_MINE').items[0].text === 'My clash line.'
			&& chainOnDisk(project, WIN, 'NEWCLASH').items[0].text === 'theirs');

		// ---- drafts: nothing is dropped when what they belong to changed (a deleted start, a key taken,
		// edits made since in the same start), or the file moved
		const clean = async () => { await c.eval(`(S.docs.clear(), S.pendingDrafts = null, S.adoptedTabs = [], localStorage.removeItem(DRAFTS_KEY), true)`); await c.page('Page.reload'); await c.waitFor(`typeof S !== 'undefined' && S.loaded && !!curStart()`, 15000, 'the page'); await sleep(500); };
		await clean();
		await open(LOSE, 'LOSE_P2_DICK_PIC');
		await typeAtEnd(0, ' DRAFT WORDS FOR P2');
		await open(LOSE, 'LOSE_P1_ASS_KISS__SHORTS_OFF');
		await typeAtEnd(0, ' OLD DRAFT WORDS');
		await c.eval(`(addStart('DRAFT_ADD'), true)`);
		await c.waitFor(`S.key === 'DRAFT_ADD' && curStart().items.length === 1`, 3000, 'DRAFT_ADD');
		await c.type('DRAFT WORDS FOR THE NEW START');
		await sleep(700);
		const p2 = (await apiFile(LOSE)).starts.find(s => s.key === 'LOSE_P2_DICK_PIC');
		const [delStatus] = await apiSave(LOSE, [{ op: 'delete', key: 'LOSE_P2_DICK_PIC', base: p2.fingerprint }, { op: 'add', key: 'DRAFT_ADD', items: [] }]);
		await c.page('Page.reload');
		await c.waitFor(`typeof S !== 'undefined' && S.loaded && !!document.querySelector('.notice[data-id="drafts"]')`, 15000, 'the drafts notice');
		await open(LOSE, 'LOSE_P1_ASS_KISS__SHORTS_OFF');
		await typeAtEnd(0, ' TODAY I WROTE THIS');
		await c.click('.notice[data-id="drafts"] button.primary');
		await c.waitFor(`!document.querySelector('.notice[data-id="drafts"] button.primary')`, 8000, 'the restore');
		const restored = await c.eval(`(() => { const d = S.docs.get(${JSON.stringify(LOSE)}); const t = k => d.starts.has(k) ? d.starts.get(k).items.map(i => i.text).join('|') : null;
			return { p2: t('LOSE_P2_DICK_PIC'), p2added: d.starts.get('LOSE_P2_DICK_PIC')?.added, add: t('DRAFT_ADD'), addDraft: t('DRAFT_ADD_DRAFT'), off: t('LOSE_P1_ASS_KISS__SHORTS_OFF'),
				offDraft: t('LOSE_P1_ASS_KISS__SHORTS_OFF_DRAFT'), any: anyDirty(), notice: document.querySelector('.notice[data-id="drafts"]')?.textContent || '' }; })()`);
		const storage = await stored();
		check('restoring drafts: a start deleted on disk comes back as a new start; a key now taken goes in as KEY_DRAFT; nothing is lost',
			delStatus === 200 && restored.p2added && /DRAFT WORDS FOR P2/.test(restored.p2) && restored.add === '' && /DRAFT WORDS FOR THE NEW START/.test(restored.addDraft || '')
			&& restored.any && /P2_DICK_PIC/.test(restored.notice) && ['DRAFT WORDS FOR P2', 'DRAFT WORDS FOR THE NEW START'].every(t => storage.includes(t)), JSON.stringify(restored));
		check('restoring drafts over a start written in this session keeps both (the draft as KEY_DRAFT)', /TODAY I WROTE THIS/.test(restored.off) && !/OLD DRAFT WORDS/.test(restored.off)
			&& /OLD DRAFT WORDS/.test(restored.offDraft || '') && ['OLD DRAFT WORDS', 'TODAY I WROTE THIS'].every(t => storage.includes(t)), JSON.stringify(restored));
		await clean();
		await open(LOSE, 'LOSE_P3A_YOUR_WALK');
		await typeAtEnd(0, ' WORDS IN A FILE THAT GETS MOVED');
		await sleep(700);
		const moved = loseFile.replace('d_ashely2_lose.tres', 'd_ashely2_lose_moved.tres');
		const keptMoved = await stored();
		fs.renameSync(loseFile, moved);
		await sleep(3500);
		await c.page('Page.reload');
		await sleep(1500);
		const lost = await c.eval(`({ notice: document.querySelector('.notice[data-id="drafts"]')?.textContent || '', stored: localStorage.getItem(DRAFTS_KEY) || '' })`);
		let shown = '';
		if (/not found/.test(lost.notice)) {
			const at = await c.eval(`[...document.querySelectorAll('.notice[data-id="drafts"] button')].findIndex(b => /Show their text/.test(b.textContent))`);
			await c.click('.notice[data-id="drafts"] button', { index: at });
			await c.waitFor(`!$('dialog').hidden`, 3000, 'the draft text');
			shown = await c.eval(`$('dText').querySelector('textarea').value`);
			await c.key('Escape');
		}
		fs.renameSync(moved, loseFile);
		check('drafts of a file that moved are kept and shown, not dropped', keptMoved.includes('WORDS IN A FILE THAT GETS MOVED') && /not found/.test(lost.notice)
			&& lost.stored.includes('WORDS IN A FILE THAT GETS MOVED') && shown.includes('WORDS IN A FILE THAT GETS MOVED'), JSON.stringify({ notice: lost.notice, shown: shown.slice(0, 120) }));
		await sleep(3500);
		await clean();

		// ---- two tabs: each keeps its own drafts; a tab's drafts are offered only once it is gone
		await open(WIN, 'WIN_X2_BREAST__DRESSED');
		await typeAtEnd(0, ' TAB A UNSAVED WORDS');
		await sleep(700);
		const tabB = await c.newTab(url);
		await c.waitIn(tabB.session, `typeof S !== 'undefined' && S.loaded && !!curStart()`, 15000, 'tab B');
		await sleep(800);
		const bOffered = await c.evalIn(tabB.session, `!!document.querySelector('.notice[data-id="drafts"]')`);
		await c.evalIn(tabB.session, `openStart(${JSON.stringify(LOSE)}, 'LOSE_P1_ASS_KISS__DRESSED').then(() => { focusItem(curStart().items[0].uid, 'end'); document.execCommand('insertText', false, ' from tab B'); return true; })`);
		await c.evalIn(tabB.session, `saveAll().then(() => true)`);
		const afterB = await stored();
		check('a second tab doesn\'t offer the first tab\'s live edits, and its save keeps them in storage', !bOffered && afterB.includes('TAB A UNSAVED WORDS')
			&& chainOnDisk(project, LOSE, 'LOSE_P1_ASS_KISS__DRESSED').items[0].text.endsWith(' from tab B'), JSON.stringify({ bOffered }));
		await c.send('Target.closeTarget', { targetId: tabB.targetId });
		// Tab A goes away (as after a crash); a new tab is offered its edits.
		const tabC = await c.newTab('about:blank');
		await c.eval(`(window.__gone = true, channel && channel.close(), true)`);
		await c.evalIn(tabC.session, `(location.href = ${JSON.stringify(url)}, true)`);
		await c.waitIn(tabC.session, `typeof S !== 'undefined' && S.loaded && !!document.querySelector('.notice[data-id="drafts"]')`, 15000, 'the drafts notice in tab C');
		const cNotice = await c.evalIn(tabC.session, `document.querySelector('.notice[data-id="drafts"]').textContent`);
		check('once a tab is gone, a new tab offers its edits', /WIN_X2_BREAST__DRESSED/.test(cNotice), cNotice);
		await c.send('Target.closeTarget', { targetId: tabC.targetId });

		}

		// ---- console and network
		const unexpected = consoleErrors.filter(e => !/status of (409|422)/.test(e) && !/status of (400|403|404) .*\/api\/reveal$/.test(e));
		check('no console errors (besides the expected refusals: 409 conflicts, 422 for the file cut short, the three files Show in folder must refuse)', unexpected.length === 0 && consoleErrors.length - unexpected.length <= expectedErrors, JSON.stringify(consoleErrors).slice(0, 600));
		const origin = new URL(url).origin;
		const outside = requests.filter(u => !u.startsWith(origin) && !u.startsWith('data:') && u !== 'about:blank');
		check('no requests leave 127.0.0.1', outside.length === 0, outside.slice(0, 5).join(' '));
	} catch (e) {
		check('the run finished', false, e.stack || String(e));
		try { await c.shot('failure'); } catch { /* no page */ }
	} finally {
		await c.close();
		server.kill();
		await sleep(300);
		for (const dir of ['profile', 'backups', 'cache'].map(d => path.join(tmpRoot, d)).concat(ownCopy && !flag('keep') ? [project] : [])) {
			try { fs.rmSync(dir, { recursive: true, force: true, maxRetries: 5 }); } catch (e) { console.log('could not remove ' + dir + ': ' + e.message); }
		}
		try { fs.rmdirSync(tmpRoot); } catch { /* the copy, kept with --keep */ }
	}
	const failed = results.filter(r => !r.ok);
	console.log(`\n${results.length - failed.length}/${results.length} passed.${shotsDir ? ` Screenshots: ${shotsDir}` : ''}${flag('keep') && ownCopy ? ` Copy kept: ${project}` : ''}`);
	process.exitCode = failed.length ? 1 : 0;
}
// Run when started directly; a scratch script can import Chrome and the helpers instead.
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
export { startServer, makeCopy, chainOnDisk, sleep, inReal };
