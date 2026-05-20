#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" -eq 0 ]; then
    SUDO=""
elif command -v sudo &>/dev/null; then
    SUDO="sudo"
else
    echo "Error: not root and sudo not available" >&2
    exit 1
fi

echo "### Base packages"
$SUDO apt update
$SUDO apt install -y --no-install-recommends \
    zsh curl wget git tig \
    ca-certificates unzip \
    build-essential make \
    ripgrep fontconfig \
    xsel tmux locales

echo "### Locale (UTF-8)"
$SUDO locale-gen en_US.UTF-8
$SUDO update-locale LANG=en_US.UTF-8
export LANG=en_US.UTF-8

# bat (Debian 12: bat / Debian 11: batcat)
$SUDO apt install -y --no-install-recommends bat 2>/dev/null \
    || $SUDO apt install -y --no-install-recommends batcat
mkdir -p ~/.local/bin
command -v bat &>/dev/null || ln -sf /usr/bin/batcat ~/.local/bin/bat

echo "### Nerd Font (Symbols Only)"
NERD_FONT_VER="3.2.1"
NERD_FONT_DIR="$HOME/.local/share/fonts/NerdFonts"
mkdir -p "$NERD_FONT_DIR"
if [ ! "$(ls -A "$NERD_FONT_DIR")" ]; then
    cd ~/Downloads
    wget --no-check-certificate \
        "https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERD_FONT_VER}/NerdFontsSymbolsOnly.tar.xz" \
        -O NerdFontsSymbolsOnly.tar.xz
    tar xf NerdFontsSymbolsOnly.tar.xz -C "$NERD_FONT_DIR"
    rm -f NerdFontsSymbolsOnly.tar.xz
    fc-cache -fv "$NERD_FONT_DIR"
fi

echo "### Neovim"
mkdir -p ~/Downloads ~/.local/bin
cd ~/Downloads
[ ! -f nvim-linux-x86_64.tar.gz ] \
    && wget --no-check-certificate https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz
tar xzf nvim-linux-x86_64.tar.gz -C ~/.local/bin
rm -f nvim-linux-x86_64.tar.gz
ln -sf ~/.local/bin/nvim-linux-x86_64/bin/nvim ~/.local/bin/nvim

echo "### tree-sitter CLI (nvim-treesitter parser build用)"
mkdir -p ~/.local/bin
cd ~/Downloads
TS_VER="0.24.6"
[ ! -f "ts.gz" ] \
    && wget --no-check-certificate \
       "https://github.com/tree-sitter/tree-sitter/releases/download/v${TS_VER}/tree-sitter-linux-x64.gz" \
       -O ts.gz
gunzip -f ts.gz
mv ts ~/.local/bin/tree-sitter
chmod +x ~/.local/bin/tree-sitter

echo "### fzf"
[ ! -d ~/.fzf ] && git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all

echo "### zinit"
export NO_INPUT=1
bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"

echo "### git-delta"
cd ~/Downloads
DELTA_VER="0.16.5"
[ ! -f "git-delta-musl_${DELTA_VER}_amd64.deb" ] \
    && wget --no-check-certificate "https://github.com/dandavison/delta/releases/download/${DELTA_VER}/git-delta-musl_${DELTA_VER}_amd64.deb"
$SUDO dpkg -i "git-delta-musl_${DELTA_VER}_amd64.deb"
rm -f "git-delta-musl_${DELTA_VER}_amd64.deb"

echo "### tmux plugin manager"
[ ! -d ~/.tmux/plugins/tpm ] \
    && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo "### nvm + Node.js LTS"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
\. "$NVM_DIR/nvm.sh"
nvm install --lts --latest-npm

echo "### Claude Code"
npm install -g @anthropic-ai/claude-code

echo "### Deploy dotfiles"
cd "$SCRIPT_DIR"
bash deploy-dotfiles

echo "### Change shell to zsh"
command -v zsh | $SUDO tee -a /etc/shells > /dev/null
chsh -s "$(command -v zsh)" 2>/dev/null || true

echo ""
echo "### Done."
echo "Restart shell or run: exec zsh"
