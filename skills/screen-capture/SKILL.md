---
name: screen-capture
description: >-
  Takes screenshots and records the screen video from WSL2 Ubuntu on a Windows
  host, then extracts frames so the agent can inspect the result. Use when the
  user asks to record the screen, take a screenshot, capture the desktop, show
  proof or evidence that a task works, or verify a UI change visually at the
  end of a task. Works for native Windows apps and browsers alike via
  PowerShell and ffmpeg gdigrab. WSL2 only.
---

# Screen Capture (WSL2 → Windows host)

Captures the Windows desktop from inside WSL2 through Windows interop. Linux-side
tools (grim, scrot, wf-recorder) do not work here: WSLg's compositor exposes no
screencopy protocol and X11 grabs only see WSLg windows, not the Windows desktop.

Scripts live in `scripts/` next to this file. Run them by that path.
Output goes to `/tmp/captures` by default (override with `CAPTURE_DIR`).

## Privacy — read first

Desktop capture records **everything on screen**: other windows, chats, recent
documents, notifications. Before capturing:

- Only capture when the user asked for it or the task is explicitly visual verification.
- Prefer the primary monitor (the default). Use `--all` only when asked.
- Tell the user what you captured and where it is saved.
- Do not upload, commit, or share captures unless asked.

## Prerequisites

- WSL2 with Windows interop enabled (`powershell.exe` runs from WSL).
- Windows ffmpeg, needed only for recording and frame extraction:
  `powershell.exe -NoProfile -Command 'winget install Gyan.FFmpeg'`
  The scripts find `ffmpeg.exe` by path, so no shell restart is needed.

Screenshots need only PowerShell, no ffmpeg.

## Screenshot

```bash
scripts/screenshot.sh [--all] [output.png]
```

Prints the PNG path. View it with the Read tool to check the result.

## Screen recording

```bash
scripts/record.sh start [--all] [--fps N] [output.mp4]   # default 15 fps, primary monitor
# ...do the thing being demonstrated...
scripts/record.sh stop                                    # prints the MP4 path
```

- Always run `stop`, even if the task fails, or ffmpeg keeps running.
- Only one recording at a time. `start` refuses if one is active.
- Timing is approximate: a 6 s recording came out around 7.7 s because of ffmpeg
  startup and shutdown.
- Start the recording, then trigger the action (open the page, run the command),
  then stop. Add a short `sleep` before `stop` so the final state is on screen.

## Inspecting a recording

The agent cannot play video. Extract frames and read them:

```bash
scripts/frames.sh /tmp/captures/recording-*.mp4 6   # 6 evenly spaced 1280px PNGs
```

Prints frame paths (in `<video>-frames/`). Read a few with the Read tool to confirm
the expected states appear, and say honestly which frames you checked.

## Showing the result to the user

Give the absolute paths, and embed them in markdown when the client renders media:

```markdown
![Screenshot](/tmp/captures/screenshot-….png)
![Recording](/tmp/captures/recording-….mp4)
```

To open the folder in Windows: `explorer.exe "$(wslpath -w /tmp/captures)"`.

## Verification workflow (end of a task)

1. Get the app into the state to be checked (dev server running, window visible).
2. `record.sh start`, perform the flow, `record.sh stop`.
3. `screenshot.sh` of the final state.
4. `frames.sh` on the recording and Read a few frames.
5. Report what the evidence shows, including anything that looks wrong. State that
   you inspected frames, not the whole video.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `ffmpeg.exe not found` | Run the winget install above |
| `ffmpeg failed to start` | Read `$XDG_RUNTIME_DIR/screen-capture/record.log` |
| `a recording is already running` | Run `record.sh stop` first |
| Black or partial capture | Target window is minimized or on another monitor; try `--all` |
| `powershell.exe: command not found` | Interop disabled; enable in `/etc/wsl.conf` (`[interop] enabled=true`) and restart WSL |

Recording writes to `C:\Windows\Temp` first, then moves the file, because ffmpeg
cannot reliably write MP4 straight to a `\\wsl.localhost` path. A crash mid-recording
can leave a stray `rec-*.mp4` there.
