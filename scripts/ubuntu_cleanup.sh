#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR_DEFAULT="$HOME/apps/ultimate-ki"
PROJECT_DIR="${PROJECT_DIR:-$PROJECT_DIR_DEFAULT}"

echo "Ubuntu cleanup helper"
echo "Project directory: $PROJECT_DIR"
echo
echo "This script can:"
echo "1. stop and remove this compose project"
echo "2. remove this project directory"
echo "3. remove old OpenClaw and Ollama user data"
echo "4. optionally remove /opt/openclaw"
echo
read -r -p "Continue? Type yes: " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
  echo "Aborted."
  exit 1
fi

if [[ -d "$PROJECT_DIR" && -f "$PROJECT_DIR/docker-compose.prod.yml" ]]; then
  echo "Stopping compose project in $PROJECT_DIR ..."
  (
    cd "$PROJECT_DIR"
    docker compose -f docker-compose.prod.yml down -v --remove-orphans || true
  )
else
  echo "Project directory not found or no docker-compose.prod.yml present, skipping compose shutdown."
fi

read -r -p "Remove project directory '$PROJECT_DIR'? Type yes: " REMOVE_PROJECT
if [[ "$REMOVE_PROJECT" == "yes" && -d "$PROJECT_DIR" ]]; then
  rm -rf "$PROJECT_DIR"
  echo "Removed $PROJECT_DIR"
fi

read -r -p "Remove ~/.openclaw and ~/.ollama? Type yes: " REMOVE_USER_DATA
if [[ "$REMOVE_USER_DATA" == "yes" ]]; then
  rm -rf "$HOME/.openclaw" "$HOME/.ollama" "$HOME/openclaw" "$HOME/openclaw_ultimate_setup"
  echo "Removed user-level OpenClaw/Ollama directories"
fi

read -r -p "Remove /opt/openclaw with sudo? Type yes: " REMOVE_OPT
if [[ "$REMOVE_OPT" == "yes" ]]; then
  sudo rm -rf /opt/openclaw
  echo "Removed /opt/openclaw"
fi

echo "Done."
