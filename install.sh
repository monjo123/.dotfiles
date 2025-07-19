#!/bin/bash

# init
sudo apt update
sudo apt-get update
sudo apt upgrade
sudo apt-get install build-essential
sudo apt-get install curl

# for zsh
ln -s ~/.dotfiles/zshrc ~/.zshrc
ln -s ~/.dotfiles/p10k.zsh ~/.p10k.zsh
sudo apt install zsh
bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
zinit self-update
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
sudo apt install bat
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# for wsl vscode
sudo apt-get install wget ca-certificates

mkdir ~/.config

# for lazygit
ln -s ~/.dotfiles/config/lazygit ~/.config/lazygit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit -D -t /usr/local/bin/
rm -f lazygit lazygit.tar.gz 

# for neovim
ln -s ~/.dotfiles/config/nvim ~/.config/nvim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo apt install luarocks
rm -f nvim-linux-x86_64.tar.gz

# for uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# for github
git config --global user.name ocean
git config --global user.email wenocean123@gmail.com

echo "$ chsh -s $(which zsh); zsh"

# yazi
ln -s ~/.dotfiles/cargo ~/.cargo
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup update
git clone https://github.com/sxyazi/yazi.git
cd yazi
cargo build --release --locked
