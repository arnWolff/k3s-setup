#!/bin/bash
echo "Deleteting K3s..."
## 1. Remove Nginx local reverse proxy - Windows+WSL only
if grep -qi microsoft /proc/version; then
  echo "WSL detected - Removing nginx reverse proxy"
  sudo apt remove nginx
fi
sudo k3s-uninstall.sh

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

## 3. Revome entries from ENV:PATH
# Get the current PATH
current_path="$PATH"

# Convert the PATH into an array
IFS=':' read -ra path_array <<< "$current_path"
# Filter out paths that start with /home/linuxbrew/.linuxbrew
filtered_path_array=()
for path in "${path_array[@]}"; do
  if [[ ! $path =~ ^/home/linuxbrew/.linuxbrew.* ]]; then
    filtered_path_array+=("$path")
  fi
done

# Convert the filtered array back into a PATH string
new_path=$(IFS=':'; echo "${filtered_path_array[*]}")

# Update the PATH in the config file
sed -i "s|export PATH=.*|export PATH=\"$new_path\"|" "$CONFIG_FILE"
# Update $PATH
export PATH="$new_path"

## 4. Clean up
# Delete k3s-setup folder
rm -rf $HOME/k3s/k3s-setup

# reload 
source "$CONFIG_FILE"
