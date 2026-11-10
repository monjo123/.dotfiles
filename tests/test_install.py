"""Offline installer checks; no real package installation or HOME reassignment."""
import gzip
import io
import os
from pathlib import Path
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "install.sh"
PASSED = []


def bash(body, extra=None, success=True):
    env = dict(os.environ, INSTALL_SCRIPT=str(SCRIPT))
    env.update(extra or {})
    result = subprocess.run(
        ["bash", "-c", body], env=env, capture_output=True,
        text=True, encoding="utf-8", errors="replace",
    )
    assert (result.returncode == 0) == success, (
        f"Unexpected exit {result.returncode}\n{result.stdout}\n{result.stderr}"
    )
    return result


SETUP = r'''
. "$INSTALL_SCRIPT"
parse_args
init_paths
SETUP_USER_HOME="$TEST_ROOT/user space"
BIN_DIR="$SETUP_USER_HOME/.local/bin"
DATA_DIR="$SETUP_USER_HOME/.local/share/dotfiles"
STATE_DIR="$SETUP_USER_HOME/.local/state/dotfiles"
CONFIG_ROOT="$SETUP_USER_HOME/.config"
CONFIG_DIR="$CONFIG_ROOT/dotfiles"
SHELL_FILE="$CONFIG_DIR/env.sh"
DOTFILES_DIR="$TEST_ROOT/repository space"
SETUP_NVM_DIR="$SETUP_USER_HOME/.nvm"
SETUP_CARGO_DIR="$SETUP_USER_HOME/.cargo"
BACKUP_DIR="$STATE_DIR/backups/test-run"
SETUP_TMP_DIR="$TEST_ROOT/staging"
NVIM_ARCH=x86_64 TS_ARCH=x64 BUN_ARCH=x64
mkdir -p "$BIN_DIR" "$DATA_DIR/bin" "$CONFIG_DIR" "$SETUP_TMP_DIR"
mkdir -p "$DOTFILES_DIR/config/nvim" "$DOTFILES_DIR/config/kitty"
printf '# test zshrc\n' > "$DOTFILES_DIR/zshrc"
printf '# test p10k\n' > "$DOTFILES_DIR/p10k.zsh"
printf 'test flags\n' > "$DOTFILES_DIR/config/brave-flags.conf"
'''


def check(name, body, success=True, prepare=None):
    with tempfile.TemporaryDirectory(prefix="dotfiles-test-") as temp:
        if prepare:
            prepare(Path(temp))
        result = bash(SETUP + body, {"TEST_ROOT": temp}, success)
    PASSED.append(name)
    return result


subprocess.run(["bash", "-n", str(SCRIPT)], check=True)
subprocess.run(["zsh", "-n", str(ROOT / "zshrc")], check=True)
PASSED.append("Bash and zsh syntax")

for platform in ["mac", "arch", "ubuntu"]:
    result = subprocess.run(
        ["bash", str(SCRIPT), "--platform", platform, "--all", "--dry-run"],
        cwd="/tmp", capture_output=True, text=True,
    )
    assert result.returncode == 0, result.stderr
    assert str(ROOT) in result.stdout
    assert "沒有變更" in result.stdout
PASSED.append("Dry-run on all platforms is independent of working directory")

for args in [
    ["--platform"], ["--platform", "invalid"], ["--unknown"],
    ["--links-only", "--set-shell"], ["--kaggle"], ["--nvtop"],
]:
    result = subprocess.run(["bash", str(SCRIPT), *args], capture_output=True)
    assert result.returncode != 0
PASSED.append("Reject invalid options and incompatible operations")
assert "kaggle" not in SCRIPT.read_text().lower()
assert "nvtop" not in SCRIPT.read_text().lower()
PASSED.append("Excluded packages are absent")

NATIVE_MOCKS = r'''
download() { printf 'Unexpected URL installer\n' >&2; return 90; }
install_uv() { return 91; }
install_node() { return 92; }
install_rust() { return 93; }
install_bun() { return 94; }
as_root() { printf 'ROOT %s\n' "$*" >> "$TEST_ROOT/calls"; }
'''

check("macOS uses Homebrew for default tools, Kitty and Brave", NATIVE_MOCKS + r'''
fake_brew() { printf 'BREW %s\n' "$*" >> "$TEST_ROOT/calls"; }
find_brew() { BREW_BIN=fake_brew; BREW_PREFIX="$TEST_ROOT/brew"; }
install_mac
grep -Fq 'install --cask kitty brave-browser' "$TEST_ROOT/calls"
grep -Fq 'install --formula git' "$TEST_ROOT/calls"
grep -q 'tree-sitter-cli' "$TEST_ROOT/calls"
! grep -Eq 'curl .*https|rustup|nvm|pip|npm' "$TEST_ROOT/calls"
''')

