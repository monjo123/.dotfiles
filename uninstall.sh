#!/usr/bin/env bash
# Undo this dotfiles setup. No installation/uninstallation is run by sourcing.
set -Eeuo pipefail
UNINSTALLER_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Reuse platform detection and user-directory conventions, never installer main().
# shellcheck source=install.sh
. "$UNINSTALLER_DIR/install.sh"
# Bash 3 on macOS treats some empty-array expansions as unset.
set +u

un_usage() {
    cat <<'EOF'
用法：bash ~/.dotfiles/uninstall.sh [--dry-run] [--platform mac|arch|ubuntu]

移除本套設定的連結、還原安裝前的設定備份與 Git 身分，解除安裝有紀錄的新增工具。
Ubuntu 全程只處理使用者目錄，不使用 sudo / apt。
執行前會列出範圍並要求輸入 UNINSTALL 確認。
若要連同未有紀錄的舊工具清單一起移除，可在確認時輸入 LEGACY。
個人資料與手動安裝的目錄會先移到回收備份；保留 repository、安裝紀錄與原始備份。
EOF
}

un_init() {
    UN_DRY_RUN=0 UN_LEGACY=0 UN_FAILURES=0 UN_KEEP_ZSH=0 UN_KEEP_GIT=0
    UN_PLATFORM=auto
    while (($#)); do
        case "$1" in
            --dry-run) UN_DRY_RUN=1 ;;
            --platform)
                [[ $# -ge 2 ]] || die '--platform 需要 mac、arch 或 ubuntu。'
                UN_PLATFORM=$2; shift
                case "$UN_PLATFORM" in mac|arch|ubuntu) ;; *) die '不支援的平台。' ;; esac ;;
            -h|--help) un_usage; exit 0 ;;
            *) die "不支援的選項：$1" ;;
        esac
        shift
    done
    [[ "$UN_PLATFORM" != auto ]] || UN_PLATFORM=$(host_platform) || die '無法辨識平台。'
    PLATFORM=$UN_PLATFORM
    init_paths
    UN_REPO=$UNINSTALLER_DIR
    UN_HOME=$SETUP_USER_HOME
    UN_OWN="$STATE_DIR/ownership/$UN_PLATFORM"
    UN_RECOVERY="$STATE_DIR/uninstall-backups/$RUN_ID"
    UN_BREW='' UN_TMP='' UN_LOCK=''
    UN_LINKS=() UN_PATHS=() UN_OLD_PATHS=() UN_PACKAGES=() UN_OLD_PACKAGES=()
    UN_NVM_DIR=$SETUP_NVM_DIR
    UN_CARGO_DIR=$SETUP_CARGO_DIR
    UN_RUSTUP_DIR=${RUSTUP_HOME:-$UN_HOME/.rustup}
    if [[ "$UN_PLATFORM" = mac ]]; then
        if command -v brew >/dev/null 2>&1; then UN_BREW=$(command -v brew)
        elif [[ -x /opt/homebrew/bin/brew ]]; then UN_BREW=/opt/homebrew/bin/brew
        elif [[ -x /usr/local/bin/brew ]]; then UN_BREW=/usr/local/bin/brew; fi
    fi
}

un_exists() { [[ -e "$1" || -L "$1" ]]; }

un_safe_path() {
    local path=$1 parent physical_home physical_parent
    [[ "$path" = "$UN_HOME/"* && "$path" != *'/../'* && "$path" != *'/./'* && "$path" != */.. && "$path" != */. ]] || return 1
    [[ "$path" != *$'\n'* && "$path" != *$'\t'* ]] || return 1
    [[ "$UN_REPO/" != "$path/"* && "$STATE_DIR/" != "$path/"* ]] || return 1
    parent=$(dirname "$path")
    [[ -d "$parent" && -d "$UN_HOME" ]] || return 1
    physical_home=$(cd -P "$UN_HOME" && pwd)
    physical_parent=$(cd -P "$parent" && pwd)
    [[ "$physical_parent" = "$physical_home" || "$physical_parent" = "$physical_home/"* ]]
}

