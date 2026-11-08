# code-snippets
A source of segments of code

## 容器中安装 Node.js 和 Codex

适用于 Ubuntu/Debian 容器，使用 root 或有 sudo 权限的用户运行：

```bash
curl -fsSL https://raw.githubusercontent.com/trebladev/code-snippets/main/scripts/install-sgl.sh | bash
```

脚本通过 NodeSource 安装 Node.js 24 LTS（已有 24.x 和 npm 时复用），然后通过 npm 安装或更新最新版 Codex CLI 到 `/usr/local`。需要能够访问 NodeSource 和 npm registry。若已有其他版本的 Node.js，脚本会尝试安装 24.x。

极简容器如果没有 curl，先以 root 执行：

```bash
apt-get update && apt-get install -y ca-certificates curl
```

安装后运行 `codex`，按提示登录；无浏览器的云服务器可运行 `codex login --device-auth`。如果 `/usr/local/bin` 不在当前终端的 PATH 中，先执行 `export PATH="/usr/local/bin:$PATH"`。

上述 curl 地址需在脚本推送到 GitHub 的 `main` 分支后才能使用。本地可运行 `bash scripts/install-sgl.sh`。
