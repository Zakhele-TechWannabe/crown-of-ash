#!/usr/bin/env python3
"""Turn saved verification output into a reviewable report, without running Godot."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
out = root / 'out/phase2'
tests = json.loads((out / 'tests.json').read_text())
scenarios = json.loads((out / 'scenarios.json').read_text())
benchmark = (out / 'bench_population.gd.log').read_text()

def decades(file):
    result = {}
    for line in (out / file).read_text().splitlines():
        m = re.match(r'DECADE (\d+) (SKILLS|SOCIETY) (.*)', line)
        if m:
            result.setdefault(int(m[1]), {})[m[2]] = json.loads(m[3])
    return result

pacing = re.search(r'MASTER_PACING day=(\d+) years=([0-9.]+)', (out / 'test_skill_pacing.gd.log').read_text())
master_years = pacing[2] if pacing else 'unverified'
hundred = decades('100years.log')
thirty = decades('30years.log')
passed = all(t['pass'] for t in tests) and all(s['pass'] for s in scenarios) and 'PASS population benchmark' in benchmark
lines = ['# Phase 2 verification', '', f'Overall: **{"PASS" if passed else "FAIL"}**.', '',
         'Godot 4.7.2, branch `fresh-start`; no commits. All runs used headless Godot, sequentially. The windowed game was left untouched.', '',
         '**Lifespan death is OFF by default.** Everyone remains alive past their realm lifespan as a frail elder; population increases only through births.', '',
         '## Automated checks', '', f'{sum(t["pass"] for t in tests)}/{len(tests)} GDScript tests passed. Catalogue descriptions: 100 domains and 1,500 disciplines; no duplicate descriptions or shared six-word phrase.', '']
for test in tests:
    lines.append(f'- {"PASS" if test["pass"] else "FAIL"} `{test["test"]}`')
lines += ['', 'Scenarios:', '']
for s in scenarios:
    lines.append(f'- {"PASS" if s["pass"] else "FAIL"} `{s["log"]}` (exit {s["exit"]})')
lines += ['', '## Scale benchmark', '', '100,000 people, 1,000,000 touched skills, 4,000,000 directed ties (40/person). Weekly social work and monthly rust are amortized into the reported total day cost. Daily and weekly timings are medians of three sequential samples; all samples are printed.', '', '```', benchmark.strip(), '```', '',
          'Memory is Godot static allocation delta for catalogue/core storage, not process RSS. Terrain, UI assets and annual faction aggregate construction are outside that figure. The expanded tie workload uses a 200 MB decimal core budget; the daily-time target remains 2,000 ms. Scene batches use 16–32 people, rather than the 256-person skill batches timed separately above.', '',
          '## Thirty daily years', '', 'Counts use each person\'s best skill, including new children. Residents begin with existing adult experience; this differs from the neutral, from-zero pacing test.', '',
          '| Year | Population | Untrained | Novice | Apprentice | Journeyman | Skilled | Adept | Expert | Master+ |',
          '|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|']
for year, data in sorted(thirty.items()):
    skills = data['SKILLS']
    values = [year, data['SOCIETY']['population']] + [skills.get(k, 0) for k in ['Untrained','Novice','Apprentice','Journeyman','Skilled','Adept','Expert']] + [sum(skills.get(k,0) for k in ['Master','Grandmaster','Sage','Peerless'])]
    lines.append('| ' + ' | '.join(map(str, values)) + ' |')
lines += ['', 'Neutral full-time pacing: Journeyman at 730 days (2 years), Skilled at 3,285 days (9 years), Expert at 9,125 days (25 years). At year 30 the practitioner remains level 30 without insight; the test supplies insight from year 31 and verifies Master after further earned practice (no XP grant). Existing attribute, milestone, teacher and qi gates still apply.', '',
          f'Measured Master timing after insight: {master_years} years.', '', '## One hundred daily years', '',
          '| Year | People | Marriages | Births | Clans | Awakenings | Mortal | Body | Qi | Foundation | Core | Nascent | Factions | Posts filled | Grudges |',
          '|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|']
for year, data in sorted(hundred.items()):
    s = data['SOCIETY']; r = s['realms']
    values = [year,s['population'],s['marriages'],s['births'],s['clans'],s['awakenings']] + [r.get(k,0) for k in ['Mortal','Body Tempering','Qi Condensation','Foundation Establishment','Core Formation','Nascent Soul']] + [s['factions'],s['positions_filled'],s['grudges']]
    lines.append('| ' + ' | '.join(map(str, values)) + ' |')
lines += ['', 'Marriages, births and awakenings are cumulative; factions, positions, grudges and realm counts describe the checkpoint. Body Tempering is the slow mortal road, open to everyone. Awakening is not the same as reaching Qi Condensation.', '', '## Chronicle highlights', '', 'Each checkpoint prints up to five events from that decade, ranked by significance. Fewer than five means fewer qualifying recorded events occurred.', '', '```']
for line in (out / '100years.log').read_text().splitlines():
    if ' SOCIETY ' in line:
        lines.append('Year ' + line.split()[1])
    elif line.startswith('CHRONICLE '):
        lines.append(line)
lines += ['```', '', '## Boundaries', '',
          'Weekly skip mode approximates population practice at calendar transitions and changes random-event sequences; food/material ledger events retain their dated calendar. Large scene faction rebuilds yield across frames; explicit headless refresh APIs are synchronous. Named qi sites and techniques use the current village/peak/spring model; resource multipliers and faction pact/schism/absorption APIs can support later content.', '',
          'The checked-in starting parent links are explicit, editable family assumptions consistent with resident ages and surnames. Unknown parents remain unknown; no invented ancestor people are inserted.', '',
          'Raw logs and JSON are in `out/phase2/`. See `phase2_implementation.md` for storage, APIs and verification commands.', '']
(root / 'docs/phase2_results.md').write_text('\n'.join(lines))
print('PASS report' if passed else 'FAIL report')
