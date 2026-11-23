#!/usr/bin/env bash
# Ubuntu/Debian: curl -fsSL <raw-url> | bash
set -Eeuo pipefail
trap 'printf "安装失败（第 %s 行），请检查上方错误后重试。\n" "$LINENO" >&2' ERR

main() {
    if [[ ! -r /etc/os-release ]]; then
        echo '仅支持 Ubuntu/Debian 系统。' >&2
        return 1
    fi
    . /etc/os-release
    case "${ID:-}" in
        ubuntu|debian) ;;
        *) echo '仅支持 Ubuntu/Debian 系统。' >&2; return 1 ;;
    esac

    local -a elevate=()
    if (( EUID != 0 )); then
        if ! command -v sudo >/dev/null 2>&1; then
            echo '请以 root 运行，或先安装并配置 sudo。' >&2
            return 1
        fi
        sudo -v
        elevate=(sudo)
    fi

    echo '安装基础依赖……'
    "${elevate[@]}" apt-get update
    "${elevate[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl tmux

    echo '配置 tmux……'
    local tmux_conf="${HOME}/.tmux.conf"
    local tmux_marker='# sgl-install: tmux settings'
    local tmux_block
    tmux_block=$(cat <<'EOF'

# sgl-install: tmux settings
set -g mouse on

# Keep more terminal output available in copy mode.
set -g history-limit 50000

# Advertise 256-color support inside tmux.
set -g default-terminal "tmux-256color"

# Enable RGB/true-color for xterm-compatible parent terminals.
# The current outer terminal reports TERM=xterm, so match the whole family.
set -as terminal-features ",xterm*:RGB"
EOF
    )
    if [[ ! -f "$tmux_conf" ]] || ! grep -Fq "$tmux_marker" "$tmux_conf"; then
        printf '%s\n' "$tmux_block" >> "$tmux_conf"
    fi

    # Use a maintained Node.js LTS release; reuse an existing 24.x installation.
    if ! command -v node >/dev/null 2>&1 || \
       [[ "$(node --version)" != v24.* ]] || \
       ! command -v npm >/dev/null 2>&1; then
        echo '安装 Node.js 24 LTS……'
        local setup_file
        setup_file=$(mktemp)
        trap 'rm -f -- "$setup_file"' EXIT
        curl -fsSL --retry 3 https://deb.nodesource.com/setup_24.x -o "$setup_file"
        "${elevate[@]}" bash "$setup_file"
        rm -f -- "$setup_file"
        trap - EXIT
        "${elevate[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
    fi

    echo '安装 Codex CLI……'
    # A fixed prefix makes the command available to subsequent container shells.
    "${elevate[@]}" env "PATH=$PATH" npm install --global --prefix /usr/local @openai/codex@latest

    # Official default installers. Run from a file with stdin closed so
    # `curl | bash` of this script cannot lose the rest of itself.
    local installer
    echo '安装 Cursor CLI……'
    installer=$(mktemp)
    trap 'rm -f -- "$installer"' EXIT
    curl -fsS --retry 3 https://cursor.com/install -o "$installer"
    bash "$installer" < /dev/null
    rm -f -- "$installer"
    trap - EXIT

    echo '安装 Google Antigravity CLI……'
    installer=$(mktemp)
    trap 'rm -f -- "$installer"' EXIT
    curl -fsSL --retry 3 https://antigravity.google/cli/install.sh -o "$installer"
    bash "$installer" < /dev/null
    rm -f -- "$installer"
    trap - EXIT

    # Default locations are under ~/.local/bin. Link them next to codex.
    "${elevate[@]}" mkdir -p /usr/local/bin
    local tool
    for tool in agent cursor-agent agy; do
        if [[ -e "${HOME}/.local/bin/${tool}" || -L "${HOME}/.local/bin/${tool}" ]]; then
            "${elevate[@]}" ln -sfn "${HOME}/.local/bin/${tool}" "/usr/local/bin/${tool}"
        fi
    done

    export PATH="/usr/local/bin:${HOME}/.local/bin:${PATH}"
    hash -r
    printf '\n安装完成：\n'
    node --version
    npm --version
    codex --version
    agent --version
    agy --version
    printf '\n运行 codex、agent 或 agy 开始使用。\n'
    printf '云服务器登录：codex login --device-auth；Cursor CLI 使用 agent login。\n'
    printf '如果当前终端找不到这些命令，请执行：export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"\n'
}

# With curl | bash, parse the entire script before starting installation.
main "$@"
