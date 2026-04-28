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

zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode

# fzf setup
zvm_after_init_commands+=('[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh')
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
    # Separate files by extension
    local c_files=()
    local cpp_files=()
    local py_files=()
    local scm_files=()
    local others=()

    for file in "$@"; do
        [[ ! -f "$file" ]] && echo "File not found: $file" && continue
        
        case "${file##*.}" in
            c)             c_files+=("$file") ;;
            cpp|cc|cx)     cpp_files+=("$file") ;;
            py)            py_files+=("$file") ;;
            scm)           scm_files+=("$file") ;;
            *)             others+=("$file") ;;
        esac
    done

    # Logic for C: Compile all .c files together if any exist
    if (( ${#c_files[@]} > 0 )); then
        echo "Compiling C files: ${c_files[*]}"
        gcc "${c_files[@]}" -o "/tmp/a.out" -Wall && "/tmp/a.out"
    fi

    # Logic for C++: Compile all .cpp files together
    if (( ${#cpp_files[@]} > 0 )); then
        echo "Compiling C++ files: ${cpp_files[*]}"
        g++ "${cpp_files[@]}" -o "/tmp/a.out" -Wall && "/tmp/a.out"
    fi

    # Logic for interpreted languages (run one by one)
    for f in "${py_files[@]}"; do python3 "$f"; done
    for f in "${scm_files[@]}"; do guile "$f"; done
    for f in "${others[@]}"; do echo "Unsupported file type: $f"; done
}

# ==============================================================================
# 7. COMPLETION SYSTEM TWEAKS
# ==============================================================================
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit


