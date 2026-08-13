# Neovim 前置环境

配置会把 `~/.local/bin` 加到 Neovim 的 `PATH`，并自动选择当前系统上可用的
`clangd`、C++ 编译器和其支持的最高语言标准。无需固定安装 LLVM 20。

## Debian / Ubuntu / WSL

```bash
sudo apt update
sudo apt install -y git curl build-essential ripgrep fd-find fzf jq \
  libsqlite3-dev clang clangd clang-tidy clang-format xclip trash-cli

# Debian/Ubuntu 将 fd 命名为 fdfind。
mkdir -p "$HOME/.local/bin"
ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"
```

Wayland 桌面可将 `xclip` 换为 `wl-clipboard`。WSL 中存在 Windows Interop 时，
配置会使用 Windows Terminal 和 `explorer.exe`；没有 Interop 或外部终端时，
C++ 运行命令会自动退回 Neovim 底部终端。

## Neovim 与 lazygit

发行版仓库版本过旧或没有 `lazygit` 时，可将官方 release 安装到用户目录：

```bash
mkdir -p "$HOME/.local/bin" "$HOME/.local/opt"

ARCH=$(uname -m | sed 's/aarch64/arm64/')
curl -fsSLo /tmp/nvim.tar.gz \
  "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.tar.gz"
tar xf /tmp/nvim.tar.gz -C "$HOME/.local/opt"
ln -sf "$HOME/.local/opt/nvim-linux-${ARCH}/bin/nvim" "$HOME/.local/bin/nvim"

LAZYGIT_TAG=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | jq -r .tag_name)
curl -fsSLo /tmp/lazygit.tar.gz \
  "https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_TAG}/lazygit_${LAZYGIT_TAG#v}_Linux_${ARCH}.tar.gz"
tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
install -m 755 /tmp/lazygit "$HOME/.local/bin/lazygit"
```

## tree-sitter 与旧版 glibc

Mason 或上游 release 的预编译 `tree-sitter` 可能要求比 Debian Stable 更新的
glibc。遇到 `GLIBC_x.xx not found` 时，从 Rust 源码编译，产物直接进入
`~/.local/bin`：

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
  sh -s -- -y --profile minimal
. "$HOME/.cargo/env"
cargo install tree-sitter-cli --locked --root "$HOME/.local"
```

配置将 Mason 的目录放在 `PATH` 末尾，因此系统或 `~/.local/bin` 中兼容的版本
优先于 Mason 下载的二进制文件。

## 检查

```bash
command -v nvim rg fd fzf jq lazygit tree-sitter clang++ clangd
nvim --version
tree-sitter --version
lazygit --version
```

进入 Neovim 后运行 `:checkhealth` 查看剩余提示。`~/.local/bin` 也应永久加入
shell 的 `PATH`；如果当前终端尚未生效，重新打开终端即可。
