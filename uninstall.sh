#!/bin/bash
## 1. Remove Nginx local reverse proxy - Windows+WSL only
if grep -qi microsoft /proc/version; then
  echo "WSL detected - Removing nginx reverse proxy"
  sudo apt remove nginx
fi
rm -rf $HOME/k3s/k3s-setup && sudo k3s-uninstall.sh

## 2. Uninstall Brew (this will remove K9s too)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"

## 3. Delete k3s-setup entries from $CONFIG_FILE
if [ -f "$HOME/.bashrc" ]; then
  CONFIG_FILE="$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
  CONFIG_FILE="$HOME/.zshrc"
fi
# Delete lines between and including the markers
sed -i '/^############################ -= K3s SETUP =- ############################$/,/^############################ -= K3s END =- ############################$/d' "$CONFIG_FILE"

