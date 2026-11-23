# code-snippets
A source of segments of code

## 容器中安装 Node.js、Codex、Cursor CLI 和 Antigravity CLI

适用于 Ubuntu/Debian 容器，使用 root 或有 sudo 权限的用户运行：

```bash
curl -fsSL https://raw.githubusercontent.com/trebladev/code-snippets/main/scripts/install-sgl.sh | bash
```

脚本通过 NodeSource 安装 Node.js 24 LTS（已有 24.x 和 npm 时复用），然后通过 npm 安装或更新最新版 Codex CLI 到 `/usr/local`。接着使用官方默认安装脚本安装 Cursor CLI（`agent`、`cursor-agent`）和 Google Antigravity CLI（`agy`），并链接到 `/usr/local/bin`。需要能够访问 NodeSource、npm registry、`cursor.com` 和 `antigravity.google`。若已有其他版本的 Node.js，脚本会尝试安装 24.x。

安装脚本同时通过 apt 安装 tmux、GitHub CLI（`gh`）和 ccache，并为 Claude Code 与 Codex 写入 tmux 配置，开启鼠标、focus events 和真彩色支持。

安装后运行 `codex`、`agent` 或 `agy`。无浏览器的云服务器可运行 `codex login --device-auth`；Cursor CLI 使用 `agent login`。如果这些命令不在当前终端的 PATH 中，先执行 `export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"`。
