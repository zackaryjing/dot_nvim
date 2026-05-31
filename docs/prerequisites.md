# Neovim 前置环境

以下命令适用于 Ubuntu 桌面环境。可以按顺序复制执行。

```bash
# 安装 LazyVim 常用前置、Wayland 剪贴板、Snacks SQLite 支持和 C++ 工具链。
# C++ LSP 固定使用 clangd-20，与 clang++ 20 保持一致。
sudo apt update
sudo apt install -y git curl build-essential ripgrep fd-find fzf jq wl-clipboard libsqlite3-dev clang-20 clangd-20 clang-tidy clang-format

# 确保用户级命令目录存在，并加入 PATH。
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# 安装官方最新版 Neovim。Ubuntu 仓库中的版本通常较旧。
NVIM_ARCH=$(uname -m | sed -e 's/aarch64/arm64/')
curl -fsSLo /tmp/nvim.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz"
mkdir -p "$HOME/.local/opt"
tar xf /tmp/nvim.tar.gz -C "$HOME/.local/opt"
ln -sf "$HOME/.local/opt/nvim-linux-${NVIM_ARCH}/bin/nvim" "$HOME/.local/bin/nvim"

# 安装 lazygit。Ubuntu 24.04 仓库中没有 lazygit，使用官方 release。
LAZYGIT_VERSION=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
LAZYGIT_ARCH=$(uname -m | sed -e 's/aarch64/arm64/')
curl -fsSLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"
tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
install -m 755 /tmp/lazygit "$HOME/.local/bin/lazygit"

# 克隆配置。首次启动后等待 LazyVim 安装插件和 Mason 工具。
git clone git@github.com:zackaryjing/dot_nvim.git "$HOME/.config/nvim"
nvim

# 暴露 Mason 安装的 tree-sitter CLI。
# 当前 nvim-treesitter 要求 tree-sitter-cli >= 0.26.1，不要安装 Ubuntu 24.04 中过旧的 apt 版本。
ln -sf "$HOME/.local/share/nvim/mason/bin/tree-sitter" "$HOME/.local/bin/tree-sitter"

# 检查结果。
nvim --version
tree-sitter --version
lazygit --version
nvim
```

进入 Neovim 后运行 `:checkhealth` 查看剩余提示。

`~/.local/bin` 应永久加入 shell 的 `PATH`。Ubuntu 默认会在重新登录后通过
`~/.profile` 加载该目录；如果当前终端中命令尚未生效，重新打开终端即可。
