sudo pacman -Syu

sudo pacman -S python3 zsh vim git openssh gcc neovim fzf bat zoxide yi

# for zsh
mkdir -p ~/.config
ln -s ~/.dotfiles/config/* ~/.config/
ln -s ~/.dotfiles/zshrc ~/.zshrc
ln -s ~/.dotfiles/p10k.zsh ~/.p10k.zsh

# install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

echo "chsh -s $(which zsh); zsh"
        