un_allowed_data() {
    case "$1" in
        "$DATA_DIR"/*|"$BIN_DIR/uv"|"$BIN_DIR/uvx"|"$UN_NVM_DIR"|"$UN_NVM_DIR"/versions/node/v*|"$UN_CARGO_DIR"|"$UN_RUSTUP_DIR"|\
        "${XDG_DATA_HOME:-$UN_HOME/.local/share}/zinit"|"${XDG_CACHE_HOME:-$UN_HOME/.cache}/zinit"|\
        "${XDG_DATA_HOME:-$UN_HOME/.local/share}/nvim"|"${XDG_STATE_HOME:-$UN_HOME/.local/state}/nvim"|\
        "${XDG_CACHE_HOME:-$UN_HOME/.cache}/nvim"|"$UN_HOME/.local/share/man/man1/zoxide.1"|"$UN_HOME/.local/share/man/man1/zi.1") return 0 ;;
        *) return 1 ;;
    esac
}

un_link_points_to() {
    local path=$1 expected=$2 base=${3:-$1} target parent
    [[ -L "$path" ]] || return 1
    target=$(readlink "$path")
    [[ "$target" = /* ]] || target="$(dirname "$base")/$target"
    [[ "$target" != "$expected" ]] || return 0
    parent=$(dirname "$target")
    [[ -d "$parent" ]] || return 1
    target="$(cd -P "$parent" && pwd)/${target##*/}"
    [[ "$target" = "$expected" ]]
}

un_add_link() {
    local destination=$1 source=$2 entry existing
    un_exists "$destination" || return 0
    un_safe_path "$destination" || return 0
    case "$destination" in
        "$UN_HOME/.zshrc") [[ "$source" = "$UN_REPO/zshrc" ]] || return 0 ;;
        "$UN_HOME/.p10k.zsh") [[ "$source" = "$UN_REPO/p10k.zsh" ]] || return 0 ;;
        "$CONFIG_ROOT"/*) [[ "$source" = "$UN_REPO/config/${destination#"$CONFIG_ROOT/"}" ]] || return 0 ;;
        "$BIN_DIR"/*)
            [[ "$source" = "$DATA_DIR/"* || "$source" = /usr/bin/batcat || "$source" = /usr/bin/fdfind \
               || "$destination" = "$BIN_DIR/bunx" && "${source##*/}" = bun ]] || return 0 ;;
        *) return 0 ;;
    esac
    un_link_points_to "$destination" "$source" || return 0
    printf -v entry '%s\t%s' "$destination" "$source"
    for existing in "${UN_LINKS[@]}"; do [[ "$existing" != "$entry" ]] || return 0; done
    UN_LINKS+=("$entry")
}

un_add_path() {
    local path=$1 legacy=${2:-0} existing
    un_exists "$path" || return 0
    un_allowed_data "$path" && un_safe_path "$path" || return 0
    for existing in "${UN_PATHS[@]}" "${UN_OLD_PATHS[@]}"; do [[ "$existing" != "$path" ]] || return 0; done
    if ((legacy)); then UN_OLD_PATHS+=("$path"); else UN_PATHS+=("$path"); fi
}

un_pkg_installed() {
    local manager=$1 package=$2
    case "$manager" in
        brew-formula) [[ -n "$UN_BREW" ]] && "$UN_BREW" list --formula --versions "$package" >/dev/null 2>&1 ;;
        brew-cask) [[ -n "$UN_BREW" ]] && "$UN_BREW" list --cask --versions "$package" >/dev/null 2>&1 ;;
        pacman) command -v pacman >/dev/null && pacman -Q "$package" >/dev/null 2>&1 ;;
        *) return 1 ;;
    esac
}

