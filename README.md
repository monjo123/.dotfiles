# .dotfiles

先 clone 到家目錄，再執行同一支安裝腳本：

```bash
git clone git@github.com:monjo123/.dotfiles.git ~/.dotfiles
bash ~/.dotfiles/install.sh --set-shell
```

腳本會自動判斷系統，直接使用自身所在的 repository，不會再次 clone dotfiles。
從其他目錄執行也可以。請用一般帳號執行。Ubuntu 的安裝與解除安裝全程不使用 sudo；
Arch 的系統套件操作，以及 macOS 的登入 shell 設定，會在需要時使用 sudo。

先檢查可用指令與套件／應用程式，已有工具直接沿用，不重裝；只有缺少的才安裝。

安裝前會互動詢問 Git 的 name 與 email，安裝成功後儲存到目前帳號的全域設定：

```bash
git config --global user.name "你輸入的名字"
git config --global user.email "你輸入的 email"
```

已有全域設定時，按 Enter 可沿用；新設定的 name 不可空白，email 需包含有效的 `@` 格式。
`--dry-run` 與 `--links-only` 不詢問、不修改 Git 身分設定。

## 三個平台的安裝來源

| 平台 | 指令工具 | Kitty | Brave |
| --- | --- | --- | --- |
| macOS | Homebrew | `brew install --cask kitty` | `brew install --cask brave-browser` |
| Arch Linux | 官方套件用 pacman，AUR 套件用 yay | pacman `kitty` | yay `brave-bin` |
| Ubuntu / Debian | 官方下載／安裝器；缺少的基礎工具用使用者目錄的 micromamba 環境 | 不安裝 | 不安裝 |

