#!/usr/bin/env sh
set -eu

if [ "$#" -ne 1 ]; then
	printf 'Użycie: %s KATALOG_EKSPORTU\n' "$0"
	exit 2
fi

release_dir=$1
if [ ! -d "$release_dir" ]; then
	printf 'Katalog eksportu nie istnieje: %s\n' "$release_dir"
	exit 2
fi

mkdir -p "$release_dir/assets"
cp -R assets/. "$release_dir/assets/"
mkdir -p "$release_dir/mods"
cp -R mods/. "$release_dir/mods/"
cp GODOT_COPYRIGHT.txt "$release_dir/GODOT_COPYRIGHT.txt"
cp LICENSE.md "$release_dir/LICENSE.md"
if [ -f THIRD_PARTY_ASSETS.md ]; then
	cp THIRD_PARTY_ASSETS.md "$release_dir/THIRD_PARTY_ASSETS.md"
fi
printf 'Skopiowano wymienne assety i informacje licencyjne do %s\n' "$release_dir"
