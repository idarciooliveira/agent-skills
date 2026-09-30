#!/usr/bin/env bash
# Shared helpers for screen-capture scripts (WSL2 -> Windows host).
set -euo pipefail

CAPTURE_DIR="${CAPTURE_DIR:-/tmp/captures}"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/screen-capture"
mkdir -p "$CAPTURE_DIR" "$STATE_DIR"

die() { echo "error: $*" >&2; exit 1; }

find_ffmpeg() {
  local f
  f=$(ls /mnt/c/Users/*/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg*/*/bin/ffmpeg.exe 2>/dev/null | head -1 || true)
  [ -n "$f" ] || f=$(command -v ffmpeg.exe || true)
  [ -n "$f" ] || die "ffmpeg.exe not found on Windows. Run: powershell.exe -Command 'winget install Gyan.FFmpeg'"
  echo "$f"
}

# Prints "X Y W H" for the primary monitor, or the whole virtual desktop if $1 = all.
screen_bounds() {
  local which="${1:-primary}"
  powershell.exe -NoProfile -Command "
    Add-Type -AssemblyName System.Windows.Forms
    if ('$which' -eq 'all') { \$b=[System.Windows.Forms.SystemInformation]::VirtualScreen }
    else { \$b=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds }
    \"\$(\$b.X) \$(\$b.Y) \$(\$b.Width) \$(\$b.Height)\"" | tr -d '\r'
}

winpath() { wslpath -w "$1"; }
stamp() { date +%Y%m%d-%H%M%S; }
