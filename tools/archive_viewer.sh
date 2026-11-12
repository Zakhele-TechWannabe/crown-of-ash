#!/usr/bin/env bash
# Open the Book of Lives: index the game's archive and serve the viewer on 127.0.0.1 only.
cd "$(dirname "$0")/.." || exit 1
python3 tools/archive_serve.py "$@" &
server=$!
trap 'kill $server 2>/dev/null' EXIT INT TERM
for _ in $(seq 40); do curl -s -o /dev/null http://127.0.0.1:8765/api/runs && break; sleep 0.25; done
xdg-open http://127.0.0.1:8765/ >/dev/null 2>&1
wait $server
