#!/bin/bash

# Install a global 'goose-cloud' command that can be run from any directory.
# It sets up Ollama env vars, activates the venv, and launches Goose
# in the current working directory.

set -e

GREEN='\033[0;32m'
NC='\033[0m'

WRAPPER="$HOME/.local/bin/goose-cloud"
mkdir -p "$HOME/.local/bin"

cat > "$WRAPPER" << 'WRAPPER_EOF'
#!/bin/bash

# goose-cloud — Launch Goose with Ollama cloud models from any directory.
# Installed by goose-ollama/scripts/install-global.sh

# Detect Ollama URL
OLLAMA_URL="http://localhost:11434"
if ! curl -sf "${OLLAMA_URL}/api/tags" &>/dev/null; then
    WIN_HOST_IP=$(ip route show default 2>/dev/null | awk '{print $3}')
    if [ -n "$WIN_HOST_IP" ] && curl -sf "http://${WIN_HOST_IP}:11434/api/tags" &>/dev/null; then
        OLLAMA_URL="http://${WIN_HOST_IP}:11434"
    else
        echo "Ollama is not reachable at localhost:11434"
        if command -v ollama &>/dev/null; then
            echo "Starting Ollama..."
            ollama serve &
            sleep 3
        else
            echo "Start Ollama on Windows or install it: curl -fsSL https://ollama.com/install.sh | sh"
            exit 1
        fi
    fi
fi

# Activate Python venv (for skills that need packages)
VENV_DIR="$HOME/.local/share/goose-ollama/venv"
if [ -f "$VENV_DIR/bin/activate" ]; then
    source "$VENV_DIR/bin/activate"
fi

# Set Goose environment
export GOOSE_PROVIDER=ollama
if [ "$OLLAMA_URL" != "http://localhost:11434" ]; then
    export OLLAMA_HOST="$OLLAMA_URL"
fi
CONFIGURED_MODEL=$(grep "^GOOSE_MODEL:" ~/.config/goose/config.yaml 2>/dev/null | awk '{print $2}')
export GOOSE_MODEL="${CONFIGURED_MODEL:-qwen3.5:cloud}"

# Performance
export GOOSE_REQUEST_TIMEOUT=300
export OLLAMA_KEEP_ALIVE=300
export OLLAMA_CONTEXT_LENGTH=32768

# Find Goose binary
GOOSE_CMD=""
if [ -x "$HOME/.local/bin/goose" ]; then
    GOOSE_CMD="$HOME/.local/bin/goose"
elif command -v goose &>/dev/null; then
    GOOSE_CMD="$(command -v goose)"
else
    echo "Goose not found. Run setup.sh first."
    exit 1
fi

# Show info
echo "Goose Cloud | model: $GOOSE_MODEL | ollama: $OLLAMA_URL"
echo "Directory: $(pwd)"
echo ""

# Launch Goose in the current directory — pass any extra args through
exec "$GOOSE_CMD" session "$@"
WRAPPER_EOF

chmod +x "$WRAPPER"

# Ensure ~/.local/bin is in PATH
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$rc" ] && ! grep -q 'HOME/.local/bin' "$rc"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
        fi
    done
fi

echo -e "${GREEN}Installed:${NC} $WRAPPER"
echo ""
echo "Usage (from any directory):"
echo "  goose-cloud                    # start a new session"
echo "  goose-cloud --name my-project  # named session"
echo ""
echo "Restart your shell or run: export PATH=\"\$HOME/.local/bin:\$PATH\""
