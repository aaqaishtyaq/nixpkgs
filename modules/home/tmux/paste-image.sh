#!/usr/bin/env bash
# Save an image from the macOS clipboard to a file and type its path into
# the active tmux pane. Works around Ghostty/Alacritty having no native
# image-paste support (their clipboard protocols are text-only, so there's
# no way for Cmd+V to hand a terminal raw image bytes).
set -euo pipefail

SAVE_DIR="${TMUX_PASTE_IMAGE_DIR:-$HOME/Pictures/tmux-pastes}"
RETENTION_DAYS="${TMUX_PASTE_IMAGE_RETENTION_DAYS:-7}"
mkdir -p "$SAVE_DIR"

# Prune old pastes on each run so this directory doesn't grow unbounded.
find "$SAVE_DIR" -name 'clip-*.png' -type f -mtime "+$RETENTION_DAYS" -delete

FILE="$SAVE_DIR/clip-$(date +%Y%m%d-%H%M%S).png"

result=$(osascript <<EOF
try
    set pngData to the clipboard as «class PNGf»
    set theFile to open for access (POSIX file "$FILE") with write permission
    set eof theFile to 0
    write pngData to theFile
    close access theFile
    return "ok"
on error errMsg
    return "error:" & errMsg
end try
EOF
)

if [[ "$result" != "ok" || ! -s "$FILE" ]]; then
  rm -f "$FILE"
  tmux display-message "No image on the clipboard"
  exit 0
fi

tmux send-keys -t "$TMUX_PANE" -l "$FILE"
tmux display-message "Pasted path: $FILE"