check("macOS optional Node, Rust and Bun also use Homebrew", NATIVE_MOCKS + r'''
NODE=1 RUST=1 BUN=1 UPDATE=1
fake_brew() { printf 'BREW %s\n' "$*" >> "$TEST_ROOT/calls"; }
find_brew() { BREW_BIN=fake_brew; BREW_PREFIX="$TEST_ROOT/brew"; }
install_mac
grep -Fq 'node pyright bash-language-server typescript-language-server typescript rust bun' "$TEST_ROOT/calls"
grep -q 'upgrade --formula' "$TEST_ROOT/calls"
grep -Fq 'upgrade --cask kitty brave-browser' "$TEST_ROOT/calls"
''')

ARCH_MOCKS = r'''
pacman() {
    if [[ "$1" = -Si ]]; then return 1; fi
    if [[ "$1" = -Ql ]]; then printf '%s /usr/share/zinit/zinit.zsh\n' "$2"; return; fi
    return 2
}
yay() {
    printf 'YAY %s\n' "$*" >> "$TEST_ROOT/calls"
    return 0
}
'''

check("Arch uses pacman / yay, installs Kitty and Brave, and avoids URL installers", NATIVE_MOCKS + ARCH_MOCKS + r'''
install_arch
grep -Fq 'ROOT pacman -Syu --needed --noconfirm' "$TEST_ROOT/calls"
grep -q 'unzip kitty' "$TEST_ROOT/calls"
grep -Fq 'YAY -S --needed --noconfirm brave-bin zinit' "$TEST_ROOT/calls"
[[ "$ZINIT_SCRIPT" = /usr/share/zinit/zinit.zsh ]]
''')

check("Arch optional tools stay in pacman / yay", NATIVE_MOCKS + ARCH_MOCKS + r'''
NODE=1 RUST=1 BUN=1
install_arch
grep -Fq 'nodejs npm pyright bash-language-server typescript-language-server typescript rust' "$TEST_ROOT/calls"
grep -Fq 'brave-bin zinit bun-bin' "$TEST_ROOT/calls"
''')

check("Arch discovers zinit-git when the stable package is unavailable", NATIVE_MOCKS + ARCH_MOCKS + r'''
yay() {
    printf 'YAY %s\n' "$*" >> "$TEST_ROOT/calls"
    if [[ "$1" = -Si && "$2" = zinit ]]; then return 1; fi
}
install_arch
grep -Fq 'brave-bin zinit-git' "$TEST_ROOT/calls"
''')

check("Arch bootstraps missing yay with makepkg, without a URL shell script", r'''
command() {
    if [[ "$*" = '-v yay' ]]; then [[ -f "$TEST_ROOT/yay-ready" ]]; return; fi
    builtin command "$@"
}
git() {
    [[ "$1" = clone && "$4" = https://aur.archlinux.org/yay-bin.git ]]
    mkdir -p "$SETUP_TMP_DIR/yay-bin"
}
makepkg() {
    [[ "$*" = '-si --noconfirm' ]]
    : > "$TEST_ROOT/yay-ready"
}
download() { return 99; }
ensure_yay
[[ -f "$TEST_ROOT/yay-ready" ]]
''')

check("Ubuntu apt is limited to base packages", r'''
as_root() { printf '%s\n' "$*" >> "$TEST_ROOT/calls"; }
install_apt
grep -q 'apt-get update' "$TEST_ROOT/calls"
grep -q 'build-essential' "$TEST_ROOT/calls"
! grep -Eq 'neovim|kitty|brave|tree-sitter|zoxide' "$TEST_ROOT/calls"
''')

check("Ubuntu keeps official tool installers and does not call native desktop installers", r'''
bat() { :; }
fd() { :; }
for name in apt uv neovim fzf zoxide tree_sitter node rust bun zinit_ubuntu; do
    eval "install_$name() { printf '%s\\n' '$name' >> \"\$TEST_ROOT/calls\"; }"
done
install_mac() { return 97; }
install_arch() { return 98; }
install_ubuntu
[[ $(wc -l < "$TEST_ROOT/calls" | tr -d ' ') = 10 ]]
grep -q '^zinit_ubuntu$' "$TEST_ROOT/calls"
''')

