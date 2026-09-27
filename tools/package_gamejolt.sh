#!/usr/bin/env sh
set -eu

version=${1:-0.8.0-alpha}
godot_bin=${GODOT_BIN:-godot}
output_root="build/gamejolt/$version"
linux_dir="$output_root/linux"
windows_dir="$output_root/windows"

if ! command -v "$godot_bin" >/dev/null 2>&1 && [ ! -x "$godot_bin" ]; then
	printf 'Nie znaleziono Godot. Ustaw GODOT_BIN=/ścieżka/do/godot.\n' >&2
	exit 2
fi
if ! command -v zip >/dev/null 2>&1; then
	printf 'Nie znaleziono programu zip.\n' >&2
	exit 2
fi

mkdir -p "$linux_dir" "$windows_dir"
"$godot_bin" --headless --path . --export-release Linux "$linux_dir/Wanderer dice farkle game.x86_64"
"$godot_bin" --headless --path . --export-release "Windows Desktop" "$windows_dir/Wanderer dice farkle game.exe"

tools/package_release.sh "$linux_dir"
tools/package_release.sh "$windows_dir"

(cd "$linux_dir" && zip -FSr "../Wanderer-dice-farkle-game-$version-linux-x86_64.zip" .)
(cd "$windows_dir" && zip -FSr "../Wanderer-dice-farkle-game-$version-windows-x86_64.zip" .)

printf 'Gotowe paczki Game Jolt:\n'
printf '  %s\n' "$output_root/Wanderer-dice-farkle-game-$version-linux-x86_64.zip"
printf '  %s\n' "$output_root/Wanderer-dice-farkle-game-$version-windows-x86_64.zip"
