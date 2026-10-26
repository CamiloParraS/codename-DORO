#!/bin/sh
# Prepares a fresh git worktree to run the game and the suite: copies the gitignored Godot cache and baked
# clips from the main checkout, then imports. Usage: tools/worktree_setup.sh <worktree-dir>
set -e
main=$(git rev-parse --show-toplevel)
wt=${1:?usage: worktree_setup.sh <worktree-dir>}
cp -r "$main/.godot" "$wt/"
git -C "$main" ls-files --others --ignored --exclude-standard -- '*.res' | while read -r f; do
  mkdir -p "$wt/$(dirname "$f")"; cp "$main/$f" "$wt/$f"
done
godot --headless --path "$wt" --import >/dev/null 2>&1
