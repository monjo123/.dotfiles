#!/usr/bin/env bash
# Personal dotfiles setup: macOS / Arch Linux / Ubuntu.
# Run as your login user: bash install.sh --set-shell
# Preview without changes: bash install.sh --dry-run
# Official installation sources are listed in README.md.

set -Eeuo pipefail

INSTALLER_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<'EOF'
用法：bash ~/.dotfiles/install.sh [選項]

選項：
  --platform NAME   指定 mac、arch、ubuntu（可搭配 --dry-run 檢視其他平台）
  --set-shell       將登入 shell 設成 zsh
  --node            Node.js 與 Pyright / Bash / TypeScript 語言伺服器
  --rust            Rust / Cargo（Scheme 的 parinfer-rust 外掛需要）
  --bun             Bun / bunx
  --all             開啟 --node --rust --bun
  --update          更新本次選用的工具
  --links-only      只建立 dotfiles 連結；不安裝套件、不改登入 shell
  --dry-run         僅顯示計畫，不下載、不寫入檔案
  --allow-root      僅 Ubuntu：明確允許直接安裝到 root 帳號
  -h, --help        顯示說明

Ubuntu 可指定 NVIM_VERSION / TREE_SITTER_VERSION，預設 latest 正式版。
Ubuntu 使用 NVM_VERSION（預設 v0.41.0）、TOOL_PYTHON_VERSION（預設 3.11）。
Arch 若沒有 yay，會使用 AUR 的 yay-bin PKGBUILD 及 makepkg 建立，不執行網路 shell installer。
macOS 需要先有 Homebrew；未安裝時請先依 https://brew.sh 完成安裝。
EOF
}

log() { printf '\n[dotfiles] %s\n' "$*"; }
die() { printf '\n[錯誤] %s\n' "$*" >&2; exit 1; }

parse_args() {
    SET_SHELL=0 NODE=0 RUST=0 BUN=0 UPDATE=0 DRY_RUN=0 ALLOW_ROOT=0 LINKS_ONLY=0
    PLATFORM=auto
    while (($#)); do
        case "$1" in
            --platform)
                [[ $# -ge 2 ]] || die '--platform 需要 mac、arch 或 ubuntu。'
                PLATFORM=$2
                case "$PLATFORM" in mac|arch|ubuntu) ;; *) die '平台只接受 mac、arch、ubuntu。' ;; esac
                shift ;;
            --set-shell) SET_SHELL=1 ;;
            --node) NODE=1 ;;
            --rust) RUST=1 ;;
            --bun) BUN=1 ;;
            --all) NODE=1 RUST=1 BUN=1 ;;
            --update) UPDATE=1 ;;
            --links-only) LINKS_ONLY=1 ;;
            --dry-run) DRY_RUN=1 ;;
            --allow-root) ALLOW_ROOT=1 ;;
            -h|--help) usage; exit 0 ;;
            *) die "不支援的選項：$1；請使用 --help。" ;;
        esac
        shift
    done
    if ((LINKS_ONLY && SET_SHELL)); then die '--links-only 不能與 --set-shell 一起使用。'; fi
    NVIM_TAG=${NVIM_VERSION:-latest}
    TREE_SITTER_TAG=${TREE_SITTER_VERSION:-latest}
    NVM_TAG=${NVM_VERSION:-v0.41.0}
    TOOL_PYTHON=${TOOL_PYTHON_VERSION:-3.11}
    local value
    for value in "$NVIM_TAG" "$TREE_SITTER_TAG" "$NVM_TAG" "$TOOL_PYTHON"; do
        [[ "$value" =~ ^[A-Za-z0-9._-]+$ ]] || die '版本只能包含英文字母、數字、點、底線與連字號。'
    done
}

