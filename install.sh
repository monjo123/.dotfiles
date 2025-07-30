#!/bin/bash

# init
sudo apt upgrade -y
sudo apt-get update -y
sudo apt-get install build-essential -y
sudo apt-get install curl -y

# for zsh
ln -s ~/.dotfiles/zshrc ~/.zshrc
ln -s ~/.dotfiles/p10k.zsh ~/.p10k.zsh
sudo apt install zsh -y
bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
zsh
zinit self-update
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
sudo apt install bat -y
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# for wsl vscode
sudo apt-get install wget ca-certificates -y

ln -s ~/.dotfiles/config ~/.config

# for lazygit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit -D -t /usr/local/bin/
rm -f lazygit lazygit.tar.gz 

# for neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo apt install luarocks -y
rm -f nvim-linux-x86_64.tar.gz

# for uv
curl -LsSf https://astral.sh/uv/install.sh | sh 

# for github
git config --global user.name ocean
git config --global user.email wenocean123@gmail.com

# yazi
curl https://sh.rustup.rs -sSf | sh -s -- -y
. "$HOME/.cargo/env"
git clone https://github.com/sxyazi/yazi.git
cd yazi
cargo build --release --locked
sudo mv target/release/yazi target/release/ya /usr/local/bin/
cd ~/.dotfiles 
rm -rf yazi
sudo sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- -y

# for ripgrep
sudo apt-get install ripgrep -y

echo "$ chsh -s $(which zsh); zsh"