un_add_package() {
    local manager=$1 package=$2 legacy=${3:-0} entry existing
    [[ "$package" =~ ^[A-Za-z0-9@+_.:-]+$ ]] || return 0
    un_pkg_installed "$manager" "$package" || return 0
    entry="$manager:$package"
    for existing in "${UN_PACKAGES[@]}" "${UN_OLD_PACKAGES[@]}"; do [[ "$existing" != "$entry" ]] || return 0; done
    if ((legacy)); then UN_OLD_PACKAGES+=("$entry"); else UN_PACKAGES+=("$entry"); fi
}

un_collect() {
    local destination source path file manager package
    if [[ -f "$UN_OWN/links" ]]; then
        while IFS=$'\t' read -r destination source; do un_add_link "$destination" "$source"; done < "$UN_OWN/links"
    fi
    un_add_link "$UN_HOME/.zshrc" "$UN_REPO/zshrc"
    un_add_link "$UN_HOME/.p10k.zsh" "$UN_REPO/p10k.zsh"
    for source in "$UN_REPO"/config/*; do un_add_link "$CONFIG_ROOT/${source##*/}" "$source"; done
    for path in "$BIN_DIR"/*; do
        [[ -L "$path" ]] || continue
        source=$(readlink "$path")
        [[ "$source" = /* ]] || source="$(dirname "$path")/$source"
        un_add_link "$path" "$source"
    done
    if [[ -f "$UN_OWN/paths" ]]; then
        while IFS= read -r path; do un_add_path "$path"; done < "$UN_OWN/paths"
    fi
    # This private namespace has only been used for this setup's downloaded tools.
    if [[ "$UN_PLATFORM" = ubuntu ]]; then
        for path in "$DATA_DIR/neovim" "$DATA_DIR/ubuntu-env" "$DATA_DIR/mamba-root" "$DATA_DIR/wrappers" "$DATA_DIR/npm-global" \
                    "$DATA_DIR/bin/fzf" "$DATA_DIR/bin/zoxide" "$DATA_DIR/bin/tree-sitter" "$DATA_DIR/bin/bun" "$DATA_DIR/bin/micromamba"; do un_add_path "$path"; done
        for path in "$BIN_DIR/uv" "$BIN_DIR/uvx" "$UN_NVM_DIR" "$UN_CARGO_DIR" "$UN_RUSTUP_DIR"; do un_add_path "$path" 1; done
    fi
    for path in "${XDG_DATA_HOME:-$UN_HOME/.local/share}/zinit" "${XDG_CACHE_HOME:-$UN_HOME/.cache}/zinit" \
                "${XDG_DATA_HOME:-$UN_HOME/.local/share}/nvim" "${XDG_STATE_HOME:-$UN_HOME/.local/state}/nvim" \
                "${XDG_CACHE_HOME:-$UN_HOME/.cache}/nvim"; do un_add_path "$path" 1; done
    for manager in brew-formula brew-cask pacman; do
        [[ "$UN_PLATFORM" = mac && "$manager" = brew-* || "$UN_PLATFORM" = arch && "$manager" = pacman ]] || continue
        for file in "$UN_OWN/packages/$manager"/*; do
            [[ -f "$file" ]] || continue
            un_add_package "$manager" "${file##*/}"
        done
    done
    # Historical versions had no ownership journal. Only this bounded list is opt-in.
    if [[ "$UN_PLATFORM" = mac ]]; then
        for package in zsh tmux neovim fzf zoxide uv tree-sitter-cli llvm bat ripgrep fd node pyright bash-language-server typescript-language-server typescript rust bun; do un_add_package brew-formula "$package" 1; done
        for package in kitty brave-browser; do un_add_package brew-cask "$package" 1; done
    elif [[ "$UN_PLATFORM" = arch ]]; then
        for package in zsh tmux neovim fzf zoxide uv tree-sitter-cli clang bat ripgrep fd nodejs npm pyright bash-language-server typescript-language-server typescript rust bun-bin kitty brave-bin; do un_add_package pacman "$package" 1; done
    fi
}

