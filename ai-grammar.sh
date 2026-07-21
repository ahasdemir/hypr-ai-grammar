#!/bin/bash
# AI Grammar & Spelling Fixer for Hyprland / Wayland
# Uses Google Gemini API to fix text selected in clipboard and paste it in-place.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables from .env if present
if [ -f "${SCRIPT_DIR}/.env" ]; then
    set -a
    source "${SCRIPT_DIR}/.env"
    set +a
elif [ -f "${HOME}/.config/ai-grammar/.env" ]; then
    set -a
    source "${HOME}/.config/ai-grammar/.env"
    set +a
fi

API_KEY="${GEMINI_API_KEY}"

if [ -z "$API_KEY" ]; then
    notify-send "AI Corrector Error" "GEMINI_API_KEY is not set in environment or .env file." &
    exit 1
fi

# Get selected text from primary clipboard in Wayland (wl-paste -p)
TEXT=$(timeout 1s wl-paste -p 2>/dev/null)

# Fallback to standard clipboard if primary is empty
if [ -z "$TEXT" ]; then
    TEXT=$(timeout 1s wl-paste 2>/dev/null)
fi

if [ -z "$TEXT" ]; then
    notify-send "AI Corrector" "Please select some text first." &
    exit 1
fi

# Send notification in background to avoid blocking execution
notify-send "AI Corrector" "Processing text with Gemini..." &

# Safely construct lightweight JSON payload with speed optimization params
PAYLOAD=$(jq -n --arg text "$TEXT" '{
  contents: [{
    parts: [{
      text: ("Fix spelling and grammar. Return ONLY corrected text, no markdown, no quotes, no explanations:\n\n" + $text)
    }]
  }],
  generationConfig: {
    temperature: 0.1,
    maxOutputTokens: 300
  }
}')

# Fast API request using gemini-3.1-flash-lite
RESPONSE=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent?key=${API_KEY}" \
  -H "Content-Type: application/json" \
  -X POST \
  -d "$PAYLOAD")

FIXED_TEXT=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text // empty')

if [ -z "$FIXED_TEXT" ] || [ "$FIXED_TEXT" == "null" ]; then
    ERR_MSG=$(echo "$RESPONSE" | jq -r '.error.message // "API did not respond."' )
    notify-send "AI Corrector Error" "$ERR_MSG" &
    exit 1
fi

# Copy corrected text to clipboard
echo -n "$FIXED_TEXT" | wl-copy

# Micro sleep to ensure clipboard sync
sleep 0.03

# Paste corrected text using wtype
wtype -M ctrl -k v -m ctrl

notify-send "AI Corrector" "Text successfully corrected." &
