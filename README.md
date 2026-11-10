# .dotfiles

先 clone 到家目錄，再執行同一支安裝腳本：

```bash
git clone git@github.com:monjo123/.dotfiles.git ~/.dotfiles
bash ~/.dotfiles/install.sh --set-shell
```

腳本會自動判斷系統，直接使用自身所在的 repository，不會再次 clone dotfiles。
從其他目錄執行也可以。請用一般帳號執行，系統套件安裝時才會呼叫 `sudo`。

## 三個平台的安裝來源

| 平台 | 指令工具 | Kitty | Brave |
| --- | --- | --- | --- |
| macOS | Homebrew | `brew install --cask kitty` | `brew install --cask brave-browser` |
| Arch Linux | 官方套件用 pacman，AUR 套件用 yay | pacman `kitty` | yay `brave-bin` |
| Ubuntu / Debian | apt 安裝基礎套件，較新的開發工具使用官方下載或安裝器 | 不安裝 | 不安裝 |

macOS 需先有 [Homebrew](https://brew.sh)；腳本不會執行 Homebrew 的網址安裝器。
Arch 缺少 yay 時，腳本會取得 AUR 的 `yay-bin` PKGBUILD，使用 `makepkg -si` 安裝。
Arch 會執行 `pacman -Syu` 完整更新系統，避免只更新套件資料庫造成部分更新。

預設工具包括 Git、curl、wget、jq、Python、編譯工具、clangd、zsh、tmux、Neovim、
fzf、zoxide、uv、Tree-sitter CLI、bat、ripgrep、fd、Zinit。

- **macOS：**上述工具全部使用 Homebrew；clangd 使用 Homebrew LLVM 的版本。
- **Arch：**上述工具使用 pacman / yay；Zinit 優先選官方套件，否則由 yay 安裝 `zinit` 或 `zinit-git`。
- **Ubuntu：**uv、Neovim、fzf、zoxide、Tree-sitter 由官方來源安裝到使用者目錄；
  Zinit 使用其 Git repository。apt 用來安裝編譯工具、Python、zsh、tmux、clangd、bat 等基礎套件。
  另外建立 `bat → batcat`、`fd → fdfind` 的指令連結，以配合現有設定。

Arch 的 Python provider 由 `python-pynvim` 提供；Ubuntu 使用 uv 的獨立 `pynvim` 工具環境，
需要時會自動下載 Python 3.11。macOS 版維持全 Homebrew 安裝，未另外透過 pip / uv 安裝 pynvim；
目前這份 Neovim 設定主要使用 Lua 外掛。

## 可選工具

```bash
# 加上 Node.js 和 Python / Bash / TypeScript 語言伺服器
bash ~/.dotfiles/install.sh --set-shell --node

# Node、Rust、Bun 全部加入
bash ~/.dotfiles/install.sh --set-shell --all
```

| 選項 | macOS | Arch | Ubuntu |
| --- | --- | --- | --- |
| `--node` | brew：Node、Pyright、Bash / TypeScript language server | pacman：同組工具 | 官方 nvm、Node LTS，再用 npm 安裝語言伺服器 |
| `--rust` | brew `rust` | pacman `rust` | 官方 rustup，minimal profile |
| `--bun` | brew `bun` | yay `bun-bin` | 官方 Bun release |
| `--all` | 開啟上面三組選項 | 同左 | 同左 |

`--rust` 也提供 Scheme 的 parinfer-rust 外掛所需的 Cargo。
現有 Neovim 設定還啟用了 Lua、LaTeX 等語言伺服器；LuaLS、LTeX、texlab、LaTeX 工具鏈與 Skim
等依需求另外準備。Zinit 和 Neovim 外掛仍由各自的外掛管理器在首次開啟時下載。

## 預覽與重跑

```bash
# 只顯示計畫，不安裝、不寫檔
bash ~/.dotfiles/install.sh --dry-run

# 在任意系統查看其他平台的計畫
bash ~/.dotfiles/install.sh --platform arch --all --dry-run
bash ~/.dotfiles/install.sh --platform mac --all --dry-run
bash ~/.dotfiles/install.sh --platform ubuntu --all --dry-run

# 只建立 dotfiles 連結
bash ~/.dotfiles/install.sh --links-only

# 更新本次選用的工具
bash ~/.dotfiles/install.sh --update --all
```

`--platform` 正式執行時必須符合目前系統，不能在 macOS 上執行 Arch 安裝。
`--links-only` 不安裝依賴，也不改登入 shell；`--set-shell` 才會將目前帳號改為 zsh。
Ubuntu 直接登入 root 時可明確使用 `--allow-root`，不要使用 `sudo bash install.sh`。

重跑不會重複建立相同連結；被替換的檔案或目錄會先移到備份。
Ubuntu 已安裝的主要下載工具會略過，使用 `--update` 才重新下載；Node 選項會確認當下 LTS。
macOS / Arch 的版本更新由各自套件管理器處理。Neovim 設定用到 `vim.pack`，
安裝結尾會用不載入個人外掛的方式檢查是否支援。

Ubuntu 可透過 `NVIM_VERSION`、`TREE_SITTER_VERSION` 指定官方 release tag；
預設為執行當時的最新正式版。也支援 `NVM_VERSION`（預設 `v0.41.0`）與
`TOOL_PYTHON_VERSION`（預設 `3.11`）。這些下載版本選項不會改變 macOS / Arch 的套件來源。

## 設定與備份

腳本會套用：

- `zshrc → ~/.zshrc`。
- `p10k.zsh → ~/.p10k.zsh`。
- `config/* → ${XDG_CONFIG_HOME:-~/.config}/`，包含 Neovim、Kitty 與 Brave flags。

其他產生的檔案：

| 位置 | 用途 |
| --- | --- |
| `~/.config/dotfiles/env.sh` | 工具路徑、原生套件 Zinit 位置、Ubuntu 的 nvm / Cargo 環境；尊重 `XDG_CONFIG_HOME` |
| `~/.local/share/dotfiles` | Ubuntu 的個人安裝工具 |
| `~/.local/state/dotfiles/backups/<執行編號>` | 被替換前的檔案、資料夾或 symlink |
| `~/.local/state/dotfiles/install-<執行編號>.log` | 安裝紀錄 |

備份中的 symlink 會保留原本連結本身。要恢復時，先移開目前設定，再將對應備份移回原位置。
如果上次安裝被強制中斷，確認沒有安裝程序執行後，可移除 `~/.local/state/dotfiles/install.lock`
內的 `pid` 檔與鎖定目錄，再重新執行。

Kitty 的 `${KITTY_OS}.conf` 會由 Kitty 自動選擇 `macos.conf` / `linux.conf`。
目前字型設定是 ComicShannsMono Nerd Font Mono，可依需求透過 brew / pacman / yay 安裝字型。

## 檢查

```bash
bash -n install.sh
zsh -n zshrc
python3 tests/test_install.py
```

測試使用離線模擬與暫存目錄，檢查三平台的套件來源、設定連結、備份、重跑與失敗處理。
不會在測試主機執行真正的套件安裝。

## 官方參考

- [Homebrew Tree-sitter CLI](https://formulae.brew.sh/formula/tree-sitter-cli)、[Zinit](https://formulae.brew.sh/formula/zinit)、[Bun](https://formulae.brew.sh/formula/bun)
- [Homebrew Kitty](https://formulae.brew.sh/cask/kitty)、[Brave](https://formulae.brew.sh/cask/brave-browser)
- [Arch Tree-sitter CLI](https://archlinux.org/packages/extra/x86_64/tree-sitter-cli/)、[uv](https://archlinux.org/packages/extra/x86_64/uv/)、[python-pynvim](https://archlinux.org/packages/extra/any/python-pynvim/)
- [uv 安裝器](https://docs.astral.sh/uv/reference/installer/)、[Neovim](https://neovim.io/doc/install/)
- [fzf](https://github.com/junegunn/fzf)、[zoxide](https://github.com/ajeetdsouza/zoxide)、[Zinit](https://github.com/zdharma-continuum/zinit)
- [nvm](https://github.com/nvm-sh/nvm)、[Rust](https://rust-lang.github.io/rustup/installation/)、[Bun](https://bun.sh/docs/installation)
