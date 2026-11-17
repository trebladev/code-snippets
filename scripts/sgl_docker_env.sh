#!/usr/bin/env bash
# Bootstrap Debian/Ubuntu containers. Install the latest Node.js Current release.
set -Eeuo pipefail
trap 'echo "Installation failed at line ${LINENO}." >&2' ERR

main() {
    if ! command -v apt-get >/dev/null 2>&1; then
        echo 'This script requires Debian/Ubuntu with apt-get.' >&2
        return 1
    fi

    local arch
    case "$(uname -m)" in
        x86_64) arch=x64 ;;
        aarch64|arm64) arch=arm64 ;;
        *) echo "Unsupported architecture: $(uname -m)" >&2; return 1 ;;
    esac

    local -a elevate=()
    if (( EUID != 0 )); then
        if ! command -v sudo >/dev/null 2>&1; then
            echo 'Run as root or install sudo first.' >&2
            return 1
        fi
        elevate=(sudo)
        sudo -v
    fi

    echo 'Updating apt and installing dependencies, tmux, gh, and ccache...'
    "${elevate[@]}" apt-get update
    "${elevate[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates curl xz-utils tmux gh ccache

    local tmux_conf="$HOME/.tmux.conf"
    local tmux_block
    tmux_block=$(cat <<'EOF'

# sgl-install: settings for Claude Code and Codex
set -g mouse on
set -g focus-events on
set -g default-terminal "tmux-256color"
set -as terminal-features ",*:RGB"
EOF
    )
    if [[ ! -f "$tmux_conf" ]] || ! grep -Fq '# sgl-install: settings for Claude Code and Codex' "$tmux_conf"; then
        printf '%s\n' "$tmux_block" >> "$tmux_conf"
    fi

    local work_dir
    work_dir=$(mktemp -d)
    trap 'rm -rf -- "$work_dir"' EXIT

    echo 'Resolving the latest Node.js Current release...'
    curl --fail --silent --show-error --location --retry 3 \
        https://nodejs.org/dist/latest/SHASUMS256.txt -o "$work_dir/latest.txt"
    local archive version
    archive=$(awk -v arch="$arch" '$2 ~ ("^node-v[0-9]+\\.[0-9]+\\.[0-9]+-linux-" arch "\\.tar\\.xz$") {print $2; exit}' "$work_dir/latest.txt")
    if [[ -z "$archive" ]]; then
        echo 'Could not resolve the latest Node.js archive.' >&2
        return 1
    fi
    version=${archive#node-}
    version=${version%-linux-*}
    local base_url="https://nodejs.org/dist/$version"
    curl --fail --silent --show-error --location --retry 3 \
        "$base_url/SHASUMS256.txt" -o "$work_dir/SHASUMS256.txt"
    curl --fail --silent --show-error --location --retry 3 \
        "$base_url/$archive" -o "$work_dir/$archive"
    (
        cd "$work_dir"
        awk -v archive="$archive" '$2 == archive' SHASUMS256.txt > checksum.txt
        test -s checksum.txt
        sha256sum --check checksum.txt
    )

    echo "Installing Node.js $version to /usr/local..."
    "${elevate[@]}" mkdir -p /usr/local
    "${elevate[@]}" tar -xJf "$work_dir/$archive" -C /usr/local --strip-components=1 --no-same-owner
    export PATH="/usr/local/bin:$PATH"
    hash -r

    echo 'Installing the latest Codex CLI...'
    "${elevate[@]}" env PATH="$PATH" /usr/local/bin/npm install --global --prefix /usr/local @openai/codex@latest

    node --version
    npm --version
    codex --version
    tmux -V
    gh --version | head -n 1
    ccache --version
    echo 'Environment ready. Run codex to sign in.'
    rm -rf -- "$work_dir"
    trap - EXIT
}

# Read all commands before running, so curl | bash also works reliably.
main "$@"
