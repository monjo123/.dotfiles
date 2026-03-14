# for zsh
mkdir -p ~/.config
ln -s ~/.dotfiles/config/* ~/.config/
ln -s ~/.dotfiles/zshrc ~/.zshrc
ln -s ~/.dotfiles/p10k.zsh ~/.p10k.zsh

echo "chsh -s $(which zsh); zsh"
        
