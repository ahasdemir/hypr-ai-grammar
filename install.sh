#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.config/hypr/scripts"

mkdir -p "$TARGET_DIR"

if [ ! -f "${SCRIPT_DIR}/.env" ] && [ -f "${SCRIPT_DIR}/.env.example" ]; then
    echo "Creating .env from .env.example..."
    cp "${SCRIPT_DIR}/.env.example" "${SCRIPT_DIR}/.env"
fi

echo "Setting executable permission on ai-grammar.sh..."
chmod +x "${SCRIPT_DIR}/ai-grammar.sh"

echo "Linking ai-grammar.sh to ${TARGET_DIR}/ai-grammar.sh..."
ln -sf "${SCRIPT_DIR}/ai-grammar.sh" "${TARGET_DIR}/ai-grammar.sh"

echo "Installation complete!"
echo "Make sure to set your GEMINI_API_KEY in ${SCRIPT_DIR}/.env"
