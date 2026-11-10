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

預設完整安裝，包含 Node.js / 語言伺服器、Rust / Cargo、Bun / bunx。
執行時會詢問 Git 的 name 與 email，並儲存為目前帳號的全域設定。

選項：
  --platform NAME   指定 mac、arch、ubuntu（可搭配 --dry-run 檢視其他平台）
  --set-shell       啟用 zsh（Ubuntu 使用使用者的 Bash 啟動設定，不需要 sudo）
  --links-only      只建立 dotfiles 連結；不安裝套件、不改登入 shell
  --dry-run         僅顯示計畫，不下載、不寫入檔案
  -h, --help        顯示說明

Ubuntu 可指定 NVIM_VERSION / TREE_SITTER_VERSION，預設 latest 正式版。
Ubuntu 使用 NVM_VERSION（預設 v0.41.0）、TOOL_PYTHON_VERSION（預設 3.11）。
Arch 若沒有 yay，會使用 AUR 的 yay-bin PKGBUILD 及 makepkg 建立，不執行網路 shell installer。
macOS 需要先有 Homebrew；未安裝時請先依 https://brew.sh 完成安裝。
Ubuntu 全程安裝到使用者目錄，缺少的基礎工具由官方 micromamba / conda-forge 提供。
所有平台都會先檢查已有工具，僅安裝缺少的項目。
EOF
}

log() { printf '\n[dotfiles] %s\n' "$*"; }
die() { printf '\n[錯誤] %s\n' "$*" >&2; exit 1; }

parse_args() {
    SET_SHELL=0 DRY_RUN=0 LINKS_ONLY=0
    PLATFORM=auto
    while (($#)); do
        case "$1" in
            --platform)
                [[ $# -ge 2 ]] || die '--platform 需要 mac、arch 或 ubuntu。'
                PLATFORM=$2
                case "$PLATFORM" in mac|arch|ubuntu) ;; *) die '平台只接受 mac、arch、ubuntu。' ;; esac
                shift ;;
            --set-shell) SET_SHELL=1 ;;
            --links-only) LINKS_ONLY=1 ;;
            --dry-run) DRY_RUN=1 ;;
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
    UBUNTU_ENV="$DATA_DIR/ubuntu-env"
    MAMBA_CACHE_ROOT="$DATA_DIR/mamba-root"
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
    if ((LINKS_ONLY)); then
        printf '  模式：只建立設定連結\n'
    else
        printf '  模式：完整安裝，包含 Node / 語言伺服器、Rust / Cargo、Bun / bunx\n'
    fi
    case "$PLATFORM" in
        mac) printf '  工具：Homebrew；桌面程式：brew cask kitty、brave-browser\n' ;;
        arch) printf '  工具：pacman / yay；桌面程式：kitty、brave-bin\n  pacman -Syu 會完整更新 Arch 系統。\n' ;;
        ubuntu) printf '  工具：已有項目略過；缺少的工具使用官方網址及 micromamba，全部在使用者目錄、無 sudo\n' ;;
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
        die '請以一般帳號執行；不要 sudo bash install.sh。'
    fi
    [[ -f "$DOTFILES_DIR/zshrc" && -d "$DOTFILES_DIR/config" ]] || die '請保留完整 dotfiles repository 再執行安裝。'
}

as_root() {
    [[ ${PLATFORM:-} != ubuntu ]] || die 'Ubuntu 版只允許使用者目錄操作，不會呼叫 sudo。'
    if ((EUID == 0)); then "$@"; else sudo "$@"; fi
}

# Record only additions made by this setup; existing installations stay unowned.
record_package_additions() {
    local manager=$1 package present
    shift
    [[ -n ${OWNERSHIP_DIR:-} ]] || return 0
    mkdir -p "$OWNERSHIP_DIR/packages/$manager"
    for package in "$@"; do
        present=0
        case "$manager" in
            brew-formula) "$BREW_BIN" list --formula --versions "$package" >/dev/null 2>&1 && present=1 ;;
            brew-cask) "$BREW_BIN" list --cask --versions "$package" >/dev/null 2>&1 && present=1 ;;
            pacman) pacman -Q "$package" >/dev/null 2>&1 && present=1 ;;
        esac
        if ((!present)); then : > "$OWNERSHIP_DIR/packages/$manager/$package"; fi
    done
}

