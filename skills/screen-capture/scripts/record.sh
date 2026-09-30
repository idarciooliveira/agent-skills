#!/usr/bin/env bash
# Usage: record.sh start [--all] [--fps N] [output.mp4]
#        record.sh stop
# Records the primary monitor (or whole desktop with --all) via ffmpeg gdigrab on Windows.
source "$(dirname "$0")/_common.sh"
cmd="${1:-}"; shift || true
pidf="$STATE_DIR/record.pid"; fifo="$STATE_DIR/record.fifo"; meta="$STATE_DIR/record.out"

case "$cmd" in
start)
  which=primary; fps=15
  while [ $# -gt 0 ]; do case "$1" in
    --all) which=all; shift;; --fps) fps="$2"; shift 2;; *) break;; esac; done
  out="${1:-$CAPTURE_DIR/recording-$(stamp).mp4}"
  [ -e "$pidf" ] && kill -0 "$(cat "$pidf")" 2>/dev/null && die "a recording is already running"
  ff=$(find_ffmpeg)
  read -r X Y W H <<<"$(screen_bounds "$which")"
  # libx264 needs even dimensions
  W=$((W/2*2)); H=$((H/2*2))
  tmp="/mnt/c/Windows/Temp/rec-$$.mp4"
  rm -f "$fifo"; mkfifo "$fifo"
  sleep infinity > "$fifo" & echo $! > "$STATE_DIR/holder.pid"   # keeps fifo open so ffmpeg can read 'q'
  "$ff" -y -f gdigrab -framerate "$fps" -offset_x "$X" -offset_y "$Y" -video_size "${W}x${H}" -i desktop \
    -c:v libx264 -preset ultrafast -pix_fmt yuv420p "$(winpath "$tmp")" \
    < "$fifo" > "$STATE_DIR/record.log" 2>&1 &
  echo $! > "$pidf"; echo "$tmp|$out" > "$meta"
  sleep 1.5
  kill -0 "$(cat "$pidf")" 2>/dev/null || die "ffmpeg failed to start; see $STATE_DIR/record.log"
  echo "recording started -> $out"
  ;;
stop)
  [ -e "$pidf" ] || die "no recording in progress"
  pid=$(cat "$pidf"); IFS='|' read -r tmp out < "$meta"
  echo q > "$fifo"
  for _ in $(seq 1 30); do kill -0 "$pid" 2>/dev/null || break; sleep 0.5; done
  kill -0 "$pid" 2>/dev/null && kill "$pid"
  kill "$(cat "$STATE_DIR/holder.pid")" 2>/dev/null || true
  rm -f "$pidf" "$fifo" "$STATE_DIR/holder.pid" "$meta"
  [ -s "$tmp" ] || die "recording file empty; see $STATE_DIR/record.log"
  mkdir -p "$(dirname "$out")"; mv "$tmp" "$out"
  echo "$out"
  ;;
*) die "usage: record.sh start [--all] [--fps N] [out.mp4] | stop";;
esac