check("Local dotfiles, GUI settings and existing files are linked with backups", r'''
mkdir -p "$CONFIG_ROOT/nvim"
printf 'old editor\n' > "$CONFIG_ROOT/nvim/keep.lua"
printf 'old shell\n' > "$SETUP_USER_HOME/.zshrc"
install_dotfiles
[[ -L "$SETUP_USER_HOME/.zshrc" && -L "$CONFIG_ROOT/nvim" ]]
[[ -L "$CONFIG_ROOT/kitty" && -L "$CONFIG_ROOT/brave-flags.conf" ]]
[[ -f "$BACKUP_DIR/.config/nvim/keep.lua" && -f "$BACKUP_DIR/.zshrc" ]]
[[ $(cat "$BACKUP_DIR/.zshrc") = 'old shell' ]]
install_dotfiles
[[ $(readlink "$SETUP_USER_HOME/.zshrc") = "$DOTFILES_DIR/zshrc" ]]
''')

check("Dangling symlinks are backed up safely", r'''
ln -s missing "$SETUP_USER_HOME/.zshrc"
install_dotfiles
[[ -L "$BACKUP_DIR/.zshrc" ]]
[[ $(readlink "$BACKUP_DIR/.zshrc") = missing ]]
''')

check("macOS environment includes Homebrew LLVM and Zinit without duplicate shell hooks", r'''
PLATFORM=mac
BREW_BIN="$TEST_ROOT/brew space/bin/brew"
BREW_PREFIX="$TEST_ROOT/brew space"
write_shell_config
cp "$SHELL_FILE" "$TEST_ROOT/expected-env"
write_shell_config
cmp "$SHELL_FILE" "$TEST_ROOT/expected-env"
grep -Fq '/opt/llvm/bin' "$SHELL_FILE"
grep -Fq 'DOTFILES_ZINIT_SCRIPT' "$SHELL_FILE"
! grep -Eq 'fzf --|zoxide init|git clone' "$SHELL_FILE"
''')

check("Ubuntu environment loads existing nvm / Cargo with correct quoting", r'''
PLATFORM=ubuntu
ZINIT_SCRIPT="$TEST_ROOT/zinit space/zinit.zsh"
mkdir -p "$SETUP_NVM_DIR" "$SETUP_CARGO_DIR"
printf ':\n' > "$SETUP_NVM_DIR/nvm.sh"
printf ':\n' > "$SETUP_CARGO_DIR/env"
write_shell_config
grep -Fq NVM_DIR "$SHELL_FILE"
grep -Fq '.cargo/env' "$SHELL_FILE"
''')


def assets(temp):
    executable = b'#!/usr/bin/env bash\nprintf "mock version\\n"\n'
    with tarfile.open(temp / 'nvim.tar.gz', 'w:gz') as archive:
        entry = tarfile.TarInfo('nvim-linux-x86_64/bin/nvim')
        entry.mode = 0o755
        entry.size = len(executable)
        archive.addfile(entry, io.BytesIO(executable))
    with gzip.open(temp / 'tree-sitter.gz', 'wb') as output:
        output.write(executable)


check("Ubuntu Neovim / Tree-sitter install correctly and skip downloads on rerun", r'''
download() {
    printf '%s\n' "$1" >> "$TEST_ROOT/downloads"
    case "$1" in
        *nvim-linux-x86_64.tar.gz) cp "$TEST_ROOT/nvim.tar.gz" "$2" ;;
        *tree-sitter-linux-x64.gz) cp "$TEST_ROOT/tree-sitter.gz" "$2" ;;
        *) return 22 ;;
    esac
}
install_neovim
install_tree_sitter
install_neovim
install_tree_sitter
[[ -x "$BIN_DIR/nvim" && -x "$BIN_DIR/tree-sitter" ]]
[[ $(wc -l < "$TEST_ROOT/downloads" | tr -d ' ') = 2 ]]
''', prepare=assets)

with tempfile.TemporaryDirectory(prefix="dotfiles-failure-") as temp:
    result = bash(SETUP + r'''
mkdir -p "$DATA_DIR/neovim/bin"
printf '#!/bin/sh\nexit 0\n' > "$DATA_DIR/neovim/bin/nvim"
chmod +x "$DATA_DIR/neovim/bin/nvim"
UPDATE=1
download() { return 22; }
install_neovim
printf UNREACHABLE
''', {"TEST_ROOT": temp}, success=False)
    assert 'UNREACHABLE' not in result.stdout
    assert (Path(temp) / 'user space/.local/share/dotfiles/neovim/bin/nvim').exists()
    PASSED.append("Failed download preserves an existing installation")

print(f"PASS: {len(PASSED)} checks")
for name in PASSED:
    print(f"  - {name}")
