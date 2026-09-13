#!/bin/zsh
set -eu
cd -- "$(dirname -- "$0")"
if command -v godot >/dev/null 2>&1; then
	exec godot --path client
elif [[ -x /opt/homebrew/bin/godot ]]; then
	exec /opt/homebrew/bin/godot --path client
else
	print "Godot 4 is required. Open client/project.godot in Godot to play."
	exit 1
fi
