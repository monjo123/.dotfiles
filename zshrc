# ==============================================================================
# 1. INSTANT PROMPT (Must stay at the absolute top)
# ==============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==============================================================================
# 2. ZINIT BOOTSTRAP
# ==============================================================================
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# Load essential annexes immediately
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

# ==============================================================================
# 3. THEME (Immediate load to prevent flickering)
# ==============================================================================
zinit ice depth=1; zinit light romkatv/powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ==============================================================================
# 4. TURBO PLUGINS (The "Fast" Section)
# ==============================================================================

# Plugins with background loading
zinit wait'0' lucid for \
    atinit"zicompinit; zicdreplay" \
        zsh-users/zsh-completions \
    blockf \
        zsh-users/zsh-autosuggestions \
    atload"_zsh_autosuggest_start" \
        zdharma-continuum/fast-syntax-highlighting \
    Aloxaf/fzf-tab \
    djui/alias-tips

zinit snippet OMZ::lib/history.zsh
# Snippets with background loading (Fixed Syntax)
zinit wait'0' lucid for \
    OMZ::lib/theme-and-appearance.zsh

# ==============================================================================
# 5. ENVIRONMENT & TOOL INIT
# ==============================================================================
export EDITOR="nvim"

# fzf setup
source <(fzf --zsh)
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always {} || cat {}' \
  --preview-window=right:60% --bind 'ctrl-/:toggle-preview'"

bindkey -r '\ec'
export FZF_DEFAULT_OPTS="--bind 'tab:down,btab:up'"

# zoxide setup
eval "$(zoxide init --cmd cd zsh)"

# ==============================================================================
# 6. ALIASES & FUNCTIONS
# ==============================================================================
alias ls='ls --color=auto'
alias ll='ls -al'
# alias lg='lazygit'
alias ng='nvim -c "let g:neogit_mode = 1 | Neogit"'

run() {
    for file in "$@"; do
        [[ ! -f "$file" ]] && echo "File not found: $file" && continue
        case "${file##*.}" in
            c)         gcc "$file" -o "/tmp/a.out" -Wall && "/tmp/a.out" ;;
            cpp|cc|cx) g++ "$file" -o "/tmp/a.out" -Wall && "/tmp/a.out" ;;
            py)        python3 "$file" ;;
            scm)       guile "$file" ;;
            *)         echo "Unsupported file type: $file" ;;
        esac
    done
}

# ==============================================================================
# 7. COMPLETION SYSTEM TWEAKS
# ==============================================================================
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# enable vi-mode
bindkey -v
bindkey '^?' backward-delete-char