init_paths() {
    SETUP_USER_HOME=${HOME:?HOME is not set}
    [[ "$SETUP_USER_HOME" = /* && "$SETUP_USER_HOME" != / ]] || die 'HOME 必須是有效的使用者家目錄。'
    BIN_DIR="$SETUP_USER_HOME/.local/bin"
    DATA_DIR="$SETUP_USER_HOME/.local/share/dotfiles"
    STATE_DIR="$SETUP_USER_HOME/.local/state/dotfiles"
    CONFIG_ROOT="${XDG_CONFIG_HOME:-$SETUP_USER_HOME/.config}"
    CONFIG_DIR="$CONFIG_ROOT/dotfiles"
    DOTFILES_DIR="$INSTALLER_DIR"
    SETUP_NVM_DIR=${NVM_DIR:-$SETUP_USER_HOME/.nvm}
    SETUP_CARGO_DIR=${CARGO_HOME:-$SETUP_USER_HOME/.cargo}
    SHELL_FILE="$CONFIG_DIR/env.sh"
    RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$"
    BACKUP_DIR="$STATE_DIR/backups/$RUN_ID"
    SETUP_TMP_DIR=''
}

host_platform() {
    case "$(uname -s)" in
        Darwin) printf mac ;;
        Linux)
            local ID='' ID_LIKE=''
            [[ -r /etc/os-release ]] || return 1
            # shellcheck disable=SC1091
            . /etc/os-release
            case " $ID $ID_LIKE " in
                *' arch '*) printf arch ;;
                *' ubuntu '*|*' debian '*) printf ubuntu ;;
                *) return 1 ;;
            esac ;;
        *) return 1 ;;
    esac
}

select_platform() {
    if [[ "$PLATFORM" = auto ]]; then
        PLATFORM=$(host_platform) || die '無法自動辨識系統，請使用 --platform mac|arch|ubuntu。'
    fi
}

show_plan() {
    log "安裝計畫：$PLATFORM"
    printf '  dotfiles：%s\n  使用者目錄：%s\n' "$DOTFILES_DIR" "$SETUP_USER_HOME"
    printf '  Node/LSP=%s Rust=%s Bun=%s 僅連結=%s\n' "$NODE" "$RUST" "$BUN" "$LINKS_ONLY"
    case "$PLATFORM" in
        mac) printf '  工具：Homebrew；桌面程式：brew cask kitty、brave-browser\n' ;;
        arch) printf '  工具：pacman / yay；桌面程式：kitty、brave-bin\n  pacman -Syu 會完整更新 Arch 系統。\n' ;;
        ubuntu) printf '  工具：apt 基礎套件 + 官方 uv / Neovim / fzf / zoxide / Tree-sitter 下載\n' ;;
    esac
    printf '  套用 zshrc、p10k.zsh，以及 config/ 下的設定；既有檔案會先備份。\n'
    printf '  備份位置：%s\n' "$BACKUP_DIR"
}

detect_platform() {
    local actual
    actual=$(host_platform) || die '目前系統不在支援範圍。'
    [[ "$actual" = "$PLATFORM" ]] || die '指定平台與目前系統不符；跨平台檢視請加 --dry-run。'
    case "$(uname -m)" in
        x86_64|amd64) NVIM_ARCH=x86_64; TS_ARCH=x64; BUN_ARCH=x64 ;;
        aarch64|arm64) NVIM_ARCH=arm64; TS_ARCH=arm64; BUN_ARCH=aarch64 ;;
        *) die '只支援 x86_64 與 ARM64。' ;;
    esac
    if ((EUID == 0)); then
        [[ "$PLATFORM" = ubuntu && -z ${SUDO_USER:-} ]] && ((ALLOW_ROOT)) || die '請以一般帳號執行；不要 sudo bash install.sh。'
    elif ((!LINKS_ONLY)); then
        case "$PLATFORM" in
            arch|ubuntu) command -v sudo >/dev/null || die '需要 sudo。'; sudo -v ;;
        esac
    fi
    [[ -f "$DOTFILES_DIR/zshrc" && -d "$DOTFILES_DIR/config" ]] || die '請保留完整 dotfiles repository 再執行安裝。'
}

as_root() {
    if ((EUID == 0)); then "$@"; else sudo "$@"; fi
}

install_apt() {
    log '安裝系統套件'
    local packages=(ca-certificates curl wget git openssh-client jq tar gzip unzip
                    xz-utils build-essential python3 python3-venv zsh tmux clangd bat ripgrep fd-find)
    as_root apt-get update
    as_root apt-get -o DPkg::Lock::Timeout=120 install -y --no-install-recommends "${packages[@]}"
}

download() {
    local url=$1 destination=$2
    curl --fail --location --silent --show-error --retry 3 --connect-timeout 15 \
        --output "$destination.part" "$url"
    mv -- "$destination.part" "$destination"
}

release_url() {
    local repository=$1 tag=$2 asset=$3
    if [[ "$tag" = latest ]]; then
        printf 'https://github.com/%s/releases/latest/download/%s' "$repository" "$asset"
    else
        printf 'https://github.com/%s/releases/download/%s/%s' "$repository" "$tag" "$asset"
    fi
}

backup_existing() {
    local path=$1 relative destination
    [[ -e "$path" || -L "$path" ]] || return 0
    [[ "$path" = "$SETUP_USER_HOME/"* ]] || die '備份目標必須位於使用者目錄。'
    relative=${path#"$SETUP_USER_HOME/"}
    destination="$BACKUP_DIR/$relative"
    [[ ! -e "$destination" && ! -L "$destination" ]] || die '同一次安裝出現重複的備份目標。'
    mkdir -p -- "$(dirname -- "$destination")"
    mv -- "$path" "$destination"
    log "已備份：$path → $destination"
}

safe_link() {
    local source=$1 destination=$2
    [[ -e "$source" ]] || die "連結來源不存在：$source"
    if [[ -L "$destination" && $(readlink -- "$destination") = "$source" ]]; then return 0; fi
    mkdir -p -- "$(dirname -- "$destination")"
    backup_existing "$destination"
    ln -s -- "$source" "$destination"
}

publish_file() {
    local source=$1 destination=$2 mode=${3:-755} staged
    if [[ -f "$destination" && ! -L "$destination" ]] && cmp -s -- "$source" "$destination"; then return 0; fi
    mkdir -p -- "$(dirname -- "$destination")"
    staged=$(mktemp "$(dirname -- "$destination")/.dotfiles.XXXXXXXX")
    install -m "$mode" "$source" "$staged"
    backup_existing "$destination"
    mv -- "$staged" "$destination"
}

install_uv() {
    log '安裝 uv'
    if [[ ! -x "$BIN_DIR/uv" ]] || ((UPDATE)); then
        download https://astral.sh/uv/install.sh "$SETUP_TMP_DIR/uv-install.sh"
        env UV_INSTALL_DIR="$BIN_DIR" UV_NO_MODIFY_PATH=1 sh "$SETUP_TMP_DIR/uv-install.sh"
    fi
    "$BIN_DIR/uv" --version
    local args=(tool install --python "$TOOL_PYTHON")
    if ((UPDATE)); then args+=(--upgrade); fi
    env UV_TOOL_BIN_DIR="$BIN_DIR" "$BIN_DIR/uv" "${args[@]}" pynvim
}

install_neovim() {
    log '安裝 Neovim'
    local target="$DATA_DIR/neovim" asset="nvim-linux-$NVIM_ARCH.tar.gz"
    if [[ ! -x "$target/bin/nvim" ]] || ((UPDATE)); then
        download "$(release_url neovim/neovim "$NVIM_TAG" "$asset")" "$SETUP_TMP_DIR/nvim.tar.gz"
        mkdir -p "$SETUP_TMP_DIR/nvim"
        tar -xzf "$SETUP_TMP_DIR/nvim.tar.gz" -C "$SETUP_TMP_DIR/nvim" --no-same-owner
        local extracted="$SETUP_TMP_DIR/nvim/nvim-linux-$NVIM_ARCH"
        "$extracted/bin/nvim" --version >/dev/null || die 'Neovim 無法執行；請檢查架構、glibc 或指定相容版本。'
        backup_existing "$target"
        mv -- "$extracted" "$target"
    fi
    safe_link "$target/bin/nvim" "$BIN_DIR/nvim"
    "$BIN_DIR/nvim" --version
}

install_fzf() {
    log '安裝 fzf'
    local target="$DATA_DIR/bin/fzf"
    if [[ ! -x "$target" ]] || ((UPDATE)); then
        git clone --depth 1 https://github.com/junegunn/fzf.git "$SETUP_TMP_DIR/fzf"
        bash "$SETUP_TMP_DIR/fzf/install" --bin
        "$SETUP_TMP_DIR/fzf/bin/fzf" --version
        publish_file "$SETUP_TMP_DIR/fzf/bin/fzf" "$target"
    fi
    safe_link "$target" "$BIN_DIR/fzf"
}

install_zoxide() {
    log '安裝 zoxide'
    local target="$DATA_DIR/bin/zoxide"
    if [[ ! -x "$target" ]] || ((UPDATE)); then
        download https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh "$SETUP_TMP_DIR/zoxide-install.sh"
        bash "$SETUP_TMP_DIR/zoxide-install.sh" \
            --bin-dir "$SETUP_TMP_DIR/zoxide-bin" --man-dir "$SETUP_TMP_DIR/zoxide-man"
        "$SETUP_TMP_DIR/zoxide-bin/zoxide" --version
        publish_file "$SETUP_TMP_DIR/zoxide-bin/zoxide" "$target"
        mkdir -p "$SETUP_USER_HOME/.local/share/man"
        cp -R "$SETUP_TMP_DIR/zoxide-man/." "$SETUP_USER_HOME/.local/share/man/"
    fi
    safe_link "$target" "$BIN_DIR/zoxide"
}

install_tree_sitter() {
    log '安裝 Tree-sitter CLI（官方預編譯版本）'
    local target="$DATA_DIR/bin/tree-sitter" asset="tree-sitter-linux-$TS_ARCH.gz"
    if [[ ! -x "$target" ]] || ((UPDATE)); then
        download "$(release_url tree-sitter/tree-sitter "$TREE_SITTER_TAG" "$asset")" "$SETUP_TMP_DIR/tree-sitter.gz"
        gzip -dc "$SETUP_TMP_DIR/tree-sitter.gz" > "$SETUP_TMP_DIR/tree-sitter"
        chmod 755 "$SETUP_TMP_DIR/tree-sitter"
        "$SETUP_TMP_DIR/tree-sitter" --version || die 'Tree-sitter 無法執行；可指定與系統/外掛相容的版本。'
        publish_file "$SETUP_TMP_DIR/tree-sitter" "$target"
    fi
    safe_link "$target" "$BIN_DIR/tree-sitter"
}

install_node() {
    ((NODE)) || return 0
    log '安裝 nvm / Node.js LTS / Pyright / Bash / TypeScript 語言伺服器'
    if [[ ! -s "$SETUP_NVM_DIR/nvm.sh" ]] || ((UPDATE)); then
        mkdir -p "$SETUP_NVM_DIR"
        download "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_TAG/install.sh" "$SETUP_TMP_DIR/nvm-install.sh"
        env NVM_DIR="$SETUP_NVM_DIR" PROFILE=/dev/null bash "$SETUP_TMP_DIR/nvm-install.sh"
    fi
    (
        # nvm is a sourced third-party shell library; it does not require nounset.
        set +u
        export NVM_DIR="$SETUP_NVM_DIR"
        # shellcheck disable=SC1091
        . "$NVM_DIR/nvm.sh"
        nvm install --lts
        nvm alias default 'lts/*'
        if ((UPDATE)) || ! npm list --global --depth=0 pyright bash-language-server typescript-language-server typescript >/dev/null 2>&1; then
            npm install --global pyright bash-language-server typescript-language-server typescript
        fi
        node --version
        npm --version
        pyright --version
    )
}

install_rust() {
    ((RUST)) || return 0
    log '安裝 Rust / Cargo'
    if [[ ! -x "$SETUP_CARGO_DIR/bin/rustup" ]]; then
        download https://sh.rustup.rs "$SETUP_TMP_DIR/rustup-install.sh"
        env CARGO_HOME="$SETUP_CARGO_DIR" sh "$SETUP_TMP_DIR/rustup-install.sh" \
            -y --profile minimal --default-toolchain stable --no-modify-path
    elif ((UPDATE)); then
        "$SETUP_CARGO_DIR/bin/rustup" update stable
    fi
    "$SETUP_CARGO_DIR/bin/cargo" --version
}

install_bun() {
    ((BUN)) || return 0
    log '安裝 Bun'
    local target="$DATA_DIR/bin/bun" asset_target="linux-$BUN_ARCH"
    if [[ ! -x "$target" ]] || ((UPDATE)); then
        if [[ "$BUN_ARCH" = x64 ]] && ! grep -qw avx2 /proc/cpuinfo; then asset_target+=-baseline; fi
        download "$(release_url oven-sh/bun latest "bun-$asset_target.zip")" "$SETUP_TMP_DIR/bun.zip"
        unzip -q "$SETUP_TMP_DIR/bun.zip" -d "$SETUP_TMP_DIR/bun"
        local executable="$SETUP_TMP_DIR/bun/bun-$asset_target/bun"
        chmod 755 "$executable"
        "$executable" --version || die 'Bun 無法在目前 CPU/系統上執行。'
        publish_file "$executable" "$target"
    fi
    safe_link "$target" "$BIN_DIR/bun"
    safe_link "$target" "$BIN_DIR/bunx"
}

# ---------------------------- macOS: Homebrew -----------------------------
find_brew() {
    if command -v brew >/dev/null 2>&1; then
        BREW_BIN=$(command -v brew)
    elif [[ -x /opt/homebrew/bin/brew ]]; then
        BREW_BIN=/opt/homebrew/bin/brew
    elif [[ -x /usr/local/bin/brew ]]; then
        BREW_BIN=/usr/local/bin/brew
    else
        die '找不到 Homebrew；請先依 https://brew.sh 安裝，再重新執行。'
    fi
    eval "$("$BREW_BIN" shellenv bash)"
    BREW_PREFIX=$("$BREW_BIN" --prefix)
}

install_mac() {
    log 'macOS：使用 Homebrew 安裝工具與桌面程式'
    find_brew
    local formulas=(git curl wget jq ca-certificates python zsh tmux neovim fzf
                    zoxide uv tree-sitter-cli llvm bat ripgrep fd zinit)
    local casks=(kitty brave-browser)
    if ((NODE)); then formulas+=(node pyright bash-language-server typescript-language-server typescript); fi
    if ((RUST)); then formulas+=(rust); fi
    if ((BUN)); then formulas+=(bun); fi
    "$BREW_BIN" update
    "$BREW_BIN" install --formula "${formulas[@]}"
    "$BREW_BIN" install --cask "${casks[@]}"
    if ((UPDATE)); then
        "$BREW_BIN" upgrade --formula "${formulas[@]}"
        "$BREW_BIN" upgrade --cask "${casks[@]}"
    fi
    ZINIT_SCRIPT="$BREW_PREFIX/opt/zinit/zinit.zsh"
}

# -------------------------- Arch: pacman / yay ----------------------------
ensure_yay() {
    command -v yay >/dev/null 2>&1 && return 0
    log '建立 yay（AUR yay-bin PKGBUILD / makepkg）'
    git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$SETUP_TMP_DIR/yay-bin"
    (
        cd "$SETUP_TMP_DIR/yay-bin"
        makepkg -si --noconfirm
    )
    command -v yay >/dev/null || die 'yay 安裝失敗。'
}

install_arch() {
    log 'Arch：完整更新系統並用 pacman 安裝官方套件'
    local packages=(base-devel ca-certificates git openssh curl wget jq python python-pynvim
                    zsh tmux neovim fzf zoxide uv tree-sitter-cli clang bat ripgrep fd unzip kitty)
    if ((NODE)); then packages+=(nodejs npm pyright bash-language-server typescript-language-server typescript); fi
    if ((RUST)); then packages+=(rust); fi
    as_root pacman -Syu --needed --noconfirm "${packages[@]}"
    ensure_yay
    local aur_packages=(brave-bin) zinit_package
    # Package availability can differ between Arch and compatible distributions.
    if pacman -Si zinit >/dev/null 2>&1; then
        as_root pacman -S --needed --noconfirm zinit
        zinit_package=zinit
    elif yay -Si zinit >/dev/null 2>&1; then
        aur_packages+=(zinit)
        zinit_package=zinit
    elif yay -Si zinit-git >/dev/null 2>&1; then
        aur_packages+=(zinit-git)
        zinit_package=zinit-git
    else
        die 'pacman / yay 找不到 zinit 或 zinit-git，請確認套件來源。'
    fi
    if ((BUN)); then aur_packages+=(bun-bin); fi
    log 'Arch：使用 yay 安裝 AUR 套件'
    yay -S --needed --noconfirm "${aur_packages[@]}"
    ZINIT_SCRIPT=$(pacman -Ql "$zinit_package" | awk '$2 ~ /\/zinit\.zsh$/ {print $2; exit}')
    [[ -n "$ZINIT_SCRIPT" ]] || die 'Zinit 套件中找不到 zinit.zsh。'
}

# -------------------- Ubuntu: base apt + official URLs --------------------
install_zinit_ubuntu() {
    log 'Ubuntu：安裝 Zinit'
    local destination="${XDG_DATA_HOME:-$SETUP_USER_HOME/.local/share}/zinit/zinit.git"
    if [[ ! -f "$destination/zinit.zsh" ]]; then
        [[ ! -e "$destination" ]] || die 'Zinit 目錄已存在但缺少 zinit.zsh，請先確認。'
        git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "$SETUP_TMP_DIR/zinit"
        mkdir -p "$(dirname "$destination")"
        mv "$SETUP_TMP_DIR/zinit" "$destination"
    elif ((UPDATE)); then
        git -C "$destination" pull --ff-only
    fi
    ZINIT_SCRIPT="$destination/zinit.zsh"
}

install_ubuntu() {
    install_apt
    # Ubuntu names the executables batcat / fdfind; the dotfiles use bat / fd.
    if ! command -v bat >/dev/null; then safe_link "$(command -v batcat)" "$BIN_DIR/bat"; fi
    if ! command -v fd >/dev/null; then safe_link "$(command -v fdfind)" "$BIN_DIR/fd"; fi
    install_uv
    install_neovim
    install_fzf
    install_zoxide
    install_tree_sitter
    install_node
    install_rust
    install_bun
    install_zinit_ubuntu
}

install_dotfiles() {
    log "套用目前 repository：$DOTFILES_DIR"
    safe_link "$DOTFILES_DIR/zshrc" "$SETUP_USER_HOME/.zshrc"
    if [[ -f "$DOTFILES_DIR/p10k.zsh" ]]; then
        safe_link "$DOTFILES_DIR/p10k.zsh" "$SETUP_USER_HOME/.p10k.zsh"
    fi
    local source
    for source in "$DOTFILES_DIR"/config/*; do
        [[ -e "$source" ]] || continue
        safe_link "$source" "$CONFIG_ROOT/${source##*/}"
    done
}

write_shell_config() {
    log '建立共用工具環境（zshrc 會自動載入）'
    local staged="$SETUP_TMP_DIR/env.sh"
    : > "$staged"
    if [[ "$PLATFORM" = mac ]]; then
        printf 'eval "$(%q shellenv bash)"\n' "$BREW_BIN" >> "$staged"
        printf 'export DOTFILES_ZINIT_SCRIPT=%q\n' "$BREW_PREFIX/opt/zinit/zinit.zsh" >> "$staged"
        printf 'case ":$PATH:" in *":%s:"*) ;; *) export PATH=%q:"$PATH" ;; esac\n' \
            "$BREW_PREFIX/opt/llvm/bin" "$BREW_PREFIX/opt/llvm/bin" >> "$staged"
    elif [[ "$PLATFORM" = arch ]]; then
        printf 'export DOTFILES_ZINIT_SCRIPT=%q\n' "$ZINIT_SCRIPT" >> "$staged"
    else
        printf 'export DOTFILES_ZINIT_SCRIPT=%q\n' "$ZINIT_SCRIPT" >> "$staged"
    fi
    cat >> "$staged" <<'EOF'
case "$PATH" in
    "$HOME/.local/bin"|"$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
EOF
    if [[ "$PLATFORM" = ubuntu && -s "$SETUP_NVM_DIR/nvm.sh" ]]; then
        printf '\nexport NVM_DIR=%q\n[ ! -s "$NVM_DIR/nvm.sh" ] || . "$NVM_DIR/nvm.sh"\n' "$SETUP_NVM_DIR" >> "$staged"
    fi
    if [[ "$PLATFORM" = ubuntu && -s "$SETUP_CARGO_DIR/env" ]]; then
        printf '\n. %q\n' "$SETUP_CARGO_DIR/env" >> "$staged"
    fi
    if ((BUN)) || [[ -x "$BIN_DIR/bun" ]]; then
        cat >> "$staged" <<'EOF'
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
case ":$PATH:" in
    *":$BUN_INSTALL/bin:"*) ;;
    *) export PATH="$BUN_INSTALL/bin:$PATH" ;;
esac
EOF
    fi
    publish_file "$staged" "$SHELL_FILE" 600
    bash -n "$SHELL_FILE"
    if command -v zsh >/dev/null; then zsh -n "$SHELL_FILE"; fi
}

set_login_shell() {
    ((SET_SHELL)) || return 0
    log '設定登入 shell 為 zsh'
    local zsh_path login_user current_shell
    zsh_path=$(command -v zsh)
    login_user=$(id -un)
    if [[ "$PLATFORM" = mac ]]; then
        current_shell=$(dscl . -read "/Users/$login_user" UserShell | awk '{print $2}')
    else
        current_shell=$(getent passwd "$login_user" | cut -d: -f7)
    fi
    [[ "$current_shell" != "$zsh_path" ]] || return 0
    if ! grep -Fxq "$zsh_path" /etc/shells; then
        [[ "$PLATFORM" = mac ]] || die 'zsh 不在 /etc/shells 中。'
        printf '%s\n' "$zsh_path" | as_root tee -a /etc/shells >/dev/null
    fi
    as_root chsh -s "$zsh_path" "$login_user"
}

verify_installation() {
    log '檢查安裝結果'
    local tool
    for tool in git python3 zsh tmux clangd uv nvim fzf zoxide tree-sitter bat rg fd; do
        command -v "$tool" >/dev/null || die "找不到工具：$tool"
    done
    nvim --headless -u NONE -i NONE '+lua if not (vim.pack and vim.pack.add) then vim.cmd("cquit 1") end' +qa \
        || die '目前 Neovim 缺少此設定使用的 vim.pack API；請更新 Neovim。'
    if [[ "$PLATFORM" = ubuntu ]]; then
        local tool_root
        tool_root=$("$BIN_DIR/uv" tool dir)
        "$tool_root/pynvim/bin/python" -c 'import pynvim; print("pynvim: OK")'
    elif [[ "$PLATFORM" = arch ]]; then
        /usr/bin/python -c 'import pynvim; print("pynvim: OK")'
    fi
    if ((NODE)); then
        for tool in node npm pyright bash-language-server typescript-language-server; do
            command -v "$tool" >/dev/null || die "找不到：$tool"
        done
    fi
    if ((RUST)); then cargo --version; fi
    if ((BUN)); then bun --version; fi
    [[ -r "$ZINIT_SCRIPT" ]] || die '找不到 Zinit 的 zinit.zsh。'
    if [[ "$PLATFORM" = mac ]]; then
        "$BREW_BIN" list --cask kitty brave-browser >/dev/null
    elif [[ "$PLATFORM" = arch ]]; then
        pacman -Q kitty brave-bin >/dev/null
    fi
}

