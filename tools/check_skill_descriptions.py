#!/usr/bin/env python3
"""Reject duplicated descriptions or shared runs longer than five words."""
import json
import pathlib
import re

root = pathlib.Path(__file__).resolve().parents[1]
domains = json.loads((root / 'data/skills/domains.json').read_text())
records = [(d['id'], d['description']) for d in domains]
for d in domains:
    records.extend((x['id'], x['description']) for x in json.loads(
        (root / 'data/skills/domains' / (d['id'] + '.json')).read_text())['disciplines'])
seen = {}
phrases = {}
failures = []
for key, description in records:
    words = re.findall(r"[a-z]+(?:'[a-z]+)?", description.lower())
    normalized = ' '.join(words)
    if normalized in seen:
        failures.append(f'{key}: same description as {seen[normalized]}')
    seen[normalized] = key
    for index in range(len(words) - 5):
        phrase = tuple(words[index:index + 6])
        if phrase in phrases:
            failures.append(f'{key} / {phrases[phrase]}: {" ".join(phrase)}')
        phrases[phrase] = key
assert len(domains) == 100 and len(records) == 1600
if failures:
    raise SystemExit('\n'.join(failures))
print('PASS descriptions: 100 domains, 1500 disciplines, no duplicate or shared six-word phrase')
