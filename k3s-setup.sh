#!/bin/bash
# Bootstrap a K3s based Kubernetes setup with helm, metrics, ingress, cert-manager and K8s dashboard

## 1. Install/Upgrade Homebrew
if ! command -v brew &> /dev/null; then
  echo "Homebrew not found - Installing Homebrew..."
  export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
  export PATH="/home/linuxbrew/.linuxbrew/sbin:$PATH"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"  
else
  echo "Homebrew found - Upgrading Homebrew..."
  brew update && brew upgrade
fi

## 2. Install/Upgrade Helm Charts
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

## 3. Bootstrap K3s
cd k3s
./prepare-k3s.sh

## 4. Prepare cluster services
cd ../cluster-system
./cluster-setup.sh

## 5. Prepare Nginx as local reverse proxy between localhost and WSL - Windows+WSL only
if grep -qi microsoft /proc/version; then
  echo "WSL detected - Installing nginx as reverse proxy"
  cd ../nginx
  ./prepare-nginx.sh
  cd ..
else
  echo "Native Linux - No need to install nginx"
fi

## 6. Install/Upgrade k9s
echo "Installing/Upgrading k9s..."
brew install gcc || brew upgrade gcc && brew install derailed/k9s/k9s || brew upgrade derailed/k9s/k9s

## 7. Append lines to ~/.bashrc or ~/.zshrc
if [ -f "$HOME/.bashrc" ]; then
  CONFIG_FILE="$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
  CONFIG_FILE="$HOME/.zshrc"
fi

if [ -n "$CONFIG_FILE" ]; then
  cat >> "$CONFIG_FILE" << EOL

############################ -= K3s SETUP =- ############################
export KUBECONFIG=~/.kube/k3s.yaml
alias k=kubectl
complete -F __start_kubectl k
source <(kubectl completion bash)

k3s() {
  case "\$1" in
    stop)
      k3s-killall.sh
      ;;
    start)
      sudo service k3s start
      ;;
    uninstall)
      rm -rf $HOME/k3s/k3s-setup && sudo k3s-uninstall.sh && sudo apt remove nginx
      ;;
    install)
      mkdir -p \$HOME/k3s && cd \$HOME/k3s
      if [ ! -d "./k3s-setup" ]; then
        git clone https://github.com/arnWolff/k3s-setup.git
      fi
      cd ./k3s-setup && ./k3s-setup.sh
      ;;
    *)
      echo "Usage: k3s {stop|start|uninstall|install}"
      ;;
  esac
}
############################ -= K3s END =- ############################
EOL
  source "$CONFIG_FILE"
fi

## 8. Add Homebrew and k9s to PATH
if [ -n "$CONFIG_FILE" ]; then
  echo 'export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"' >> "$CONFIG_FILE"
  echo 'export PATH="/home/linuxbrew/.linuxbrew/sbin:$PATH"' >> "$CONFIG_FILE"
  echo 'export PATH="/home/linuxbrew/.linuxbrew/opt/k9s/bin:$PATH"' >> "$CONFIG_FILE"
  source "$CONFIG_FILE"
fi

## 9. Run command to reload configuration file
if [ -n "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
fi

echo "*** Finished! Enjoy your local K8s environment. ***"
