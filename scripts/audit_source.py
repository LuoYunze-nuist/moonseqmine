#!/usr/bin/env python3
"""Inspect handwritten production files and required deliverable paths."""
from pathlib import Path
import json
root = Path(__file__).resolve().parents[1]
files = []
for path in sorted((root/'src').glob('*.mbt')):
    if path.name.endswith(('_test.mbt','_wbtest.mbt')):
        continue
    text = path.read_text(encoding='utf-8-sig')
    if any(mark in text for mark in ('TODO','FIXME','IMPLEMENT_ME')):
        raise SystemExit('Unfinished implementation marker in '+path.name)
    files.append({'path':path.relative_to(root).as_posix(),'physical_lines':len(text.splitlines())})
lines = sum(item['physical_lines'] for item in files)
if lines < 1500:
    raise SystemExit('Insufficient handwritten production MoonBit lines')
required = ['README.md','LICENSE','THIRD_PARTY.md','AI_USAGE.md','CHANGELOG.md',
            'docs/competition/duplicate-check.md','src/pkg.generated.mbti']
for name in required:
    if not (root/name).is_file():raise SystemExit('Missing '+name)
for example in ('journeys','services','symbols'):
    if not (root/'src'/'examples'/example/'main.mbt').is_file():raise SystemExit('Missing example')
print(json.dumps({'production_physical_lines':lines,'method':'root src/*.mbt only; excludes test, generated API, example and reference vectors; physical lines include ordinary blanks/comments','files':files},ensure_ascii=False,indent=2))
