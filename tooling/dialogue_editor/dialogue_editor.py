"""A dialogue editor for the game in the browser: every start key as a script of lines and signals,
with its pictures, saved straight into the game's DialogueData files.

    python -P -E tooling/dialogue_editor/dialogue_editor.py [--project PATH] [--image-root PATH]
           [--port 8766] [--no-open] [--backups PATH] [--cache PATH] [--config PATH] [--done PATH]

-P stops Python importing files from the current folder. The server listens on 127.0.0.1 only.
Defaults: the Godot project this tool sits in, its pictures, port 8766, backups in this folder's
backups/ and thumbnails in cache/, the starts marked done in done.json here. --port 0 takes any free port. dialogues.py has the rules for
what is editable and how a save goes in.

The API the page uses (JSON; paths are res:// paths):
    GET  /api/files                      every dialogue file, with counts, stages and its start keys
    GET  /api/file?path=res://...        one file: characters, picture lists, the signals the game
                                         knows, and the starts with their items
    GET  /api/search?q=...[&path=][&placeholder=1]
    GET  /api/versions                   {path: version} so the page notices outside changes
    GET  /api/status                     whether Godot is running, whether its addon is patched
    POST /api/save                       {path, changes: [...], confirmGodot?} (Content-Type: application/json)
    GET  /api/done                       {done: {path: {start key: when marked}}}
    POST /api/done                       {path, key, done: true|false}: marks a start done or not; every mark back
    GET  /api/matches                    {picks: {situation: {list, picture}}}: the picture each poker match opens on
    POST /api/matches                    {set: {situation: {list, picture} or null}}: sets or clears picks; every pick back
    GET  /api/wallpapers                 {picks: {picture file: {list, picture}}, seeded: {lists file: when}}: the
                                         pictures picked as wallpapers (the Gallery's Wallpapers)
    POST /api/wallpapers                 {set: {picture file: {list, picture} or null}, seed?: lists file}: picks or
                                         unpicks; seed marks the lists whose video pictures were pre-picked; all back
    POST /api/reveal                     {path, play?}: shows a picture or video of the project in its folder
                                         (File Explorer, the file selected), or with play opens it in its usual program
    GET  /img?path=res://...[&w=N]       a picture, or a cached thumbnail at most N wide
"""
import argparse
import json
import os
import socket
import sys
import time
import traceback
import urllib.parse
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

TOOL_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOL_DIR))  # -P keeps the tool's own folder off the import path
import dialogues as D  # noqa: E402

DEFAULT_PORT = 8766
MAX_BODY = 32 * 1024 * 1024


class Server(ThreadingHTTPServer):
    """Windows lets a second program bind a port that's in use when SO_REUSEADDR is set (Python's
    default for HTTP servers), so two editors would share a port silently. Exclusive use instead,
    so a busy port is noticed."""
    daemon_threads = True
    allow_reuse_address = os.name != 'nt'

    def server_bind(self):
        if os.name == 'nt' and hasattr(socket, 'SO_EXCLUSIVEADDRUSE'):
            self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
        super().server_bind()

    def handle_error(self, request, client_address):
        # The browser drops picture requests it no longer needs (a page left, a list scrolled
        # past): nothing went wrong, so say nothing.
        if isinstance(sys.exc_info()[1], ConnectionError):
            return
        super().handle_error(request, client_address)