macOS 需先有 [Homebrew](https://brew.sh)；腳本不會執行 Homebrew 的網址安裝器。
Arch 缺少 yay 時，腳本會取得 AUR 的 `yay-bin` PKGBUILD，使用 `makepkg -si` 安裝。
Arch 有缺少的官方套件時會執行 `pacman -Syu`，避免部分更新；工具都已齊全時會略過套件安裝。

預設工具包括 Git、curl、wget、jq、Python、編譯工具、clangd、zsh、tmux、Neovim、
fzf、zoxide、uv、Tree-sitter CLI、bat、ripgrep、fd，以及 Node.js、語言伺服器、Rust / Cargo、Bun / bunx。

- **macOS：**上述工具全部使用 Homebrew；clangd 使用 Homebrew LLVM 的版本。
- **Arch：**上述工具使用 pacman / yay。
- **Ubuntu：**uv、Neovim、fzf、zoxide、Tree-sitter、Rust、Bun 等由官方來源安裝到使用者目錄。
  缺少的 Git、Python、zsh、tmux、clangd、C/C++ 編譯器、bat、ripgrep、fd、make 等，
  由官方 micromamba 執行檔與 conda-forge 套件補齊到 `~/.local/share/dotfiles/ubuntu-env`，不使用 apt。
  只為缺少的指令在 `~/.local/bin` 建立入口，不會全域啟用或修改你原有的 Conda 環境。
  如果已有 `batcat` 或 `fdfind`，只補上 `bat` / `fd` 的連結。

Ubuntu 首次下載需已有 curl、wget、Python 3 其中之一，以及 Bash、tar、gzip 等基本工具。
這些是取得網路安裝器的起點；不會為了補齊它們而自動要求 sudo。

Arch 的 Python provider 由 `python-pynvim` 提供；Ubuntu 使用 uv 的獨立 `pynvim` 工具環境，
需要時會自動下載 Python 3.11。macOS 版維持全 Homebrew 安裝，未另外透過 pip / uv 安裝 pynvim；
目前這份 Neovim 設定主要使用 Lua 外掛。

## 預設安裝的開發工具

直接執行腳本就會包含下列工具，不需要額外的安裝選項。

| 工具 | macOS | Arch | Ubuntu |
| --- | --- | --- | --- |
| Node.js / 語言伺服器 | brew：Node、Pyright、Bash / TypeScript language server | pacman：同組工具 | 官方 nvm、Node LTS，再用 npm 安裝語言伺服器 |
| Rust / Cargo | brew `rust` | pacman `rust` | 官方 rustup，minimal profile |
| Bun / bunx | brew `bun` | yay `bun-bin` | 官方 Bun release |

Rust / Cargo 也提供 Scheme 的 parinfer-rust 外掛所需的編譯環境。
現有 Neovim 設定還啟用了 Lua、LaTeX 等語言伺服器；LuaLS、LTeX、texlab、LaTeX 工具鏈與 Skim
等依需求另外準備。Neovim 外掛由自身的外掛管理器在首次開啟時下載。

三個平台的 Zinit 統一由 `zshrc` 負責：首次開啟 zsh 時，若找不到
`${XDG_DATA_HOME:-~/.local/share}/zinit/zinit.git/zinit.zsh`，就自動用 Git clone 安裝，
之後直接載入已有版本。`install.sh` 不安裝 Zinit 套件，也不指定套件管理器的 Zinit 路徑。
Zinit 本體更新使用 `zinit self-update`，外掛更新使用 `zinit update`。

## 預覽與重跑

```bash
# 只顯示計畫，不安裝、不寫檔
bash ~/.dotfiles/install.sh --dry-run

# 在任意系統查看其他平台的計畫
bash ~/.dotfiles/install.sh --platform arch --dry-run
bash ~/.dotfiles/install.sh --platform mac --dry-run
bash ~/.dotfiles/install.sh --platform ubuntu --dry-run

# 只建立 dotfiles 連結
bash ~/.dotfiles/install.sh --links-only

```

`--platform` 正式執行時必須符合目前系統，不能在 macOS 上執行 Arch 安裝。
`--links-only` 不安裝依賴，也不啟用 zsh。`--set-shell` 在 macOS / Arch 會設定登入 shell；
Ubuntu 會在個人的 `~/.bashrc` 加入互動終端機自動進入 zsh 的區塊，不更動 `/etc/shells` 或使用 sudo。
這個區塊不影響非互動命令，也會在解除安裝時移除。
腳本統一使用一般帳號執行，會拒絕直接以 root 執行；不要使用 `sudo bash install.sh`。

重跑不會重複建立相同連結；被替換的檔案或目錄會先移到備份。
Ubuntu 已安裝的工具會略過；Node.js 已可用時沿用原版本，否則優先沿用 nvm 中的已安裝版本，再考慮下載 LTS。
macOS / Arch 的版本更新由各自套件管理器處理。Neovim 設定用到 `vim.pack`，
安裝結尾會用不載入個人外掛的方式檢查是否支援。
若原有 Neovim 太舊，會提示你處理相容性，不會自動覆蓋它。

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
| `~/.config/dotfiles/env.sh` | 工具路徑、Ubuntu 的 nvm / Cargo 環境；尊重 `XDG_CONFIG_HOME` |
| `~/.local/share/dotfiles` | Ubuntu 的個人安裝工具 |
| `~/.local/state/dotfiles/backups/<執行編號>` | 被替換前的檔案、資料夾或 symlink |
| `~/.local/state/dotfiles/install-<執行編號>.log` | 安裝紀錄 |
| `~/.local/state/dotfiles/ownership/<平台>` | 新增工具、連結及原始 Git / shell 設定的解除安裝紀錄 |

備份中的 symlink 會保留原本連結本身。要恢復時，先移開目前設定，再將對應備份移回原位置。
如果上次安裝被強制中斷，確認沒有安裝程序執行後，可移除 `~/.local/state/dotfiles/install.lock`
內的 `pid` 檔與鎖定目錄，再重新執行。

Kitty 的 `${KITTY_OS}.conf` 會由 Kitty 自動選擇 `macos.conf` / `linux.conf`。
目前字型設定是 ComicShannsMono Nerd Font Mono，可依需求透過 brew / pacman / yay 安裝字型。

## 解除安裝

```bash
# 先檢視移除清單，完全不修改檔案
bash ~/.dotfiles/uninstall.sh --dry-run

# 列出清單並互動確認後執行
bash ~/.dotfiles/uninstall.sh
```

確認時輸入 `UNINSTALL`，會移除有紀錄的新增工具與本 repository 的設定連結，
並盡可能還原安裝前的設定備份、Git name / email 與登入 shell。
已另外更改過的 Git 身分會保留目前值。Ubuntu 的 Bash 自動進入 zsh 區塊會移除。

新版本安裝器會先檢查既有工具，只記錄這次新增的項目。原本就已存在的工具不會自動當作新增項目。
如果先前使用沒有紀錄的舊版安裝器，解除安裝會另外列出「舊工具候選」；
只有輸入 `LEGACY` 才一併處理該清單，也會先備份並清除沒有原始紀錄的 Git 全域 name / email。
直接按 Enter 會取消。

個人安裝目錄與外掛資料會先移到 `~/.local/state/dotfiles/uninstall-backups/<執行編號>`，
讓你可以找回原有內容；確認不再需要後，可自行刪除這個回收備份以釋放空間。
套件管理器只移除紀錄中指定的套件，不使用強制移除依賴或自動清除其他套件的選項。
若其他程式仍依賴某個工具，會保留失敗紀錄並回報，方便處理後重跑。

Ubuntu 不使用 sudo，也不會清除舊版透過 apt 安裝的系統套件。
repository、本機專案、SSH 金鑰、shell history 與瀏覽器個人資料不在移除範圍。

## 檢查

```bash
bash -n install.sh
bash -n uninstall.sh
zsh -n zshrc
```

驗證使用離線模擬與暫存目錄，檢查套件來源、略過既有工具、Git 互動、設定備份及解除安裝。
不會在測試主機執行真正的套件安裝或移除。

## 官方參考

- [Homebrew Tree-sitter CLI](https://formulae.brew.sh/formula/tree-sitter-cli)、[Bun](https://formulae.brew.sh/formula/bun)
- [Homebrew Kitty](https://formulae.brew.sh/cask/kitty)、[Brave](https://formulae.brew.sh/cask/brave-browser)
- [Arch Tree-sitter CLI](https://archlinux.org/packages/extra/x86_64/tree-sitter-cli/)、[uv](https://archlinux.org/packages/extra/x86_64/uv/)、[python-pynvim](https://archlinux.org/packages/extra/any/python-pynvim/)
- [uv 安裝器](https://docs.astral.sh/uv/reference/installer/)、[Neovim](https://neovim.io/doc/install/)
- [fzf](https://github.com/junegunn/fzf)、[zoxide](https://github.com/ajeetdsouza/zoxide)、[Zinit](https://github.com/zdharma-continuum/zinit)
- [nvm](https://github.com/nvm-sh/nvm)、[Rust](https://rust-lang.github.io/rustup/installation/)、[Bun](https://bun.sh/docs/installation)
- [Micromamba 官方安裝說明](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html)
- [Homebrew 移除選項](https://docs.brew.sh/Manpage)、[pacman 手冊](https://man.archlinux.org/man/pacman.8.en)
