#!/usr/bin/env python3
"""Serial headless checks; terminate only processes this runner creates."""
import glob
import json
import os
from pathlib import Path
import subprocess
import sys
import threading

out = Path('out/phase2')
out.mkdir(parents=True, exist_ok=True)
results = []
# Includes tools/test_session_compiler.gd, tools/test_cultivator_lab.gd
# and tools/test_qi_condensation.gd;
# keep all Godot invocations serial, including the full-world prepared cohort.
files = sys.argv[1:] or sorted(glob.glob('tools/test_*.gd'))
for file in files:
    log = out / (Path(file).name + '.log')
    failed = False
    with log.open('w') as stream:
        process = subprocess.Popen(['godot', '--headless', '--path', '.', '-s', file],
                                   env={**os.environ, 'XDG_DATA_HOME': '/tmp/crown-godot'},
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        # The century-long kinship fixture now also replays 36,500 authoritative qi dates.
        timeout = 900 if Path(file).name in {"test_family.gd", "test_fifty.gd", "test_session_compiler.gd", "bench_qi_live.gd", "test_qi_condensation.gd"} else 300
        deadline = threading.Timer(timeout, process.kill)
        deadline.start()
        for line in process.stdout:
            stream.write(line)
            stream.flush()
            if any(x in line for x in ['SCRIPT ERROR', 'FAIL', 'Assertion failed']):
                failed = True
                process.terminate()
        status = process.wait()
        deadline.cancel()
    passed = status == 0 and not failed
    results.append({'test': file, 'pass': passed, 'exit': status})
    (out / ('tests.json' if not sys.argv[1:] else 'selected_tests.json')).write_text(json.dumps(results, indent=2))
    print(file, 'PASS' if passed else 'FAIL', flush=True)
