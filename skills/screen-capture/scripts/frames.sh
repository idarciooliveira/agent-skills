#!/usr/bin/env bash
# Usage: frames.sh video.mp4 [count=6]
# Extracts evenly spaced PNG frames so a recording can be inspected with the Read tool. Prints frame paths.
source "$(dirname "$0")/_common.sh"
vid="${1:?video path required}"; n="${2:-6}"
ff=$(find_ffmpeg)
dir="${vid%.*}-frames"; mkdir -p "$dir"; rm -f "$dir"/frame-*.png
probe="${ff%ffmpeg.exe}ffprobe.exe"
dur=$("$probe" -v error -show_entries format=duration -of csv=p=0 "$(winpath "$vid")" | tr -d '\r')
rate=$(awk -v n="$n" -v d="$dur" 'BEGIN{printf "%.6f", n/(d>0?d:1)}')
"$ff" -y -v error -i "$(winpath "$vid")" -vf "fps=$rate,scale=1280:-2" -frames:v "$n" "$(winpath "$dir")\\frame-%02d.png"
ls "$dir"/frame-*.png
