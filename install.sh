#!/usr/bin/env bash
# SAP-SKILLS installer for Linux / macOS / Git Bash
# Usage:
#   ./install.sh                    # Install all skills to .claude/skills (project)
#   ./install.sh --global           # Install to ~/.claude/skills (all projects)
#   ./install.sh sap-rap-comprehensive sap-cap-advanced  # Install specific skills
#   ./install.sh --global sap-rap-comprehensive          # Combine flags

set -euo pipefail

GLOBAL=0
SKILLS=()

for arg in "$@"; do
  case "$arg" in
    --global|-g)
      GLOBAL=1
      ;;
    --help|-h)
      echo "SAP-SKILLS installer"
      echo ""
      echo "Usage:"
      echo "  $0                              Install all skills to .claude/skills"
      echo "  $0 --global                     Install all skills to ~/.claude/skills"
      echo "  $0 skill1 skill2                Install only the named skills"
      echo "  $0 --global skill1              Install named skills globally"
      exit 0
      ;;
    *)
      SKILLS+=("$arg")
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/skills"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: skills directory not found at $SOURCE_DIR" >&2
  exit 1
fi

if [ "$GLOBAL" -eq 1 ]; then
  TARGET="$HOME/.claude/skills"
else
  TARGET="$(pwd)/.claude/skills"
fi

mkdir -p "$TARGET"

if [ "${#SKILLS[@]}" -eq 0 ]; then
  echo "Installing all SAP skills to $TARGET"
  cp -r "$SOURCE_DIR"/* "$TARGET/"
  COUNT=$(find "$SOURCE_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l)
  echo "Installed $COUNT skills."
else
  for skill in "${SKILLS[@]}"; do
    if [ ! -d "$SOURCE_DIR/$skill" ]; then
      echo "Warning: skill '$skill' not found in $SOURCE_DIR" >&2
      continue
    fi
    cp -r "$SOURCE_DIR/$skill" "$TARGET/"
    echo "Installed: $skill"
  done
fi

echo ""
echo "Done. Restart Claude Code for the skills to take effect."