record_owned_path() {
    local path=$1
    [[ -n ${OWNERSHIP_DIR:-} ]] || return 0
    # The journal is data, never sourced as shell code.
    [[ "$path" = "$SETUP_USER_HOME/"* && "$path" != *$'\n'* && "$path" != *$'\t'* ]] || return 0
    touch "$OWNERSHIP_DIR/paths"
    grep -Fxq -- "$path" "$OWNERSHIP_DIR/paths" || printf '%s\n' "$path" >> "$OWNERSHIP_DIR/paths"
}

record_path_if_new() {
    [[ -e "$1" || -L "$1" ]] || record_owned_path "$1"
}

snapshot_git_setting() {
    local key=$1
    [[ -n ${OWNERSHIP_DIR:-} ]] || return 0
    [[ ! -f "$OWNERSHIP_DIR/git-$key.captured" ]] || return 0
    if command -v git >/dev/null; then
        git config --global --get-all "user.$key" > "$OWNERSHIP_DIR/git-$key.before" 2>/dev/null || true
    else
        : > "$OWNERSHIP_DIR/git-$key.before"
    fi
    : > "$OWNERSHIP_DIR/git-$key.captured"
}

begin_ownership_tracking() {
    mkdir -p "$OWNERSHIP_DIR"
    printf '1\n' > "$OWNERSHIP_DIR/version"
    snapshot_git_setting name
    snapshot_git_setting email
    local path
    for path in "${XDG_DATA_HOME:-$SETUP_USER_HOME/.local/share}/zinit" \
                "${XDG_CACHE_HOME:-$SETUP_USER_HOME/.cache}/zinit" \
                "${XDG_DATA_HOME:-$SETUP_USER_HOME/.local/share}/nvim" \
                "${XDG_STATE_HOME:-$SETUP_USER_HOME/.local/state}/nvim" \
                "${XDG_CACHE_HOME:-$SETUP_USER_HOME/.cache}/nvim"; do
        record_path_if_new "$path"
    done
    if [[ "$PLATFORM" = ubuntu ]]; then
        for path in "$DATA_DIR/neovim" \
                    "$DATA_DIR/bin/fzf" "$DATA_DIR/bin/zoxide" "$DATA_DIR/bin/tree-sitter" \
                    "$DATA_DIR/bin/bun" \
                    "$DATA_DIR/bin/micromamba" "$UBUNTU_ENV" "$MAMBA_CACHE_ROOT" "$DATA_DIR/wrappers" \
                    "$SETUP_USER_HOME/.local/share/man/man1/zoxide.1" \
                    "$SETUP_USER_HOME/.local/share/man/man1/zi.1"; do
            record_path_if_new "$path"
        done
    fi
}

download() {
    local url=$1 destination=$2
    if command -v curl >/dev/null 2>&1; then
        curl --fail --location --silent --show-error --retry 3 --connect-timeout 15 --output "$destination.part" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -q --tries=3 --timeout=30 -O "$destination.part" "$url"
    elif command -v python3 >/dev/null 2>&1; then
        python3 - "$url" "$destination.part" <<'PY'
import sys, urllib.request
urllib.request.urlretrieve(sys.argv[1], sys.argv[2])
PY
    else
        die '首次下載需要 curl、wget 或 Python 3 其中之一；亦可預先放入 micromamba 執行檔。'
    fi
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
    if [[ -n ${OWNERSHIP_DIR:-} ]]; then
        local entry
        printf -v entry '%s\t%s' "$destination" "$source"
        touch "$OWNERSHIP_DIR/links"
        grep -Fxq -- "$entry" "$OWNERSHIP_DIR/links" || printf '%s\n' "$entry" >> "$OWNERSHIP_DIR/links"
    fi
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
    if command -v uv >/dev/null 2>&1; then
        UV_BIN=$(command -v uv)
        log "沿用 uv：$UV_BIN"
    else
        record_path_if_new "$BIN_DIR/uv"
        record_path_if_new "$BIN_DIR/uvx"
        download https://astral.sh/uv/install.sh "$SETUP_TMP_DIR/uv-install.sh"
        env UV_INSTALL_DIR="$BIN_DIR" UV_NO_MODIFY_PATH=1 sh "$SETUP_TMP_DIR/uv-install.sh"
        UV_BIN="$BIN_DIR/uv"
    fi
    "$UV_BIN" --version
    if command -v pynvim-python >/dev/null 2>&1; then log 'pynvim 已存在，略過。'; return 0; fi
    if [[ -n ${OWNERSHIP_DIR:-} ]] && ! "$UV_BIN" tool list | grep -q '^pynvim '; then
        : > "$OWNERSHIP_DIR/pynvim-added"
        "$UV_BIN" tool dir > "$OWNERSHIP_DIR/pynvim-tool-dir"
    fi
    env UV_TOOL_BIN_DIR="$BIN_DIR" "$UV_BIN" tool install --python "$TOOL_PYTHON" pynvim
}

