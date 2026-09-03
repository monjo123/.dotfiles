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

zinit light jeffreytse/zsh-vi-mode

# fzf setup
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always {} || cat {}' \
    --preview-window=right:60% --bind 'ctrl-/:toggle-preview'"

export FZF_DEFAULT_OPTS="--bind 'tab:down,btab:up'"

FZF_ALT_C_COMMAND= source <(fzf --zsh)


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
    local c_files=()
    local cpp_files=()
    local py_files=()
    local scm_files=()
    local others=()

    # Detect OS-specific or available compiler binaries
    local c_compiler="gcc"
    local cpp_compiler="g++"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        command -v gcc-16 >/dev/null 2>&1 && c_compiler="gcc-16"
        command -v g++-16 >/dev/null 2>&1 && cpp_compiler="g++-16"
    fi

    for file in "$@"; do
        if [[ ! -f "$file" ]]; then
            echo "File not found: $file" >&2
            continue
        fi

        local base="${file##*/}"     # strip directory
        local ext="${base##*.}"
        [[ "$ext" == "$base" ]] && ext=""  # no extension

        case "$ext" in
            c)             c_files+=("$file") ;;
            cpp|cc|cxx)    cpp_files+=("$file") ;;
            py)            py_files+=("$file") ;;
            scm)           scm_files+=("$file") ;;
            *)             others+=("$file") ;;
        esac
    done

    if (( ${#c_files[@]} > 0 )); then
        echo "Compiling C files with $c_compiler: ${c_files[*]}"
        if "$c_compiler" "${c_files[@]}" -o "/tmp/a.out" -Wall; then
            "/tmp/a.out"
        else
            echo "C compilation failed" >&2
        fi
    fi

    if (( ${#cpp_files[@]} > 0 )); then
        echo "Compiling C++ files with $cpp_compiler: ${cpp_files[*]}"
        if "$cpp_compiler" "${cpp_files[@]}" -o "/tmp/a.out" -Wall; then
            "/tmp/a.out"
        else
            echo "C++ compilation failed" >&2
        fi
    fi

    for f in "${py_files[@]}"; do python3 "$f"; done
    for f in "${scm_files[@]}"; do guile "$f"; done
    for f in "${others[@]}"; do echo "Unsupported file type: $f"; done
}

# ==============================================================================
# 7. COMPLETION SYSTEM TWEAKS
# ==============================================================================
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

setopt CORRECT_ALL
