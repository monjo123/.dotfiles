#!/bin/bash

# init
sudo apt upgrade -y
sudo apt-get update -y
sudo apt-get install curl -y

# for zsh
ln -s ~/.dotfiles/zshrc ~/.zshrc
ln -s ~/.dotfiles/p10k.zsh ~/.p10k.zsh
sudo apt install zsh -y
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
sudo apt install bat -y
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# for wsl vscode
sudo apt-get install wget ca-certificates -y

# for uv
curl -LsSf https://astral.sh/uv/install.sh | sh 

# for github
git config --global user.name ocean
git config --global user.email wenocean123@gmail.com

# for zoxide
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

echo "chsh -s $(which zsh); zsh"
        