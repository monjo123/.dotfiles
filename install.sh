#!/bin/bash

# init
sudo apt update
sudo apt-get update
sudo apt upgrade
sudo apt-get install build-essential
sudo apt-get install curl

# for zsh
cp zshrc ~/.zshrc
cp p10k.zsh ~/.p10k.zsh
sudo apt install zsh
sudo chsh -s $(which zsh)
bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
zinit self-update
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
sudo apt install bat

# for wsl vscode
sudo apt-get install wget ca-certificates

# for lazygit
cp -r config/lazygit ~/.config/
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit -D -t /usr/local/bin/

# for neovim
cp -r config/nvim ~/.config
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo apt install luarocks

# for ripgrep
sudo apt-get install ripgrep

# for fd-find
sudo apt install fd-find

# for node.js
sudo apt-get install nodejs
sudo apt install npm

# for uv
curl -LsSf https://astral.sh/uv/install.sh | sh


