"""Takes the snapshot of dialogue files the tests read line by line (helpers.FIXTURES), from the
project into tests/fixtures/. Run it once, or again on purpose when a test needs newer content:

    python -P -E tooling/dialogue_editor/tests/make_fixtures.py

The tests then keep meaning the same thing however much is written with the editor meanwhile.
It only reads the project.
"""
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import helpers as H  # noqa: E402


def main():
    for res in H.FIXTURES:
        source = H.REAL_PROJECT / res.removeprefix('res://')
        target = H.FIXTURES_DIR / res.removeprefix('res://')
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
        print(f'{res}  {target.stat().st_size // 1024} KB')


if __name__ == '__main__':
    main()
