#!/usr/bin/env bash
set -e

REPO="https://github.com/ypankovych/c-cli.git"
INSTALL_DIR="$HOME/.c-cli"

echo "Installing c-cli..."

# Check for claude
if ! command -v claude >/dev/null 2>&1; then
  echo "Error: 'claude' (Claude Code CLI) is required but not installed."
  echo "Install it from: https://docs.anthropic.com/en/docs/claude-code"
  exit 1
fi

# Clone or update
if [ -d "$INSTALL_DIR" ]; then
  echo "Updating existing installation..."
  git -C "$INSTALL_DIR" pull --quiet
else
  git clone --quiet "$REPO" "$INSTALL_DIR"
fi

SOURCE_LINE='[ -f "$HOME/.c-cli/c.sh" ] && source "$HOME/.c-cli/c.sh"'

# Detect shell and rc file
install_to_rc() {
  local rc="$1"
  if [ -f "$rc" ] && grep -qF ".c-cli/c.sh" "$rc"; then
    echo "Already in $rc"
  else
    echo "" >> "$rc"
    echo "# c-cli — natural language shell commands" >> "$rc"
    echo "$SOURCE_LINE" >> "$rc"
    echo "Added to $rc"
  fi
}

# Oh-my-zsh plugin (if available)
if [ -d "$HOME/.oh-my-zsh/custom/plugins" ]; then
  PLUGIN_DIR="$HOME/.oh-my-zsh/custom/plugins/c-cli"
  mkdir -p "$PLUGIN_DIR"
  ln -sf "$INSTALL_DIR/c.sh" "$PLUGIN_DIR/c-cli.plugin.zsh"
  echo "Oh-my-zsh plugin linked. Add 'c-cli' to your plugins=(...) in .zshrc"
  echo "  OR keep the source line below — both work, pick one."
fi

# Add source line to shell rc
if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
  install_to_rc "$HOME/.zshrc"
fi

if [ -n "$BASH_VERSION" ] || [ -f "$HOME/.bashrc" ]; then
  install_to_rc "$HOME/.bashrc"
fi

echo ""
echo "Done! Restart your shell or run:"
echo "  source ~/.c-cli/c.sh"
echo ""
echo "Usage:"
echo "  c  <request>   translate and execute"
echo "  cx <request>   translate and print only"
echo "  cc <request>   translate and copy to clipboard"
