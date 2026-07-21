# AI Grammar & Spelling Fixer for Hyprland / Wayland

An instant, lightweight AI-powered grammar and spelling corrector for Linux Wayland desktops (specifically tailored for Hyprland). Select any text in any application, press your configured hotkey, and watch the text get corrected automatically in-place!

Powered by **Google Gemini API** (`gemini-3.1-flash-lite`) for low-latency responses.

---

## Features

- **In-place Correction**: Works across any text box, editor, browser, or terminal in Wayland.
- **Fast Response**: Uses lightweight API payload settings and `gemini-3.1-flash-lite` for near-instant execution.
- **Clipboard Fallback**: Checks primary selection first (`wl-paste -p`), then falls back to global clipboard (`wl-paste`).
- **Desktop Notifications**: Instant notifications via `notify-send` for feedback and error reporting.

---

## Prerequisites

Ensure you have the following dependencies installed on your Wayland setup:

- `wl-clipboard` (`wl-copy`, `wl-paste`)
- `wtype` (for automated keypress pasting)
- `jq` (JSON processing)
- `curl` (API request)
- `libnotify` (`notify-send`)

### Installing Dependencies (Arch / CachyOS)

```bash
sudo pacman -S wl-clipboard wtype jq curl libnotify
```

---

## Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/your-username/ai-grammar.git ~/Projects/ai-grammar
   cd ~/Projects/ai-grammar
   chmod +x ai-grammar.sh
   ```

2. **Configure Environment Variables:**

   Copy `.env.example` to `.env` and insert your Gemini API Key:

   ```bash
   cp .env.example .env
   ```

   Edit `.env`:

   ```env
   GEMINI_API_KEY="your_gemini_api_key_here"
   ```

---

## Hyprland Configuration

Add the following binding to your Hyprland configuration (`~/.config/hypr/bindings.conf` or `~/.config/hypr/hyprland.conf`):

```ini
# AI Grammar Fixer (Ctrl + Space)
bindd = CTRL, SPACE, AI Grammar Fixer (Gemini), exec, ~/.config/hypr/scripts/ai-grammar.sh
```

Restart or reload Hyprland (`hyprctl reload`).

---

## Usage

1. Highlight any text using your mouse or keyboard selection.
2. Press <kbd>Ctrl</kbd> + <kbd>Space</kbd>.
3. The selected text will be sent to Gemini, corrected, copied to the clipboard, and automatically pasted over your selection.

---

## License

This project is licensed under the [MIT License](LICENSE).