def make_handler(editor):
    class Handler(BaseHTTPRequestHandler):
        protocol_version = 'HTTP/1.1'

        def send(self, status, body, content_type='application/json; charset=utf-8', cache=None):
            if not isinstance(body, bytes):
                body = json.dumps(body, ensure_ascii=False).encode('utf-8')
            self.send_response(status)
            self.send_header('Content-Type', content_type)
            self.send_header('Content-Length', str(len(body)))
            self.send_header('Cache-Control', cache or 'no-store')
            self.send_header('X-Content-Type-Options', 'nosniff')
            self.end_headers()
            self.wfile.write(body)

        def local_host(self):
            """Only requests addressed to this machine by name or number: a page elsewhere that
            points its own domain at 127.0.0.1 (DNS rebinding) gets nothing."""
            host = (self.headers.get('Host') or '').rsplit(':', 1)[0].strip('[]').lower()
            return host in ('127.0.0.1', 'localhost', '::1')

        def query(self):
            parsed = urllib.parse.urlparse(self.path)
            return parsed.path, {k: v[-1] for k, v in urllib.parse.parse_qs(parsed.query, keep_blank_values=True).items()}

        def fail(self, error):
            self.send(error.status, error.body())

        def do_GET(self):
            if not self.local_host():
                return self.send(403, {'error': 'this server answers 127.0.0.1 and localhost only', 'code': 'host'})
            path, params = self.query()
            try:
                if path in ('/', '/index.html'):
                    self.send(200, (TOOL_DIR / 'editor.html').read_bytes(), 'text/html; charset=utf-8')
                elif path == '/api/files':
                    self.send(200, editor.files())
                elif path == '/api/file':
                    self.send(200, editor.file(params.get('path')))
                elif path == '/api/search':
                    self.send(200, editor.search(params.get('q', ''), params.get('path') or None,
                                                 params.get('placeholder') in ('1', 'true', 'yes')))
                elif path == '/api/versions':
                    self.send(200, editor.versions())
                elif path == '/api/status':
                    self.send(200, editor.status())
                elif path == '/api/done':
                    self.send(200, editor.done())
                elif path == '/api/matches':
                    self.send(200, editor.match_pictures())
                elif path == '/api/wallpapers':
                    self.send(200, editor.wallpapers())
                elif path == '/img':
                    width = params.get('w')
                    if width not in (None, ''):
                        try:
                            width = int(width)
                        except ValueError:
                            raise D.EditorError('w must be a number', 400, code='bad-request')
                    else:
                        width = None
                    data, content_type = editor.image(params.get('path'), width)
                    # Picture URLs carry the file's date (v=...), so a cached copy is never stale.
                    self.send(200, data, content_type, cache='private, max-age=604800' if params.get('v') else 'no-cache')
                elif path == '/favicon.ico':
                    self.send(204, b'', 'image/x-icon')
                else:
                    self.send(404, {'error': 'not found', 'code': 'not-found'})
            except D.EditorError as e:
                self.fail(e)
            except ConnectionError:
                pass  # the browser went away mid-answer
            except Exception as e:  # a bug: say so on the page and in the console
                traceback.print_exc()
                self.send(500, {'error': f'the editor hit a problem: {e}', 'code': 'internal'})

        def do_POST(self):
            if not self.local_host():
                return self.send(403, {'error': 'this server answers 127.0.0.1 and localhost only', 'code': 'host'})
            path, _ = self.query()
            # A refusal before the body is read leaves it in the connection: close it after answering.
            keep_open, self.close_connection = not self.close_connection, True
            try:
                # A page from elsewhere can't send JSON here without asking first (CORS), and this
                # server never says yes; the Origin check also turns away pages on other local ports.
                origin = self.headers.get('Origin')
                if origin:
                    parsed = urllib.parse.urlparse(origin)
                    if parsed.hostname not in ('127.0.0.1', 'localhost', '::1') or parsed.port != self.server.server_address[1]:
                        raise D.EditorError('saves come from the editor page only', 403, code='origin')
                if (self.headers.get('Content-Type') or '').split(';')[0].strip().lower() != 'application/json':
                    raise D.EditorError('send JSON (Content-Type: application/json)', 415, code='bad-request')
                length = (self.headers.get('Content-Length') or '0').strip()
                if not length.isascii() or not length.isdigit():
                    # A bad length would be a 500 at int(), and a negative one would wait for the
                    # whole stream to end.
                    raise D.EditorError('the request needs a Content-Length', 400, code='bad-request')
                length = int(length)
                if length > MAX_BODY:
                    raise D.EditorError('that request is too big', 413, code='bad-request')
                raw = self.rfile.read(length)
                self.close_connection = not keep_open
                try:
                    body = json.loads(raw.decode('utf-8'))
                except (ValueError, UnicodeDecodeError) as e:
                    raise D.EditorError(f'the request is not JSON: {e}', 400, code='bad-json')
                if path == '/api/save':
                    if not isinstance(body, dict):
                        raise D.EditorError('send an object: {path, changes}', 400, code='bad-request')
                    self.send(200, editor.save(body.get('path'), body.get('changes'), bool(body.get('confirmGodot'))))
                elif path == '/api/done':
                    if not isinstance(body, dict):
                        raise D.EditorError('send an object: {path, key, done}', 400, code='bad-request')
                    self.send(200, editor.mark_done(body.get('path'), body.get('key'), body.get('done')))
                elif path == '/api/matches':
                    if not isinstance(body, dict):
                        raise D.EditorError('send an object: {set: {...}}', 400, code='bad-request')
                    self.send(200, editor.set_match_pictures(body.get('set')))
                elif path == '/api/wallpapers':
                    if not isinstance(body, dict):
                        raise D.EditorError('send an object: {set: {...}, seed}', 400, code='bad-request')
                    self.send(200, editor.set_wallpapers(body.get('set'), body.get('seed')))
                elif path == '/api/reveal':
                    if not isinstance(body, dict):
                        raise D.EditorError('send an object: {path, play}', 400, code='bad-request')
                    self.send(200, editor.reveal(body.get('path'), body.get('play') is True))
                else:
                    self.send(404, {'error': 'not found', 'code': 'not-found'})
            except D.EditorError as e:
                self.fail(e)
            except ConnectionError:
                pass
            except Exception as e:
                traceback.print_exc()
                self.send(500, {'error': f'the editor hit a problem: {e}', 'code': 'internal'})

        def log_message(self, *args):
            pass

    return Handler