cleanup() {
    if [[ -n ${SETUP_TMP_DIR:-} && -d "$SETUP_TMP_DIR" ]]; then rm -rf -- "$SETUP_TMP_DIR"; fi
    if [[ -n ${LOCK_DIR:-} && -d "$LOCK_DIR" ]]; then
        rm -f "$LOCK_DIR/pid"
        rmdir "$LOCK_DIR" 2>/dev/null || true
    fi
}

main() {
    parse_args "$@"
    init_paths
    select_platform
    show_plan
    if ((DRY_RUN)); then log '預覽完成，沒有變更檔案或安裝套件。'; return 0; fi
    detect_platform
    umask 077
    mkdir -p "$BIN_DIR" "$DATA_DIR/bin" "$STATE_DIR" "$CONFIG_DIR"
    LOCK_DIR="$STATE_DIR/install.lock"
    mkdir "$LOCK_DIR" 2>/dev/null || die "另一個安裝正在執行，或上次意外中斷留下鎖定：$LOCK_DIR"
    trap cleanup EXIT
    printf '%s\n' "$$" > "$LOCK_DIR/pid"
    SETUP_TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles.XXXXXXXX")
    trap 'printf "\n[錯誤] 安裝在第 %s 行停止；修正後可重新執行。\n" "$LINENO" >&2' ERR
    local log_file="$STATE_DIR/install-$RUN_ID.log"
    exec > >(tee -a "$log_file") 2>&1
    export PATH="$BIN_DIR:$PATH"
    if ((!LINKS_ONLY)); then
        case "$PLATFORM" in
            mac) install_mac ;;
            arch) install_arch ;;
            ubuntu) install_ubuntu ;;
        esac
        # The environment is needed to find Homebrew LLVM and Ubuntu nvm tools.
        write_shell_config
        # shellcheck disable=SC1090
        set +u
        . "$SHELL_FILE"
        set -u
        verify_installation
    fi
    install_dotfiles
    set_login_shell
    log '完成；請重新登入，或執行 zsh。首次開啟 zsh / Neovim 時會下載各自的外掛。'
    printf '安裝紀錄：%s\n備份位置：%s\n' "$log_file" "$BACKUP_DIR"
}

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
    main "$@"
fi
