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
    "${elevate[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl

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
    export PATH="/usr/local/bin:$PATH"
    hash -r
    printf '\n安装完成：\n'
    node --version
    npm --version
    codex --version
    printf '\n运行 codex 开始使用；云服务器可使用 codex login --device-auth 登录。\n'
    printf '如果当前终端找不到 codex，请执行：export PATH="/usr/local/bin:$PATH"\n'
}

# With curl | bash, parse the entire script before starting installation.
main "$@"
