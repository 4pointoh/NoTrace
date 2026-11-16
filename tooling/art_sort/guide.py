"""A dialogue guide for a packaged scene: one HTML page that says, for every dialogue start, what the
scene is, when it plays, which file and start node to open, which pictures it shows line by line,
and which pictures of its list no line uses yet.

    python -P -E art_sort.py guide <workspace>      (Put in the game also rewrites it)

It reads the game itself (the stages, their dialogue files, the picture lists), so it is never out
of date after a fresh run. The words around it come from scene.json: each sequence's designRow,
state and context, plus a "guide" block in the "game" block:
    file       where the page goes, relative to the project (eg docs/ashely_poker2/dialogue_guide.html)
    title      the page's title
    stages     the scene's game stage names, in play order
    overview   lines saying how the scene runs, shown at the top
    scenes     per start key: title, when (when it plays) and next (what follows)
    open       lines listing what is still open, shown at the top
"""
import datetime
import html
import os
import re
import urllib.parse
from pathlib import Path

import package as P

STARTS_ROUTING = 'routing'


def esc(text):
    return html.escape(str(text), quote=True)


class Guide:
    def __init__(self, workspace):
        self.workspace = workspace
        self.config = workspace.scene.get('game') or {}
        self.guide = self.config.get('guide')
        if not self.guide or not self.guide.get('file'):
            raise P.PackageError('scene.json\'s "game" block has no "guide" with a "file"')
        project = self.config.get('project')
        self.project = P.Project(Path(os.path.expanduser(project)) if project else P.find_project())
        self.out = self.project.root / self.guide['file']
        self.lists = P.Lists(self.project, self.config['backgroundLists'])
        self.pictures = self.config['pictures'].rstrip('/')
        self.list_cache = {}
        self.sequences = {s['key']: (stage, s) for stage, s in workspace.sequences(workspace.board())}

    # ---- reading the game

    def list_pictures(self, index):
        """A picture list's (name, imagePath) pairs, by its position in the BackgroundLists."""
        if index not in self.list_cache:
            path = self.project.path(self.lists.paths[index])
            self.list_cache[index] = P.list_backgrounds(path.read_text(encoding='utf-8')) if path.exists() else []
        return self.list_cache[index]

    def list_name(self, index):
        return Path(self.lists.paths[index]).stem

    def stages(self):
        """The scene's game stages in play order: name, display name, its .tres, dialogue, choice script."""
        wanted = self.guide.get('stages', [])
        found = {}
        root = self.project.path(self.config.get('stages', 'res://data/game_stages'))
        for path in sorted(root.rglob('*.tres')):
            text = path.read_text(encoding='utf-8')
            if 'script_class="GameStage"' not in text:
                continue
            section = P.resource_section(text)
            name = P.string_property(section, 'name')
            if name not in wanted:
                continue
            refs = P.ext_resources(text)

            def ref(prop):
                found_ref = re.search(rf'^{prop} = ExtResource\("([^"]+)"\)', section, re.MULTILINE)
                return refs.get(found_ref.group(1)) if found_ref else None
            endings = re.search(r'^endingDialogueKeys = Array\[String\]\(\[(.*)\]\)$', section, re.MULTILINE)
            found[name] = {
                'name': name, 'display': P.string_property(section, 'displayName') or name,
                'file': self.project.res(path), 'dialogue': ref('dialogue'), 'choices': ref('choicesScript'),
                'poker': ref('pokerScript'), 'next': ref('guaranteedNextGameStage'),
                'endings': re.findall(r'"([^"]*)"', endings.group(1)) if endings else [],
            }
        return [found[name] for name in wanted if name in found]

    def scene_lines(self, dialogue, key):
        """The nodes a start leads through, as rows: kind, node id, and for a line its speaker, text and
        picture (list index, picture index)."""
        rows = []
        for node_id in dialogue.chain(key):
            node = dialogue.nodes[node_id]
            if P.is_dialogue_node(node_id, node):
                speaker = node.get('speaker', '')
                if isinstance(speaker, int):
                    speaker = dialogue.speakers[speaker] if 0 <= speaker < len(dialogue.speakers) else f'#{speaker}'
                list_index, picture = node.get('backgroundList', -1), node.get('background', -1)
                rows.append({'kind': 'line', 'id': str(node_id), 'speaker': speaker, 'text': str(node.get('dialogue', '')),
                             'picture': (list_index, picture) if isinstance(list_index, int) and list_index >= 0
                             and isinstance(picture, int) and picture >= 0 else None})
            else:
                what = node.get('signalValue') if isinstance(node, dict) else None
                rows.append({'kind': 'other', 'id': str(node_id), 'text': f'signal "{what}"' if what else 'node'})
        return rows

    # ---- writing the page

    def image(self, list_index, picture, size='line'):
        pictures = self.list_pictures(list_index)
        if not 0 <= picture < len(pictures):
            return f'<span class="missing">{esc(self.list_name(list_index))} #{picture + 1}: no such picture</span>'
        name, image_path = pictures[picture]
        rel = os.path.relpath(self.project.path(image_path), self.out.parent).replace(os.sep, '/')
        url = '/'.join(urllib.parse.quote(part) for part in rel.split('/'))
        placeholder = '/placeholders/' in image_path
        list_name = self.list_name(list_index)
        label = name if name.startswith(list_name) else f'{list_name} · {name}'
        return (f'<a class="pic {size}{" placeholder" if placeholder else ""}" href="{url}" target="_blank" '
                f'title="{esc(image_path)}"><img loading="lazy" src="{url}" alt="{esc(label)}">'
                f'<span>{esc(label)}{" (placeholder)" if placeholder else ""}</span></a>')

    def write(self):
        stages = self.stages()
        scenes_conf = self.guide.get('scenes', {})
        written_total = lines_total = 0
        toc, body = [], []
        for stage in stages:
            dialogue = P.Dialogue(self.project, self.project.path(stage['dialogue'])) if stage['dialogue'] else None
            starts = list(dialogue.starts) if dialogue else []
            cards, entries = [], []
            for key in starts:
                conf = scenes_conf.get(key, {})
                rows = self.scene_lines(dialogue, key)
                lines = [r for r in rows if r['kind'] == 'line']
                written = sum(1 for r in lines if not r['text'].startswith(P.PLACEHOLDER))
                routing = not lines
                written_total += written
                lines_total += len(lines)
                anchor = f'{stage["name"]}-{key}'
                status = ('routing' if routing else f'{written}/{len(lines)} written')
                chip = 'routing' if routing else 'done' if written == len(lines) else 'todo'
                entries.append(f'<li><a href="#{esc(anchor)}"><code>{esc(key)}</code></a> '
                               f'<span class="chip {chip}">{esc(status)}</span>'
                               f'<span class="toc-title">{esc(conf.get("title", ""))}</span></li>')
                cards.append(self.card(stage, dialogue, key, conf, rows, anchor, routing))
            toc.append(f'<li><a href="#{esc(stage["name"])}">{esc(stage["display"])}</a><ul>{"".join(entries)}</ul></li>')
            files = [('Game stage', stage['file']), ('Dialogue', stage['dialogue']),
                     ('Choices', stage['choices']), ('Poker script', stage['poker'])]
            files_html = ''.join(f'<div><b>{label}</b> <code>{esc(res)}</code></div>' for label, res in files if res)
            endings = (f'<div><b>Ends the stage</b> {", ".join(f"<code>{esc(k)}</code>" for k in stage["endings"])}</div>'
                       if stage['endings'] else '')
            body.append(f'<section class="stage" id="{esc(stage["name"])}"><h2>{esc(stage["display"])} '
                        f'<small><code>{esc(stage["name"])}</code></small></h2><div class="files">{files_html}{endings}</div>'
                        f'{"".join(cards)}</section>')

        overview = ''.join(f'<li>{line}</li>' for line in self.guide.get('overview', []))
        open_items = ''.join(f'<li>{line}</li>' for line in self.guide.get('open', []))
        stamp = datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
        try:
            workspace_shown = '~/' + self.workspace.root.relative_to(Path.home()).as_posix()
        except ValueError:
            workspace_shown = str(self.workspace.root)
        page = PAGE.format(
            title=esc(self.guide.get('title', 'Dialogue guide')), stamp=stamp, written=written_total, lines=lines_total,
            overview=f'<h2>How the scene runs</h2><ul>{overview}</ul>' if overview else '',
            open=f'<h2>Still open</h2><ul>{open_items}</ul>' if open_items else '',
            toc=''.join(toc), body=''.join(body),
            command=esc(f'python -P -E tooling/art_sort/art_sort.py guide {workspace_shown}'))
        self.out.parent.mkdir(parents=True, exist_ok=True)
        changed = P.save_text(self.out, page)
        return {'file': str(self.out), 'written': written_total, 'lines': lines_total, 'changed': changed}

    def card(self, stage, dialogue, key, conf, rows, anchor, routing):
        stage_name, sequence = self.sequences.get(key, (None, None))
        start_id = str(dialogue.starts[key])
        start_node = dialogue.nodes.get(start_id, {})
        x, y = (P.vector(start_node['offset']) + [0, 0])[:2] if isinstance(start_node, dict) and 'offset' in start_node else (0, 0)
        meta = [('Start key', f'<code>{esc(key)}</code>'),
                ('Start node', f'<code>{esc(start_id)}</code> <span class="muted">at ({int(x)}, {int(y)}) in the editor</span>'),
                ('File', f'<code>{esc(stage["dialogue"])}</code>')]
        if sequence:
            row = sequence.get('designRow')
            meta.append(('Design row', f'{esc(row)} <span class="muted">(DESIGN.md §8)</span>' if row else '—'))
            if sequence.get('state'):
                meta.append(('Her state', esc(sequence['state'])))
        if conf.get('when'):
            meta.append(('Plays', conf['when']))
        if conf.get('next'):
            meta.append(('Then', conf['next']))
        own_list = None
        if sequence:
            list_res = f'{self.pictures}/{key}/{key}.tres'
            if list_res in self.lists.paths:
                own_list = self.lists.paths.index(list_res)
                meta.append(('Picture list', f'<code>{esc(key)}</code> <span class="muted">(list {own_list} in '
                                             f'<code>{esc(self.config["backgroundLists"])}</code>, '
                                             f'{len(self.list_pictures(own_list))} pictures)</span>'))
        meta_html = ''.join(f'<dt>{label}</dt><dd>{value}</dd>' for label, value in meta)
        context = sequence.get('context', '') if sequence else ''
        context_html = f'<p class="context">{esc(context)}</p>' if context else ''

        if routing:
            lines_html = '<p class="muted">No lines: the stage moves straight on.</p>'
        else:
            out, number = [], 0
            for r in rows:
                if r['kind'] != 'line':
                    out.append(f'<tr class="other"><td></td><td colspan="3"><code>{esc(r["id"])}</code> {esc(r["text"])}</td></tr>')
                    continue
                number += 1
                pic = self.image(*r['picture']) if r['picture'] else '<span class="muted">same picture</span>'
                placeholder = r['text'].startswith(P.PLACEHOLDER)
                out.append(f'<tr class="{"ph" if placeholder else "said"}"><td class="n">{number}<br><code>{esc(r["id"])}</code></td>'
                           f'<td class="picture">{pic}</td><td class="who">{esc(r["speaker"]) or "<span class=muted>—</span>"}</td>'
                           f'<td class="text">{esc(r["text"])}</td></tr>')
            lines_html = f'<table class="lines"><tr><th>#</th><th>Picture</th><th>Speaker</th><th>Line</th></tr>{"".join(out)}</table>'

        strip = ''
        if own_list is not None:
            used = {r['picture'][1] for r in rows if r['kind'] == 'line' and r['picture'] and r['picture'][0] == own_list}
            items = []
            for index in range(len(self.list_pictures(own_list))):
                items.append(f'<div class="strip-item{"" if index in used else " unused"}">{self.image(own_list, index, "strip")}'
                             f'<em>{"shown" if index in used else "not used yet"}</em></div>')
            unused = len(self.list_pictures(own_list)) - len(used)
            strip = (f'<details class="strip"{" open" if unused else ""}><summary>All {len(items)} pictures in its list'
                     f'{f" · {unused} not used by a line yet" if unused else ""}</summary><div class="strip-grid">{"".join(items)}</div></details>')
        title = conf.get('title') or (context.split('.')[0] if context else '')
        return (f'<article class="scene{" routing" if routing else ""}" id="{esc(anchor)}"><h3><code>{esc(key)}</code>'
                f'{f" <span>{esc(title)}</span>" if title else ""}</h3><dl>{meta_html}</dl>{context_html}{lines_html}{strip}</article>')


