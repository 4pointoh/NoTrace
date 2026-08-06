"""One-time migration: convert serialized Background.images texture references
(eagerly loaded ExtResource) into Background.imagePath strings (loaded on
demand at runtime by BackgroundCache).

Pure text transform so that everything else in each .tres file — UIDs,
formatting, property order — is preserved byte-for-byte. Idempotent.

Run from the project root:  python tooling/migrate_background_textures.py
"""
import re
import sys
from pathlib import Path

EXT_RE = re.compile(
    r'\[ext_resource type="Texture2D"(?: uid="[^"]*")? path="([^"]+)" id="([^"]+)"\]\r?\n'
)
IMAGES_RE = re.compile(r'^images = ExtResource\("([^"]+)"\)$', re.MULTILINE)
LOAD_STEPS_RE = re.compile(r'(\[gd_resource[^\]]*? load_steps=)(\d+)')

total_files = 0
total_replaced = 0
total_ext_removed = 0
warnings = []

for tres in sorted(Path('data').rglob('*.tres')) + sorted(Path('resources').rglob('*.tres')):
    raw = tres.read_bytes()
    text = raw.decode('utf-8')
    if 'images = ExtResource(' not in text:
        continue

    # id -> texture path, from Texture2D ext_resource declarations
    tex_by_id = {m.group(2): m.group(1) for m in EXT_RE.finditer(text)}

    replaced = 0
    def replace_images(m):
        global replaced
        ext_id = m.group(1)
        if ext_id not in tex_by_id:
            warnings.append(f'{tres}: images = ExtResource("{ext_id}") is not a Texture2D ext_resource; left as-is')
            return m.group(0)
        replaced += 1
        return f'imagePath = "{tex_by_id[ext_id]}"'

    new_text = IMAGES_RE.sub(replace_images, text)
    if replaced == 0:
        continue

    # Drop Texture2D ext_resource lines that nothing references anymore.
    removed = 0
    def drop_unreferenced(m):
        global removed
        if f'ExtResource("{m.group(2)}")' in new_text:
            return m.group(0)
        removed += 1
        return ''

    new_text2 = EXT_RE.sub(drop_unreferenced, new_text)

    # Keep the header's load_steps consistent with the removed declarations.
    if removed:
        def fix_load_steps(m):
            return f'{m.group(1)}{int(m.group(2)) - removed}'
        new_text2, n = LOAD_STEPS_RE.subn(fix_load_steps, new_text2, count=1)
        if n != 1:
            warnings.append(f'{tres}: could not adjust load_steps')

    tres.write_bytes(new_text2.encode('utf-8'))
    total_files += 1
    total_replaced += replaced
    total_ext_removed += removed
    print(f'{tres}: {replaced} background(s) migrated, {removed} texture ref(s) removed')

print(f'--- done: {total_replaced} backgrounds in {total_files} files, '
      f'{total_ext_removed} texture ext_resources removed ---')
for w in warnings:
    print('WARNING:', w, file=sys.stderr)
sys.exit(1 if warnings else 0)
