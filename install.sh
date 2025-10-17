sudo pacman -Syu

sudo pacman -S python3 zsh vim git openssh gcc neovim fzf bat zoxide

# install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# for zsh
mkdir -p ~/.config
ln -s ~/.dotfiles/config/* ~/.config/
ln -s ~/.dotfiles/zshrc ~/.zshrc
ln -s ~/.dotfiles/p10k.zsh ~/.p10k.zsh

echo "chsh -s $(which zsh); zsh"
        
