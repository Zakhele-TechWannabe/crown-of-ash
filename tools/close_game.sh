#!/usr/bin/env bash
# Ask windowed games to save and quit; headless tests are left alone.
set -u
pids=()
for p in $(pgrep -x godot); do
    [[ -r /proc/$p/cmdline ]] || continue
    mapfile -d '' -t args < "/proc/$p/cmdline"
    [[ " ${args[*]} " == *" --headless "* ]] && continue
    project=$(readlink "/proc/$p/cwd")
    for ((i=0; i<${#args[@]}; i++)); do
        if [[ ${args[i]} == --path ]]; then
            project=${args[i+1]}
            [[ $project = /* ]] || project="$(readlink "/proc/$p/cwd")/$project"
        fi
    done
    name=$(sed -n 's/^config\/name="\(.*\)"/\1/p' "$project/project.godot" 2>/dev/null)
    [[ -n $name ]] || continue
    data_home=${XDG_DATA_HOME:-$HOME/.local/share}
    # Each process may have its own XDG data directory.
    while IFS= read -r -d '' entry; do
        [[ $entry == XDG_DATA_HOME=* ]] && data_home=${entry#XDG_DATA_HOME=}
    done < "/proc/$p/environ"
    user_dir="$data_home/godot/app_userdata/$name"
    mkdir -p "$user_dir"
    touch "$user_dir/quit.$p.request"
    pids+=("$p")
done
for ((second=0; second<10; second++)); do
    alive=0
    for p in "${pids[@]}"; do kill -0 "$p" 2>/dev/null && alive=1; done
    (( alive == 0 )) && exit 0
    sleep 1
done
for p in "${pids[@]}"; do
    kill -0 "$p" 2>/dev/null && kill "$p"
done
