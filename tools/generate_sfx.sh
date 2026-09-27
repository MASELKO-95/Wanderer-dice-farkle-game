#!/usr/bin/env sh
set -eu

output_dir=${1:-assets/sounds}
mkdir -p "$output_dir"

make_sound() {
	name=$1
	duration=$2
	expression=$3
	ffmpeg -hide_banner -loglevel error -y \
		-f lavfi -i "aevalsrc=${expression}:s=44100:d=${duration}" \
		-c:a libvorbis -q:a 5 "$output_dir/$name.ogg"
}

make_sound ui_click 0.07 "0.22*sin(2*PI*920*t)*exp(-42*t)"
make_sound ui_hover 0.09 "0.12*sin(2*PI*560*t)*exp(-30*t)"
make_sound die_select 0.13 "0.18*(sin(2*PI*680*t)+0.35*sin(2*PI*1020*t))*exp(-24*t)"
make_sound coin_bank 0.42 "0.16*(sin(2*PI*880*t)+sin(2*PI*1320*t))*exp(-7*t)+0.10*sin(2*PI*1760*t)*exp(-13*t)"
make_sound farkle 0.72 "0.20*sin(2*PI*(250-125*t)*t)*exp(-1.8*t)+0.08*sin(2*PI*(126-45*t)*t)*exp(-2.2*t)"
make_sound win_fanfare 1.45 "0.10*(sin(2*PI*(523+136*gt(t\,0.34)+125*gt(t\,0.68)+261*gt(t\,1.02))*t)+0.55*sin(2*PI*(659+125*gt(t\,0.34)+136*gt(t\,0.68)+261*gt(t\,1.02))*t))*exp(-0.28*t)"

ffmpeg -hide_banner -loglevel error -y \
	-f lavfi -i "anoisesrc=color=brown:amplitude=0.28:sample_rate=44100:duration=0.78" \
	-af "highpass=f=110,lowpass=f=2400,tremolo=f=18:d=0.65,afade=t=out:st=0.55:d=0.23" \
	-c:a libvorbis -q:a 5 "$output_dir/dice_roll.ogg"

printf 'Wygenerowano 7 oryginalnych efektów w %s\n' "$output_dir"
