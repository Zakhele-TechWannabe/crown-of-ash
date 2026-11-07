#!/usr/bin/env bash
cd "$(dirname "$0")" && exec godot --path . -- "$@"