un_plan() {
    local item
    log "解除安裝計畫：$UN_PLATFORM"
    printf '會移除本 repository 的設定連結，並還原能找到的原始設定備份。\n'
    printf '有紀錄且仍符合的 Git / shell 設定會還原；個人目錄移至回收備份。\n'
    printf 'LEGACY 模式也會清除沒有原始備份的 Git 全域 user.name / user.email（先備份目前值）。\n'
    for item in "${UN_LINKS[@]}"; do printf '  設定連結：%s\n' "${item%%$'\t'*}"; done
    for item in "${UN_PATHS[@]}"; do printf '  個人工具／資料：%s\n' "$item"; done
    for item in "${UN_PACKAGES[@]}"; do printf '  已記錄新增套件：%s\n' "$item"; done
    if ((${#UN_OLD_PATHS[@]} + ${#UN_OLD_PACKAGES[@]})); then
        printf '\n以下項目沒有新增紀錄，可能是原本就有的工具；僅輸入 LEGACY 時納入：\n'
        for item in "${UN_OLD_PATHS[@]}" "${UN_OLD_PACKAGES[@]}"; do printf '  舊工具候選：%s\n' "$item"; done
    fi
    printf '\n回收備份：%s\n' "$UN_RECOVERY"
    if [[ "$UN_PLATFORM" = ubuntu ]]; then printf 'Ubuntu 不會使用 sudo，也不會移除舊版 apt 安裝的系統套件。\n'; fi
}

un_move() {
    local path=$1 destination index=0
    un_exists "$path" || return 0
    if ! un_safe_path "$path"; then log "保留不在安全範圍內的路徑：$path"; UN_FAILURES=$((UN_FAILURES+1)); return 0; fi
    destination="$UN_RECOVERY/${path#"$UN_HOME/"}"
    while un_exists "$destination"; do index=$((index+1)); destination="$UN_RECOVERY/${path#"$UN_HOME/"}.remaining-$index"; done
    mkdir -p "$(dirname "$destination")"
    mv -- "$path" "$destination"
    log "已移至回收備份：$path"
}

un_restore_backup() {
    local destination=$1 relative candidate source=$2 parent root
    relative=${destination#"$UN_HOME/"}
    for candidate in "$STATE_DIR"/backups/*/"$relative"; do
        un_exists "$candidate" || continue
        if [[ -L "$candidate" ]] && un_link_points_to "$candidate" "$source" "$destination"; then continue; fi
        parent=$(cd -P "$(dirname "$candidate")" && pwd)
        root=$(cd -P "$STATE_DIR/backups" && pwd)
        [[ "$parent" = "$root/"* ]] || continue
        mkdir -p "$(dirname "$destination")"
        mv -- "$candidate" "$destination"
        log "已還原原始設定：$destination"
        break
    done
}

un_restore_configs() {
    local entry destination source staged="$UN_TMP/bashrc"
    for entry in "${UN_LINKS[@]}"; do
        destination=${entry%%$'\t'*}; source=${entry#*$'\t'}
        un_link_points_to "$destination" "$source" || continue
        un_move "$destination"
        un_restore_backup "$destination" "$source"
    done
    if un_exists "$SHELL_FILE" && un_safe_path "$SHELL_FILE"; then
        if [[ -f "$UN_OWN/env.cksum" ]] || grep -q 'BUN_INSTALL\|Managed by dotfiles' "$SHELL_FILE" 2>/dev/null; then un_move "$SHELL_FILE"; fi
    fi
    local bashrc="$UN_HOME/.bashrc" start='# dotfiles: auto-start zsh' end='# dotfiles: end auto-start zsh'
    if [[ -f "$bashrc" ]] && grep -Fxq "$start" "$bashrc"; then
        if [[ $(grep -Fxc "$start" "$bashrc") = 1 && $(grep -Fxc "$end" "$bashrc") = 1 ]]; then
            awk -v start="$start" -v end="$end" '$0==start{skip=1;next} $0==end{skip=0;next} !skip{print}' "$bashrc" > "$staged"
            un_move "$bashrc"
            install -m 600 "$staged" "$bashrc"
        else log 'Bash 啟動區塊不完整，保留 .bashrc。'; UN_FAILURES=$((UN_FAILURES+1)); fi
    fi
}

un_restore_git() {
    command -v git >/dev/null || return 0
    local key value
    for key in name email; do
        if [[ ! -f "$UN_OWN/git-$key.applied" || ! -f "$UN_OWN/git-$key.before" ]]; then
            if ((UN_LEGACY)); then
                git config --global --get-all "user.$key" > "$UN_TMP/git-current" 2>/dev/null || true
                if [[ -s "$UN_TMP/git-current" ]]; then
                    cp "$UN_TMP/git-current" "$UN_RECOVERY/git-$key.removed"
                    if ! git config --global --unset-all -- "user.$key"; then UN_FAILURES=$((UN_FAILURES+1)); UN_KEEP_GIT=1; fi
                fi
            fi
            continue
        fi
        git config --global --get-all "user.$key" > "$UN_TMP/git-current" 2>/dev/null || true
        if ! cmp -s "$UN_TMP/git-current" "$UN_OWN/git-$key.applied"; then log "Git user.$key 已另行修改，保留目前值。"; continue; fi
        cp "$UN_TMP/git-current" "$UN_RECOVERY/git-$key.removed"
        if ! git config --global --unset-all -- "user.$key"; then UN_FAILURES=$((UN_FAILURES+1)); UN_KEEP_GIT=1; continue; fi
        while IFS= read -r value; do git config --global --add -- "user.$key" "$value"; done < "$UN_OWN/git-$key.before"
        log "已還原 Git user.$key。"
    done
}

un_shell_uses_package_zsh() {
    local shell=$1 prefix
    if [[ "$UN_PLATFORM" = mac && -n "$UN_BREW" ]]; then
        prefix=$("$UN_BREW" --prefix)
        [[ "$shell" -ef "$prefix/opt/zsh/bin/zsh" ]]
    elif [[ "$UN_PLATFORM" = arch ]]; then [[ "$shell" -ef /usr/bin/zsh ]]
    else return 1; fi
}

un_restore_shell() {
    local applied previous current account entry removing_zsh=0
    for entry in "${UN_PACKAGES[@]}"; do [[ "${entry#*:}" != zsh ]] || removing_zsh=1; done
    [[ -f "$UN_OWN/shell.applied" && -f "$UN_OWN/shell.before" ]] || ((removing_zsh)) || return 0
    account=$(id -un)
    if [[ "$UN_PLATFORM" = mac ]]; then current=$(dscl . -read "/Users/$account" UserShell | awk '{print $2}')
    else current=$(getent passwd "$account" | cut -d: -f7); fi
    if [[ -f "$UN_OWN/shell.applied" && -f "$UN_OWN/shell.before" ]]; then
        applied=$(cat "$UN_OWN/shell.applied"); previous=$(cat "$UN_OWN/shell.before")
        [[ "$current" = "$applied" ]] || return 0
    elif un_shell_uses_package_zsh "$current"; then
        if [[ "$UN_PLATFORM" = mac ]]; then previous=/bin/zsh; else previous=/bin/bash; fi
    else return 0; fi
    if [[ ! -x "$previous" ]] || ! grep -Fxq "$previous" /etc/shells; then UN_KEEP_ZSH=1; UN_FAILURES=$((UN_FAILURES+1)); log '原登入 shell 已不可用，保留 zsh 套件。'; return 0; fi
    if [[ "$UN_PLATFORM" = ubuntu ]]; then
        if ! chsh -s "$previous"; then UN_KEEP_ZSH=1; UN_FAILURES=$((UN_FAILURES+1)); fi
    elif ! as_root chsh -s "$previous" "$account"; then UN_KEEP_ZSH=1; UN_FAILURES=$((UN_FAILURES+1)); fi
}

un_remove_user_packages() {
    local directory prefix npm_bin node_bin file package packages=() uv_bin tool_root
    if [[ -f "$UN_OWN/pynvim-added" ]]; then
        uv_bin=$(command -v uv 2>/dev/null || true)
        if [[ -n "$uv_bin" ]]; then
            if [[ -f "$UN_OWN/pynvim-tool-dir" ]]; then tool_root=$(cat "$UN_OWN/pynvim-tool-dir"); else tool_root=$("$uv_bin" tool dir); fi
            if un_safe_path "$tool_root/pynvim" && [[ -d "$tool_root/pynvim" ]]; then
                if ! env UV_TOOL_DIR="$tool_root" "$uv_bin" tool uninstall pynvim; then UN_FAILURES=$((UN_FAILURES+1)); fi
            fi
        fi
    fi
    for directory in "$UN_OWN"/npm/*; do
        [[ -f "$directory/prefix" && -f "$directory/npm-bin" && -f "$directory/node-bin" ]] || continue
        prefix=$(cat "$directory/prefix"); npm_bin=$(cat "$directory/npm-bin"); node_bin=$(cat "$directory/node-bin")
        [[ -d "$prefix" && -x "$npm_bin" ]] || continue
        un_safe_path "$prefix/.dotfiles-prefix-check" || continue
        case "$npm_bin" in "$UN_HOME"/*/npm|/usr/bin/npm|/usr/local/bin/npm) ;; *) continue ;; esac
        packages=()
        for file in "$directory"/package-*; do
            [[ -f "$file" ]] || continue
            package=${file##*/package-}
            case "$package" in pyright|typescript|bash-language-server|typescript-language-server) packages+=("$package") ;; esac
        done
        if ((${#packages[@]})); then
            if ! env PATH="$node_bin:$PATH" npm_config_prefix="$prefix" "$npm_bin" uninstall --global -- "${packages[@]}"; then UN_FAILURES=$((UN_FAILURES+1)); fi
        fi
    done
    if [[ -f "$UN_OWN/nvm-alias.captured" && -f "$UN_NVM_DIR/alias/default" ]] && [[ $(cat "$UN_NVM_DIR/alias/default") = 'lts/*' ]]; then
        un_move "$UN_NVM_DIR/alias/default"
        if [[ -f "$UN_OWN/nvm-alias.before" ]]; then cp "$UN_OWN/nvm-alias.before" "$UN_NVM_DIR/alias/default"; fi
    fi
}

un_quarantine_data() {
    local path
    # Parents go first so nested records do not collide in the recovery tree.
    for path in "${UN_PATHS[@]}"; do printf '%08d\t%s\n' "${#path}" "$path"; done | sort -n > "$UN_TMP/paths"
    while IFS=$'\t' read -r _ path; do [[ -z "$path" ]] || un_move "$path"; done < "$UN_TMP/paths"
}

un_remove_native() {
    local entry manager package formulas=() casks=() pacman_packages=() current account
    ((${#UN_PACKAGES[@]})) || return 0
    account=$(id -un)
    if [[ "$UN_PLATFORM" = mac ]]; then current=$(dscl . -read "/Users/$account" UserShell 2>/dev/null | awk '{print $2}')
    else current=$(getent passwd "$account" 2>/dev/null | cut -d: -f7); fi
    for entry in "${UN_PACKAGES[@]}"; do
        manager=${entry%%:*}; package=${entry#*:}
        if [[ "$package" = zsh ]]; then
            if ((UN_KEEP_ZSH)) || un_shell_uses_package_zsh "$current"; then
                log '登入帳號仍使用這個 zsh，保留套件。'; UN_FAILURES=$((UN_FAILURES+1)); continue
            fi
        fi
        [[ "$package" != git || "$UN_KEEP_GIT" = 0 ]] || continue
        case "$manager" in brew-formula) formulas+=("$package") ;; brew-cask) casks+=("$package") ;; pacman) pacman_packages+=("$package") ;; esac
    done
    if ((${#casks[@]})); then
        if ! env HOMEBREW_NO_AUTOREMOVE=1 "$UN_BREW" uninstall --cask -- "${casks[@]}"; then UN_FAILURES=$((UN_FAILURES+1)); fi
    fi
    if ((${#formulas[@]})); then
        if ! env HOMEBREW_NO_AUTOREMOVE=1 "$UN_BREW" uninstall --formula -- "${formulas[@]}"; then UN_FAILURES=$((UN_FAILURES+1)); fi
    fi
    if ((${#pacman_packages[@]})); then
        if ! as_root pacman -R --noconfirm -- "${pacman_packages[@]}"; then UN_FAILURES=$((UN_FAILURES+1)); fi
    fi
}

un_cleanup() {
    [[ -z "$UN_TMP" || ! -d "$UN_TMP" ]] || rm -rf -- "$UN_TMP"
    if [[ -n "$UN_LOCK" && -d "$UN_LOCK" ]]; then rm -f "$UN_LOCK/pid"; rmdir "$UN_LOCK" 2>/dev/null || true; fi
}

un_main() {
    un_init "$@"
    un_collect
    un_plan
    if ((UN_DRY_RUN)); then log '預覽完成，未進行任何變更。'; return 0; fi
    [[ $(host_platform) = "$UN_PLATFORM" ]] || die '指定平台與目前系統不符。'
    ((EUID != 0)) || die '請使用一般帳號執行，不要 sudo bash uninstall.sh。'
    [[ -t 0 ]] || die '請在互動終端機檢視計畫並確認；預覽可使用 --dry-run。'
    local answer
    printf '\nUNINSTALL：移除有紀錄的工具與本套設定。\nLEGACY：另包含上方未有紀錄的舊工具候選清單。\n'
    read -r -p '輸入 UNINSTALL 或 LEGACY 確認；直接 Enter 取消：' answer || return 1
    case "$answer" in UNINSTALL) ;; LEGACY) UN_LEGACY=1; UN_PATHS+=("${UN_OLD_PATHS[@]}"); UN_PACKAGES+=("${UN_OLD_PACKAGES[@]}") ;; *) log '已取消，未進行變更。'; return 0 ;; esac
    umask 077
    mkdir -p "$STATE_DIR" "$UN_RECOVERY"
    UN_LOCK="$STATE_DIR/install.lock"
    mkdir "$UN_LOCK" 2>/dev/null || die '安裝或解除安裝正在執行，請先確認鎖定目錄。'
    trap un_cleanup EXIT
    printf '%s\n' "$$" > "$UN_LOCK/pid"
    UN_TMP=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-uninstall.XXXXXXXX")
    trap 'printf "\n[錯誤] 解除安裝在第 %s 行停止；回收備份位於 %s。\n" "$LINENO" "$UN_RECOVERY" >&2' ERR
    un_restore_git
    un_restore_shell
    un_remove_user_packages
    un_restore_configs
    un_quarantine_data
    un_remove_native
    if ((UN_FAILURES)); then
        log "部分項目無法移除，已保留紀錄供重跑；請檢查上方訊息。回收備份：$UN_RECOVERY"
        return 1
    fi
    if [[ -d "$UN_OWN" ]]; then mv "$UN_OWN" "$UN_RECOVERY/ownership"; fi
    log "解除安裝完成；請重新登入。回收備份：$UN_RECOVERY"
}

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then un_main "$@"; fi