install_neovim() {
    if command -v nvim >/dev/null 2>&1; then log "沿用 Neovim：$(command -v nvim)"; return 0; fi
    log '安裝 Neovim'
    local target="$DATA_DIR/neovim" asset="nvim-linux-$NVIM_ARCH.tar.gz"
    if [[ ! -x "$target/bin/nvim" ]]; then
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
    if command -v fzf >/dev/null 2>&1; then log "沿用 fzf：$(command -v fzf)"; return 0; fi
    log '安裝 fzf'
    local target="$DATA_DIR/bin/fzf"
    if [[ ! -x "$target" ]]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git "$SETUP_TMP_DIR/fzf"
        bash "$SETUP_TMP_DIR/fzf/install" --bin
        "$SETUP_TMP_DIR/fzf/bin/fzf" --version
        publish_file "$SETUP_TMP_DIR/fzf/bin/fzf" "$target"
    fi
    safe_link "$target" "$BIN_DIR/fzf"
}

install_zoxide() {
    if command -v zoxide >/dev/null 2>&1; then log "沿用 zoxide：$(command -v zoxide)"; return 0; fi
    log '安裝 zoxide'
    local target="$DATA_DIR/bin/zoxide"
    if [[ ! -x "$target" ]]; then
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
    if command -v tree-sitter >/dev/null 2>&1; then log "沿用 Tree-sitter：$(command -v tree-sitter)"; return 0; fi
    log '安裝 Tree-sitter CLI（官方預編譯版本）'
    local target="$DATA_DIR/bin/tree-sitter" asset="tree-sitter-linux-$TS_ARCH.gz"
    if [[ ! -x "$target" ]]; then
        download "$(release_url tree-sitter/tree-sitter "$TREE_SITTER_TAG" "$asset")" "$SETUP_TMP_DIR/tree-sitter.gz"
        gzip -dc "$SETUP_TMP_DIR/tree-sitter.gz" > "$SETUP_TMP_DIR/tree-sitter"
        chmod 755 "$SETUP_TMP_DIR/tree-sitter"
        "$SETUP_TMP_DIR/tree-sitter" --version || die 'Tree-sitter 無法執行；可指定與系統/外掛相容的版本。'
        publish_file "$SETUP_TMP_DIR/tree-sitter" "$target"
    fi
    safe_link "$target" "$BIN_DIR/tree-sitter"
}

