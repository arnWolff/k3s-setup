#!/bin/bash
# Bootstrap a K3s based Kubernetes setup with helm, metrics, nginx ingress, cert-manager


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

# Add Homebrew and k9s to PATH
export PATH="/home/linuxbrew/.linuxbrew/bin:\$PATH"
export PATH="/home/linuxbrew/.linuxbrew/sbin:\$PATH"
export PATH="/home/linuxbrew/.linuxbrew/opt/k9s/bin:\$PATH"

k3s-setup() {
  case "\$1" in
    stop)
      k3s-killall.sh
      ;;
    start)
      sudo service k3s start
      ;;
    uninstall)
      $HOME/k3s/k3s-setup/uninstall.sh
      ;;
    install)
      mkdir -p \$HOME/k3s && cd \$HOME/k3s
      if [ ! -d "./k3s-setup" ]; then
        git clone https://github.com/arnWolff/k3s-setup.git
      fi
      cd ./k3s-setup && ./k3s-setup.sh
      chmod 700 uninstall.sh
      ;;
    *)
      echo "Usage: k3s-setup {stop|start|uninstall|install}"
      ;;
  esac
}
############################ -= K3s END =- ############################

EOL

fi

## 9. Run command to reload configuration file

source "$CONFIG_FILE"

echo "*** Finished! Enjoy your K3s environment. ***"
