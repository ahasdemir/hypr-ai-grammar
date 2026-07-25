#!/bin/bash
# AI Grammar Fixer & Text Enhancer for Hyprland / Wayland
# Uses Google Gemini API to fix or enhance selected text in-place.
# Usage:
#   ai-grammar.sh [fix|enhance]

# Resolve real path in case script is invoked via a symlink
REAL_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$REAL_SCRIPT")" && pwd)"

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

# Determine mode: fix (default) or enhance
MODE="${1:-fix}"
MODE_LOWER=$(echo "$MODE" | tr '[:upper:]' '[:lower:]')

case "$MODE_LOWER" in
    enhance|--enhance|-e)
        MODE_NAME="Enhancer"
        ACTION_VERB="enhanced"
        TEMPERATURE=0.3
        PROMPT_INSTRUCTION="You are a context-aware text enhancer and polisher.
Analyze the context, tone, and format of the input text (e.g. casual WhatsApp message to a friend, funny banter, formal email to a coworker, technical document, social post, etc.).
Fix all spelling and grammar errors AND enhance the text by improving vocabulary, clarity, flow, and expression while perfectly matching the intended context and tone.
- If it is a casual or funny message to a friend: keep it natural, engaging, witty, and casual. Keep or adapt emojis/slang naturally.
- If it is a formal email or work message to a coworker: refine it to be clear, articulate, polite, and professional.
- If it is technical: ensure precision, clarity, and conciseness.
Return ONLY the enhanced text. Do NOT wrap in markdown code blocks, do NOT use surrounding quotes, and do NOT include any explanations or conversational filler."
        ;;
    fix|--fix|-f|*)
        MODE_NAME="Fixer"
        ACTION_VERB="corrected"
        TEMPERATURE=0.1
        PROMPT_INSTRUCTION="You are a context-aware spelling and grammar corrector.
Analyze the context, tone, and format of the input text (e.g. casual WhatsApp message to a friend, funny banter, formal email to a coworker, technical document, code comment, etc.).
Fix ONLY spelling mistakes, typos, and grammar errors.
CRITICAL: Preserve the original tone, intent, informal phrasing, slang, casing style, and emojis appropriate for that context. Do NOT rewrite or change the wording unnecessarily.
Return ONLY the corrected text. Do NOT wrap in markdown code blocks, do NOT use surrounding quotes, and do NOT include any explanations or conversational filler."
        ;;
esac

# Get selected text from primary clipboard in Wayland (wl-paste -p)
TEXT=$(timeout 1s wl-paste -p 2>/dev/null)

# Fallback to standard clipboard if primary is empty
if [ -z "$TEXT" ]; then
    TEXT=$(timeout 1s wl-paste 2>/dev/null)
fi

if [ -z "$TEXT" ]; then
    notify-send "AI $MODE_NAME" "Please select some text first." &
    exit 1
fi

# Send notification in background to avoid blocking execution
notify-send "AI $MODE_NAME" "Processing text with Gemini..." &

# Safely construct lightweight JSON payload with speed optimization params
PAYLOAD=$(jq -n \
  --arg text "$TEXT" \
  --arg instruction "$PROMPT_INSTRUCTION" \
  --argjson temp "$TEMPERATURE" '{
  contents: [{
    parts: [{
      text: ($instruction + "\n\nInput text:\n" + $text)
    }]
  }],
  generationConfig: {
    temperature: $temp,
    maxOutputTokens: 500
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
    notify-send "AI $MODE_NAME Error" "$ERR_MSG" &
    exit 1
fi

# Copy corrected text to clipboard
echo -n "$FIXED_TEXT" | wl-copy

# Micro sleep to ensure clipboard sync
sleep 0.03

# Paste corrected text using wtype
wtype -M ctrl -k v -m ctrl

notify-send "AI $MODE_NAME" "Text successfully ${ACTION_VERB}." &