install_node() {
    log '安裝 nvm / Node.js LTS / Pyright / Bash / TypeScript 語言伺服器'
    local have_node=0
    USE_NVM=0
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then have_node=1; fi
    if ((!have_node)) || [[ $(command -v node 2>/dev/null || true) = "$SETUP_NVM_DIR/"* ]]; then USE_NVM=1; fi
    if ((have_node)) && command -v pyright >/dev/null 2>&1 && command -v bash-language-server >/dev/null 2>&1 \
       && command -v typescript-language-server >/dev/null 2>&1 && command -v tsc >/dev/null 2>&1; then
        log 'Node.js 與語言伺服器均已存在，略過。'
        return 0
    fi
    if ((!have_node)) && [[ ! -s "$SETUP_NVM_DIR/nvm.sh" ]]; then
        record_path_if_new "$SETUP_NVM_DIR"
        mkdir -p "$SETUP_NVM_DIR"
        download "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_TAG/install.sh" "$SETUP_TMP_DIR/nvm-install.sh"
        env NVM_DIR="$SETUP_NVM_DIR" PROFILE=/dev/null bash "$SETUP_TMP_DIR/nvm-install.sh"
    fi
    (
        # nvm is a sourced third-party shell library; it does not require nounset.
        set +u
        export NVM_DIR="$SETUP_NVM_DIR"
        local version versions_before='' prefix npm_record package
        if ((!have_node)); then
        # shellcheck disable=SC1091
        . "$NVM_DIR/nvm.sh"
        for version in "$NVM_DIR"/versions/node/*; do
            [[ ! -d "$version" ]] || versions_before+="$version"$'\n'
        done
        if [[ -n ${OWNERSHIP_DIR:-} && ! -f "$OWNERSHIP_DIR/nvm-alias.captured" ]]; then
            if [[ -f "$NVM_DIR/alias/default" ]]; then
                cp "$NVM_DIR/alias/default" "$OWNERSHIP_DIR/nvm-alias.before"
            fi
            : > "$OWNERSHIP_DIR/nvm-alias.captured"
        fi
        if nvm use --silent default >/dev/null 2>&1 || nvm use --silent node >/dev/null 2>&1; then
            log '沿用 nvm 中已安裝的 Node.js。'
        else
            nvm install --lts
            nvm alias default 'lts/*'
        fi
        version=$(dirname "$(dirname "$(command -v node)")")
        if ! printf '%s' "$versions_before" | grep -Fxq -- "$version"; then record_owned_path "$version"; fi
        fi
        prefix=$(npm prefix --global)
        if [[ "$prefix" != "$SETUP_USER_HOME/"* || ! -w "$prefix" ]]; then
            prefix="$DATA_DIR/npm-global"
            record_path_if_new "$prefix"
            mkdir -p "$prefix"
            export npm_config_prefix="$prefix"
            export PATH="$prefix/bin:$PATH"
        fi
        if [[ -n ${OWNERSHIP_DIR:-} ]]; then
            prefix=$(npm prefix --global)
            mkdir -p "$OWNERSHIP_DIR/npm"
            npm_record=$(printf '%s' "$prefix" | cksum)
            npm_record="$OWNERSHIP_DIR/npm/${npm_record%% *}"
            mkdir -p "$npm_record"
            printf '%s\n' "$prefix" > "$npm_record/prefix"
            command -v npm > "$npm_record/npm-bin"
            dirname "$(command -v node)" > "$npm_record/node-bin"
        fi
        for package in pyright bash-language-server typescript-language-server typescript; do
            local executable=$package
            [[ "$package" != typescript ]] || executable=tsc
            if command -v "$executable" >/dev/null 2>&1; then log "$executable 已存在，略過。"; continue; fi
            if [[ -n ${OWNERSHIP_DIR:-} ]]; then : > "$npm_record/package-$package"; fi
            npm install --global "$package"
        done
        node --version
        npm --version
        pyright --version
    )
}

install_rust() {
    USE_CARGO_ENV=0
    if command -v cargo >/dev/null 2>&1 && command -v rustc >/dev/null 2>&1; then
        [[ $(command -v cargo) != "$SETUP_CARGO_DIR/"* ]] || USE_CARGO_ENV=1
        log 'Rust / Cargo 已存在，略過。'; return 0
    fi
    USE_CARGO_ENV=1
    log '安裝 Rust / Cargo'
    if [[ ! -x "$SETUP_CARGO_DIR/bin/rustup" ]]; then
        record_path_if_new "$SETUP_CARGO_DIR"
        record_path_if_new "${RUSTUP_HOME:-$SETUP_USER_HOME/.rustup}"
        download https://sh.rustup.rs "$SETUP_TMP_DIR/rustup-install.sh"
        env CARGO_HOME="$SETUP_CARGO_DIR" sh "$SETUP_TMP_DIR/rustup-install.sh" \
            -y --profile minimal --default-toolchain stable --no-modify-path
    fi
    "$SETUP_CARGO_DIR/bin/cargo" --version
}

install_bun() {
    if command -v bun >/dev/null 2>&1; then
        if ! command -v bunx >/dev/null 2>&1; then safe_link "$(command -v bun)" "$BIN_DIR/bunx"; fi
        log 'Bun 已存在，略過下載。'; return 0
    fi
    log '安裝 Bun'
    local target="$DATA_DIR/bin/bun" asset_target="linux-$BUN_ARCH"
    if [[ ! -x "$target" ]]; then
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
tool_available_for_package() {
    case "$1" in
        python|python3) command -v python3 >/dev/null 2>&1 ;;
        openssh|openssh-client) command -v ssh >/dev/null 2>&1 && command -v ssh-keygen >/dev/null 2>&1 ;;
        llvm|clang) command -v clangd >/dev/null 2>&1 ;;
        node|nodejs) command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1 ;;
        rust) command -v cargo >/dev/null 2>&1 && command -v rustc >/dev/null 2>&1 ;;
        bun|bun-bin) command -v bun >/dev/null 2>&1 && command -v bunx >/dev/null 2>&1 ;;
        neovim) command -v nvim >/dev/null 2>&1 ;;
        ripgrep) command -v rg >/dev/null 2>&1 ;;
        tree-sitter-cli) command -v tree-sitter >/dev/null 2>&1 ;;
        python-pynvim) command -v pynvim-python >/dev/null 2>&1 ;;
        typescript) command -v tsc >/dev/null 2>&1 ;;
        brave-bin|brave-browser)
            command -v brave >/dev/null 2>&1 || command -v brave-browser >/dev/null 2>&1 || [[ -d '/Applications/Brave Browser.app' ]] ;;
        kitty) command -v kitty >/dev/null 2>&1 || [[ -d /Applications/kitty.app ]] ;;
        base-devel) command -v cc >/dev/null 2>&1 && command -v make >/dev/null 2>&1 && command -v fakeroot >/dev/null 2>&1 ;;
        ca-certificates) return 1 ;;
        *) command -v "$1" >/dev/null 2>&1 ;;
    esac
}

filter_missing_packages() {
    local manager=$1 package exists
    shift
    MISSING_PACKAGES=()
    for package in "$@"; do
        exists=0
        if tool_available_for_package "$package"; then exists=1; else
            case "$manager" in
                brew-formula) "$BREW_BIN" list --formula --versions "$package" >/dev/null 2>&1 && exists=1 ;;
                brew-cask) "$BREW_BIN" list --cask --versions "$package" >/dev/null 2>&1 && exists=1 ;;
                pacman) pacman -Q "$package" >/dev/null 2>&1 && exists=1 ;;
            esac
        fi
        if ((exists)); then log "$package 已存在，略過。"; else MISSING_PACKAGES+=("$package"); fi
    done
}

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
                    zoxide uv tree-sitter-cli llvm bat ripgrep fd
                    node pyright bash-language-server typescript-language-server typescript rust bun)
    local casks=(kitty brave-browser)
    filter_missing_packages brew-formula "${formulas[@]}"
    # Bash 3.2 with nounset needs the + form when an array is empty.
    formulas=(${MISSING_PACKAGES[@]+"${MISSING_PACKAGES[@]}"})
    filter_missing_packages brew-cask "${casks[@]}"
    casks=(${MISSING_PACKAGES[@]+"${MISSING_PACKAGES[@]}"})
    if ((${#formulas[@]} + ${#casks[@]})); then "$BREW_BIN" update; fi
    if ((${#formulas[@]})); then
        record_package_additions brew-formula "${formulas[@]}"
        "$BREW_BIN" install --formula "${formulas[@]}"
    fi
    if ((${#casks[@]})); then
        record_package_additions brew-cask "${casks[@]}"
        "$BREW_BIN" install --cask "${casks[@]}"
    fi
}

# -------------------------- Arch: pacman / yay ----------------------------
ensure_yay() {
    command -v yay >/dev/null 2>&1 && return 0
    record_package_additions pacman yay-bin
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
                    zsh tmux neovim fzf zoxide uv tree-sitter-cli clang bat ripgrep fd unzip kitty
                    nodejs npm pyright bash-language-server typescript-language-server typescript rust)
    filter_missing_packages pacman "${packages[@]}"
    packages=(${MISSING_PACKAGES[@]+"${MISSING_PACKAGES[@]}"})
    if ((${#packages[@]})); then
        record_package_additions pacman "${packages[@]}"
        as_root pacman -Syu --needed --noconfirm "${packages[@]}"
    fi
    local aur_packages=(brave-bin bun-bin)
    filter_missing_packages pacman "${aur_packages[@]}"
    aur_packages=(${MISSING_PACKAGES[@]+"${MISSING_PACKAGES[@]}"})
    if ((${#aur_packages[@]})); then
        ensure_yay
        record_package_additions pacman "${aur_packages[@]}"
        log 'Arch：使用 yay 安裝 AUR 套件'
        yay -S --needed --noconfirm "${aur_packages[@]}"
    fi
}

# ----------------------- Ubuntu: user-local only -------------------------
install_ubuntu_base() {
    local packages=() wrappers=() package tool implementation item executable action=install
    local specs=(git:git:git curl:curl:curl wget:wget:wget jq:jq:jq
                 "python=$TOOL_PYTHON:python3:python3" zsh:zsh:zsh tmux:tmux:tmux
                 clang-tools:clangd:clangd bat:bat:bat ripgrep:rg:rg fd-find:fd:fd
                 unzip:unzip:unzip make:make:make pkg-config:pkg-config:pkg-config
                 c-compiler:cc:cc c-compiler:gcc:gcc cxx-compiler:c++:c++ cxx-compiler:g++:g++)
    for item in "${specs[@]}"; do
        package=${item%%:*}; item=${item#*:}; tool=${item%%:*}; implementation=${item#*:}
        if command -v "$tool" >/dev/null 2>&1; then log "$tool 已存在，略過。"; continue; fi
        if [[ "$tool" = bat ]] && command -v batcat >/dev/null 2>&1; then safe_link "$(command -v batcat)" "$BIN_DIR/bat"; continue; fi
        if [[ "$tool" = fd ]] && command -v fdfind >/dev/null 2>&1; then safe_link "$(command -v fdfind)" "$BIN_DIR/fd"; continue; fi
        wrappers+=("$tool:$implementation")
        local found=0 candidate
        for candidate in ${packages[@]+"${packages[@]}"}; do [[ "$candidate" != "$package" ]] || found=1; done
        ((found)) || packages+=("$package")
    done
    ((${#packages[@]})) || return 0
    if command -v micromamba >/dev/null 2>&1; then
        MICROMAMBA_BIN=$(command -v micromamba)
    else
        MICROMAMBA_BIN="$DATA_DIR/bin/micromamba"
        if [[ ! -x "$MICROMAMBA_BIN" ]]; then
            local arch=linux-64
            [[ "$NVIM_ARCH" != arm64 ]] || arch=linux-aarch64
            download "$(release_url mamba-org/micromamba-releases latest "micromamba-$arch")" "$SETUP_TMP_DIR/micromamba"
            chmod 755 "$SETUP_TMP_DIR/micromamba"
            "$SETUP_TMP_DIR/micromamba" --version
            publish_file "$SETUP_TMP_DIR/micromamba" "$MICROMAMBA_BIN"
        fi
        safe_link "$MICROMAMBA_BIN" "$BIN_DIR/micromamba"
    fi
    [[ -f "$UBUNTU_ENV/conda-meta/history" ]] || action=create
    log '使用 micromamba 安裝缺少的基礎工具（使用者目錄）'
    if [[ "$action" = create ]]; then
        env MAMBA_ROOT_PREFIX="$MAMBA_CACHE_ROOT" "$MICROMAMBA_BIN" --no-rc create --yes --prefix "$UBUNTU_ENV" --override-channels --channel conda-forge "${packages[@]}"
    else
        env MAMBA_ROOT_PREFIX="$MAMBA_CACHE_ROOT" "$MICROMAMBA_BIN" --no-rc install --yes --freeze-installed --prefix "$UBUNTU_ENV" --override-channels --channel conda-forge "${packages[@]}"
    fi
    mkdir -p "$DATA_DIR/wrappers"
    for item in "${wrappers[@]}"; do
        tool=${item%%:*}; implementation=${item#*:}
        executable="$UBUNTU_ENV/bin/$implementation"
        [[ -x "$executable" ]] || die "micromamba 安裝後找不到 $implementation。"
        {
            printf '#!/usr/bin/env bash\n# Managed by dotfiles micromamba.\n'
            case "$tool" in
                cc|gcc|c++|g++) printf 'export MAMBA_ROOT_PREFIX=%q\nexec %q run --no-capture-output --prefix %q %q "$@"\n' "$MAMBA_CACHE_ROOT" "$MICROMAMBA_BIN" "$UBUNTU_ENV" "$implementation" ;;
                *) printf 'exec %q "$@"\n' "$executable" ;;
            esac
        } > "$SETUP_TMP_DIR/wrapper"
        publish_file "$SETUP_TMP_DIR/wrapper" "$DATA_DIR/wrappers/$tool"
        safe_link "$DATA_DIR/wrappers/$tool" "$BIN_DIR/$tool"
    done
    hash -r
}

install_ubuntu() {
    install_ubuntu_base
    install_uv
    install_neovim
    install_fzf
    install_zoxide
    install_tree_sitter
    install_node
    install_rust
    install_bun
}

prompt_git_identity() {
    [[ -t 0 ]] || die '需要在終端機互動輸入 Git name 與 email；請直接執行腳本，遠端執行時請配置 TTY。'
    local current_name='' current_email='' entered
    if command -v git >/dev/null 2>&1; then
        current_name=$(git config --global --get user.name 2>/dev/null || true)
        current_email=$(git config --global --get user.email 2>/dev/null || true)
    fi
    log '設定 Git 全域身分'
    while :; do
        if [[ -n "$current_name" ]]; then
            read -r -p "Git user.name [$current_name]：" entered || die 'Git name 輸入已中止。'
            GIT_SETUP_NAME=${entered:-$current_name}
        else
            read -r -p 'Git user.name：' GIT_SETUP_NAME || die 'Git name 輸入已中止。'
        fi
        [[ -n ${GIT_SETUP_NAME//[[:space:]]/} ]] && break
        printf 'name 不能空白，請重新輸入。\n' >&2
    done
    while :; do
        if [[ -n "$current_email" ]]; then
            read -r -p "Git user.email [$current_email]：" entered || die 'Git email 輸入已中止。'
            GIT_SETUP_EMAIL=${entered:-$current_email}
        else
            read -r -p 'Git user.email：' GIT_SETUP_EMAIL || die 'Git email 輸入已中止。'
        fi
        [[ "$GIT_SETUP_EMAIL" =~ ^[^[:space:]@]+@[^[:space:]@]+$ ]] && break
        printf '請輸入有效的 email，例如 name@example.com。\n' >&2
    done
}

configure_git_identity() {
    log '儲存 Git 全域 name 與 email'
    git config --global -- user.name "$GIT_SETUP_NAME"
    git config --global -- user.email "$GIT_SETUP_EMAIL"
    if [[ -n ${OWNERSHIP_DIR:-} ]]; then
        printf '%s\n' "$GIT_SETUP_NAME" > "$OWNERSHIP_DIR/git-name.applied"
        printf '%s\n' "$GIT_SETUP_EMAIL" > "$OWNERSHIP_DIR/git-email.applied"
    fi
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
    printf '# Managed by dotfiles install.sh\n' > "$staged"
    if [[ "$PLATFORM" = mac ]]; then
        printf 'eval "$(%q shellenv bash)"\n' "$BREW_BIN" >> "$staged"
        printf 'case ":$PATH:" in *":%s:"*) ;; *) export PATH=%q:"$PATH" ;; esac\n' \
            "$BREW_PREFIX/opt/llvm/bin" "$BREW_PREFIX/opt/llvm/bin" >> "$staged"
    fi
    cat >> "$staged" <<'EOF'
case "$PATH" in
    "$HOME/.local/bin"|"$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
EOF
    if [[ "$PLATFORM" = ubuntu && ${USE_NVM:-0} = 1 && -s "$SETUP_NVM_DIR/nvm.sh" ]]; then
        printf '\nexport NVM_DIR=%q\n[ ! -s "$NVM_DIR/nvm.sh" ] || . "$NVM_DIR/nvm.sh"\n' "$SETUP_NVM_DIR" >> "$staged"
    fi
    if [[ "$PLATFORM" = ubuntu && ${USE_CARGO_ENV:-0} = 1 && -s "$SETUP_CARGO_DIR/env" ]]; then
        printf '\n. %q\n' "$SETUP_CARGO_DIR/env" >> "$staged"
    fi
    if [[ "$PLATFORM" = ubuntu && -d "$DATA_DIR/npm-global/bin" ]]; then
        printf '\nexport PATH=%q:"$PATH"\n' "$DATA_DIR/npm-global/bin" >> "$staged"
    fi
    cat >> "$staged" <<'EOF'
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
case ":$PATH:" in
    *":$BUN_INSTALL/bin:"*) ;;
    *) export PATH="$BUN_INSTALL/bin:$PATH" ;;
esac
EOF
    publish_file "$staged" "$SHELL_FILE" 600
    if [[ -n ${OWNERSHIP_DIR:-} ]]; then
        cksum < "$SHELL_FILE" > "$OWNERSHIP_DIR/env.cksum"
    fi
    bash -n "$SHELL_FILE"
    if command -v zsh >/dev/null; then zsh -n "$SHELL_FILE"; fi
}

set_login_shell() {
    ((SET_SHELL)) || return 0
    log '設定登入 shell 為 zsh'
    local zsh_path login_user current_shell
    zsh_path=$(command -v zsh)
    if [[ "$PLATFORM" = ubuntu ]]; then
        log 'Ubuntu：以個人 Bash 啟動設定進入 zsh，不呼叫 sudo 或修改系統 shell 清單。'
        local bashrc="$SETUP_USER_HOME/.bashrc" marker='# dotfiles: auto-start zsh' staged="$SETUP_TMP_DIR/bashrc"
        if [[ -f "$bashrc" ]] && grep -Fxq "$marker" "$bashrc"; then return 0; fi
        if [[ -f "$bashrc" ]]; then cat "$bashrc" > "$staged"; else : > "$staged"; fi
        {
            printf '\n%s\n' "$marker"
            printf 'if [[ $- == *i* && -z ${DOTFILES_ZSH_AUTO_STARTED:-} ]]; then\n'
            printf '  export DOTFILES_ZSH_AUTO_STARTED=1\n  exec %q\nfi\n' "$zsh_path"
            printf '# dotfiles: end auto-start zsh\n'
        } >> "$staged"
        publish_file "$staged" "$bashrc" 600
        if [[ -n ${OWNERSHIP_DIR:-} ]]; then : > "$OWNERSHIP_DIR/bashrc-hook"; fi
        return 0
    fi
    login_user=$(id -un)
    if [[ "$PLATFORM" = mac ]]; then
        current_shell=$(dscl . -read "/Users/$login_user" UserShell | awk '{print $2}')
    else
        current_shell=$(getent passwd "$login_user" | cut -d: -f7)
    fi
    [[ "$current_shell" != "$zsh_path" ]] || return 0
    if [[ -n ${OWNERSHIP_DIR:-} && ! -f "$OWNERSHIP_DIR/shell.before" ]]; then
        printf '%s\n' "$current_shell" > "$OWNERSHIP_DIR/shell.before"
    fi
    if ! grep -Fxq "$zsh_path" /etc/shells; then
        [[ "$PLATFORM" = mac ]] || die 'zsh 不在 /etc/shells 中。'
        printf '%s\n' "$zsh_path" | as_root tee -a /etc/shells >/dev/null
    fi
    as_root chsh -s "$zsh_path" "$login_user"
    if [[ -n ${OWNERSHIP_DIR:-} ]]; then printf '%s\n' "$zsh_path" > "$OWNERSHIP_DIR/shell.applied"; fi
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
        tool_root=$(uv tool dir)
        if [[ -x "$tool_root/pynvim/bin/python" ]]; then
            "$tool_root/pynvim/bin/python" -c 'import pynvim; print("pynvim: OK")'
        else
            command -v pynvim-python >/dev/null || die '找不到 pynvim provider。'
        fi
    elif [[ "$PLATFORM" = arch ]]; then
        command -v pynvim-python >/dev/null || /usr/bin/python -c 'import pynvim; print("pynvim: OK")'
    fi
    for tool in node npm pyright bash-language-server typescript-language-server; do
        command -v "$tool" >/dev/null || die "找不到：$tool"
    done
    cargo --version
    bun --version
    if [[ "$PLATFORM" = mac ]]; then
        tool_available_for_package kitty || "$BREW_BIN" list --cask kitty >/dev/null
        tool_available_for_package brave-browser || "$BREW_BIN" list --cask brave-browser >/dev/null
    elif [[ "$PLATFORM" = arch ]]; then
        tool_available_for_package kitty || pacman -Q kitty >/dev/null
        tool_available_for_package brave-bin || pacman -Q brave-bin >/dev/null
    fi
}

cleanup() {
    if [[ -n ${SETUP_TMP_DIR:-} && -d "$SETUP_TMP_DIR" ]]; then rm -rf -- "$SETUP_TMP_DIR"; fi
    if [[ -n ${LOCK_DIR:-} && -d "$LOCK_DIR" ]]; then
        rm -f "$LOCK_DIR/pid"
        rmdir "$LOCK_DIR" 2>/dev/null || true
    fi
}

start_logging() {
    exec > >(tee -a "$1") 2>&1
}

main() {
    parse_args "$@"
    init_paths
    select_platform
    OWNERSHIP_DIR="$STATE_DIR/ownership/$PLATFORM"
    show_plan
    if ((DRY_RUN)); then log '預覽完成，沒有變更檔案或安裝套件。'; return 0; fi
    detect_platform
    if ((!LINKS_ONLY)); then prompt_git_identity; fi
    umask 077
    mkdir -p "$BIN_DIR" "$DATA_DIR/bin" "$STATE_DIR" "$CONFIG_DIR"
    LOCK_DIR="$STATE_DIR/install.lock"
    mkdir "$LOCK_DIR" 2>/dev/null || die "另一個安裝正在執行，或上次意外中斷留下鎖定：$LOCK_DIR"
    trap cleanup EXIT
    printf '%s\n' "$$" > "$LOCK_DIR/pid"
    SETUP_TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles.XXXXXXXX")
    trap 'printf "\n[錯誤] 安裝在第 %s 行停止；修正後可重新執行。\n" "$LINENO" >&2' ERR
    local log_file="$STATE_DIR/install-$RUN_ID.log"
    start_logging "$log_file"
    begin_ownership_tracking
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
        configure_git_identity
    fi
    install_dotfiles
    set_login_shell
    log '完成；請重新登入，或執行 zsh。首次開啟 zsh 時會自動安裝 Zinit 與外掛，Neovim 會下載自己的外掛。'
    printf '安裝紀錄：%s\n備份位置：%s\n' "$log_file" "$BACKUP_DIR"
}

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
    main "$@"
fi
