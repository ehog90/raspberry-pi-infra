#!/bin/bash
set -euo pipefail

info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; }

if [[ $EUID -eq 0 ]]; then
    error "Do not run this script as root. Run as your regular user."
    exit 1
fi

# ============================================================
# 1. Oh My Bash
# ============================================================
info "Installing Oh My Bash..."

if [[ -d "$HOME/.oh-my-bash" ]]; then
    warn "Oh My Bash is already installed at ~/.oh-my-bash — skipping."
else
    # The official installer tries to start a new shell; we use --unattended
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended
    info "Oh My Bash installed successfully."
fi

# Set the agnoster theme
BASHRC="$HOME/.bashrc"
if grep -q '^OSH_THEME=' "$BASHRC" 2>/dev/null; then
    info "Setting Oh My Bash theme to agnoster..."
    sed -i 's/^OSH_THEME=.*/OSH_THEME="agnoster"/' "$BASHRC"
else
    warn "OSH_THEME line not found in $BASHRC — appending agnoster theme."
    echo 'OSH_THEME="agnoster"' >> "$BASHRC"
fi

# ============================================================
# 2. NVM (Node Version Manager)
# ============================================================
NVM_VERSION="v0.40.1"

info "Installing NVM ${NVM_VERSION}..."

if [[ -d "$HOME/.nvm" ]]; then
    warn "NVM directory already exists at ~/.nvm — reinstalling/updating."
fi

curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash

# Load NVM into the current session
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

info "Installing latest Node.js LTS..."
nvm install --lts
nvm alias default 'lts/*'

# ============================================================
# 3. Ensure .bashrc sources NVM (Oh My Bash may overwrite it)
# ============================================================
BASHRC="$HOME/.bashrc"
NVM_BLOCK='# --- NVM ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'

if ! grep -q 'NVM_DIR' "$BASHRC" 2>/dev/null; then
    info "Appending NVM loader to $BASHRC..."
    printf '\n%s\n' "$NVM_BLOCK" >> "$BASHRC"
else
    info "NVM already referenced in $BASHRC — skipping."
fi

# ============================================================
# Done
# ============================================================
info "Shell environment setup complete!"
echo
echo "  Oh My Bash : ~/.oh-my-bash"
echo "  NVM        : ${NVM_DIR}"
echo "  Node       : $(node -v)"
echo "  NPM        : $(npm -v)"
echo
info "Open a new terminal or run: source ~/.bashrc"