def find_project():
    for folder in TOOL_DIR.parents:
        if (folder / 'project.godot').exists():
            return folder
    sys.exit('error: this tool is not inside a Godot project: give --project')


def make_server(editor, port):
    return Server(('127.0.0.1', port), make_handler(editor))


def serve(args):
    project = Path(args.project).resolve() if args.project else find_project()
    editor = D.Editor(project, args.image_root, args.backups, args.cache, args.config, args.done)
    try:
        server = make_server(editor, args.port)
    except OSError:
        url = f'http://127.0.0.1:{args.port}/'
        print(f'port {args.port} is already in use: the dialogue editor is probably open already. '
              + (url if args.no_open else f'Opening {url}'))
        if not args.no_open:
            webbrowser.open(url)
        return
    url = f'http://127.0.0.1:{server.server_address[1]}/'
    started = time.perf_counter()
    count = editor.warm()
    print(f'read {count} dialogue files in {time.perf_counter() - started:.1f}s from {project}')
    print(f'dialogue editor: {url}  (Ctrl+C to stop)', flush=True)
    if not args.no_open:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    parser.add_argument('--project', help='the Godot project (default: the one this tool is in)')
    parser.add_argument('--image-root', help='a project to read pictures from (default: --project)')
    parser.add_argument('--port', type=int, default=DEFAULT_PORT, help='0 for any free port')
    parser.add_argument('--no-open', action='store_true', help="don't open a browser")
    parser.add_argument('--backups', help='where old copies of saved files go (default: backups/ here)')
    parser.add_argument('--cache', help='where thumbnails go (default: cache/ here)')
    parser.add_argument('--config', help='the config file naming scene notes (default: config.json here)')
    parser.add_argument('--done', help='where the starts marked done are kept (default: done.json here); '
                                       'the match pictures go beside it, in match_pictures.json')
    try:
        serve(parser.parse_args())
    except D.EditorError as e:
        sys.exit(f'error: {e}')


if __name__ == '__main__':
    main()