def write_guide(workspace):
    return Guide(workspace).write()


PAGE = '''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<style>
:root {{ --bg: #f6f4f1; --card: #fff; --ink: #1d1b19; --muted: #77716a; --line: #e4dfd8; --accent: #8a4b2a;
  --todo: #b7791f; --done: #2f7d4f; --code: #f0ebe4; --ph: #a39b92; }}
@media (prefers-color-scheme: dark) {{ :root {{ --bg: #171513; --card: #211e1b; --ink: #ece7e1; --muted: #9b948c;
  --line: #36312c; --accent: #e0a07c; --todo: #e0b050; --done: #6cc28e; --code: #2c2824; --ph: #7d766f; }} }}
* {{ box-sizing: border-box; }}
body {{ margin: 0; background: var(--bg); color: var(--ink); font: 15px/1.5 system-ui, -apple-system, "Segoe UI", sans-serif; }}
code {{ font: 13px/1.3 ui-monospace, Consolas, monospace; background: var(--code); padding: 1px 5px; border-radius: 4px; }}
.layout {{ display: grid; grid-template-columns: 330px 1fr; min-height: 100vh; }}
nav {{ position: sticky; top: 0; height: 100vh; overflow: auto; padding: 18px 14px; border-right: 1px solid var(--line); font-size: 13px; }}
nav ul {{ list-style: none; padding-left: 0; margin: 0; }} nav ul ul {{ padding-left: 6px; margin: 4px 0 14px; }}
nav > ul > li > a {{ font-weight: 700; color: var(--ink); text-decoration: none; }}
nav li li {{ margin: 3px 0; }} nav li li a {{ text-decoration: none; }}
nav li li a code {{ color: var(--accent); }} nav li li a:hover code {{ text-decoration: underline; }}
a {{ color: var(--accent); }}
.toc-title {{ display: block; color: var(--muted); font-size: 12px; margin-left: 2px; }}
main {{ padding: 24px 32px 80px; max-width: 1200px; }}
h1 {{ margin: 0 0 4px; }} .stamp {{ color: var(--muted); margin-bottom: 18px; }}
.intro {{ background: var(--card); border: 1px solid var(--line); border-radius: 10px; padding: 6px 20px 12px; margin-bottom: 18px; }}
.stage {{ margin-top: 40px; }} .stage > h2 {{ border-bottom: 2px solid var(--accent); padding-bottom: 6px; }}
.stage > h2 small {{ font-weight: 400; }}
.files {{ font-size: 13px; color: var(--muted); margin-bottom: 14px; }} .files b {{ color: var(--ink); font-weight: 600; margin-right: 4px; }}
.scene {{ background: var(--card); border: 1px solid var(--line); border-radius: 10px; padding: 14px 18px; margin: 16px 0; }}
.scene.routing {{ opacity: .75; }}
.scene h3 {{ margin: 0 0 10px; font-size: 18px; }} .scene h3 span {{ font-weight: 500; }}
dl {{ display: grid; grid-template-columns: 110px 1fr; gap: 3px 12px; margin: 0 0 10px; font-size: 14px; }}
dt {{ color: var(--muted); }} dd {{ margin: 0; }}
.context {{ border-left: 3px solid var(--accent); padding: 2px 10px; margin: 8px 0 12px; }}
.muted {{ color: var(--muted); }}
.chip {{ font-size: 11px; padding: 0 6px; border-radius: 8px; margin-left: 4px; border: 1px solid currentColor; }}
.chip.todo {{ color: var(--todo); }} .chip.done {{ color: var(--done); }} .chip.routing {{ color: var(--muted); }}
table.lines {{ width: 100%; border-collapse: collapse; font-size: 14px; }}
.lines th {{ text-align: left; color: var(--muted); font-weight: 500; border-bottom: 1px solid var(--line); padding: 4px; }}
.lines td {{ border-bottom: 1px solid var(--line); padding: 6px 4px; vertical-align: top; }}
.lines td.n {{ width: 64px; color: var(--muted); font-size: 12px; }} .lines td.picture {{ width: 150px; }}
.lines td.who {{ width: 80px; font-weight: 600; }}
.lines tr.ph td.text {{ color: var(--ph); font-style: italic; }}
.lines tr.other td {{ color: var(--muted); font-size: 12px; }}
a.pic {{ display: inline-block; text-decoration: none; color: var(--muted); font-size: 11px; }}
a.pic img {{ display: block; border-radius: 5px; background: var(--code); object-fit: cover; }}
a.pic.line img {{ width: 120px; height: 160px; }} a.pic.strip img {{ width: 96px; height: 128px; }}
a.pic.placeholder img {{ outline: 3px solid var(--todo); }}
.missing {{ color: var(--todo); }}
details.strip {{ margin-top: 10px; }} details.strip summary {{ cursor: pointer; color: var(--muted); }}
.strip-grid {{ display: flex; flex-wrap: wrap; gap: 10px; margin-top: 8px; }}
.strip-item {{ text-align: center; }} .strip-item em {{ display: block; font-size: 11px; color: var(--done); font-style: normal; }}
.strip-item.unused em {{ color: var(--todo); font-weight: 600; }} .strip-item.unused img {{ outline: 3px dashed var(--todo); }}
@media (max-width: 900px) {{ .layout {{ grid-template-columns: 1fr; }} nav {{ position: static; height: auto; border-right: 0; }} main {{ padding: 16px; }} }}
</style></head>
<body><div class="layout">
<nav><ul>{toc}</ul></nav>
<main>
<h1>{title}</h1>
<div class="stamp">Written {stamp} from the game's own files · {written} of {lines} lines written · regenerate with <code>{command}</code> (Put in the game does it too)</div>
<div class="intro">
<h2>Using this</h2>
<ul>
<li>Each card is one dialogue start. Open its <b>File</b> in Godot (double-click it in the FileSystem dock) to get the dialogue editor, and find the <b>Start node</b> by its id. The start nodes run down the left edge in the order shown here, and the editor position is given too.</li>
<li>Each line node picks its picture with a <b>background list</b> and a <b>background</b> (picture). The <b>Picture</b> column shows what each line shows now, as <i>list · picture</i>. "Same picture" means the line keeps the one before.</li>
<li>Grey italic lines are still placeholders. Write over them in Godot, or on the sort board (the preview's text box), which Put in the game carries over while the scene is untouched in Godot. Once you change a scene in Godot it is yours: Put in the game only adds pictures to its list and tells you which ones no line shows yet.</li>
<li>"Not used yet" (dashed outline) marks pictures in a scene's list that no line shows. A thick outline marks a placeholder picture.</li>
<li>Close Godot before running Put in the game.</li>
</ul>
{overview}
{open}
</div>
{body}
</main></div></body></html>
'''
