#!/bin/bash

set -e  # Exit on any error

# Update & install base tools
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y build-essential curl wget ca-certificates git

# Set up config directories
mkdir -p ~/.config

# Zsh setup
ln -sf ~/.dotfiles/zshrc ~/.zshrc
ln -sf ~/.dotfiles/p10k.zsh ~/.p10k.zsh
sudo apt install -y zsh

# Zinit (Zsh plugin manager)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
zsh
source ~/.zshrc 
zinit self-update

# fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
yes | ~/.fzf/install

# Other tools
sudo apt install -y bat ripgrep luarocks

# Zoxide
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# Lazygit
ln -sf ~/.dotfiles/config/lazygit ~/.config/lazygit
LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '"tag_name": *"v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit -D -t /usr/local/bin/
rm -f lazygit lazygit.tar.gz

# Neovim
ln -sf ~/.dotfiles/config/nvim ~/.config/nvim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
rm -f nvim-linux-x86_64.tar.gz

# UV (Rust-based package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Rust & Yazi
if ! command -v rustup >/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
. "$HOME/.cargo/env"
rustup update
ln -sf ~/.dotfiles/config/yazi ~/.config/yazi

git clone https://github.com/sxyazi/yazi.git
cd yazi
cargo build --release --locked
sudo mv target/release/yazi target/release/ya /usr/local/bin/
cd ..
rm -rf yazi

# Starship prompt
curl -fsSL https://starship.rs/install.sh | sudo sh -s -- -y

# for github 
git config --global user.name ocean 
git config --global user.email wenocean123@gmail.com

echo "$ chsh -s $(which zsh); zsh"
