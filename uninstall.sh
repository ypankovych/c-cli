#!/usr/bin/env bash
set -e

INSTALL_DIR="$HOME/.c-cli"

echo "Uninstalling c-cli..."

# Remove source lines from rc files
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$rc" ]; then
    sed -i.bak '/\.c-cli\/c\.sh/d' "$rc"
    sed -i.bak '/# c-cli/d' "$rc"
    rm -f "${rc}.bak"
    echo "Cleaned $rc"
  fi
done

# Remove oh-my-zsh plugin symlink
rm -rf "$HOME/.oh-my-zsh/custom/plugins/c-cli" 2>/dev/null

# Remove install dir
rm -rf "$INSTALL_DIR"

# Remove history
rm -f "$HOME/.c_history"

echo "Done. Restart your shell."
