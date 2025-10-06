# init
pacman -Syu
pacman -S python3 zsh vim git openssh gcc neovim fzf bat zoxide

# for zsh
ln -s ~/.dotfiles/zshrc ~/.zshrc
ln -s ~/.dotfiles/p10k.zsh ~/.p10k.zsh

echo "chsh -s $(which zsh); zsh"
        
