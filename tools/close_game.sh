#!/usr/bin/env bash
# Close any running windowed game (leaves headless tests alone). Run before launching or screenshotting.
for p in $(pgrep -x godot); do
	case "$(tr '\0' ' ' < /proc/$p/cmdline)" in *--headless*) ;; *) kill "$p";; esac
done
