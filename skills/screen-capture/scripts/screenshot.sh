#!/usr/bin/env bash
# Usage: screenshot.sh [--all] [output.png]
# Captures the primary monitor (or the whole virtual desktop with --all) and prints the PNG path.
source "$(dirname "$0")/_common.sh"
which=primary
[ "${1:-}" = "--all" ] && { which=all; shift; }
out="${1:-$CAPTURE_DIR/screenshot-$(stamp).png}"
mkdir -p "$(dirname "$out")"
read -r X Y W H <<<"$(screen_bounds "$which")"
tmp="/mnt/c/Windows/Temp/sc-$$.png"
powershell.exe -NoProfile -Command "
  Add-Type -AssemblyName System.Drawing
  \$bmp=New-Object System.Drawing.Bitmap $W,$H
  \$g=[System.Drawing.Graphics]::FromImage(\$bmp)
  \$g.CopyFromScreen($X,$Y,0,0,\$bmp.Size)
  \$bmp.Save('C:\\Windows\\Temp\\sc-$$.png',[System.Drawing.Imaging.ImageFormat]::Png)" >/dev/null
mv "$tmp" "$out"
echo "$out"
