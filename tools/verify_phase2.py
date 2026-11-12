#!/usr/bin/env python3
"""Complete serial verification; only headless child processes are launched."""
import json
import os
from pathlib import Path
import subprocess
import threading
import time

subprocess.run(['python3', 'tools/run_phase2_checks.py'], check=True)
subprocess.run(['python3', 'tools/run_phase2_checks.py', 'tools/bench_population.gd'], check=True)
subprocess.run(['python3', 'tools/check_skill_descriptions.py'], check=True)
out = Path('out/phase2')
runs = [
    ('100years.log', ['--headless-sim', '--years=100']),
    ('30years.log', ['--headless-sim', '--years=30']),
    ('startup_people.log', ["--goto=Servants' Village", '--day=200', '--ledger=people', '--person=0']),
    ('startup_society.log', ["--goto=Servants' Village", '--day=200', '--ledger=society']),
    ('skip_cli.log', ['--skip-years=1']),
]
results = []
for name, arguments in runs:
    command = ['godot', '--headless', '--path', '.']
    if name.startswith('startup'):
        command += ['--quit-after', '120']
    command += ['--'] + arguments
    failed = False
    began = time.monotonic()
    with (out / name).open('w') as log:
        process = subprocess.Popen(command,
                                   env={**os.environ, 'XDG_DATA_HOME': '/tmp/crown-godot'},
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        deadline = threading.Timer(1500, process.kill)
        deadline.start()
        for line in process.stdout:
            log.write(line)
            log.flush()
            if ' SOCIETY ' in line:
                print(name, line.strip(), flush=True)
            if any(word in line for word in ['SCRIPT ERROR', 'FAIL', 'Assertion failed']):
                failed = True
                process.terminate()
        status = process.wait()
        deadline.cancel()
    passed = status == 0 and not failed
    results.append({'log': name, 'pass': passed, 'exit': status, 'seconds': round(time.monotonic() - began, 2)})
    (out / 'scenarios.json').write_text(json.dumps(results, indent=2))
    print(name, 'PASS' if passed else 'FAIL', flush=True)
subprocess.run(['python3', 'tools/report_phase2.py'], check=True)
