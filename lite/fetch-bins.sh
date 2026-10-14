#!/usr/bin/env bash
set -euo pipefail

# Télécharge les binaires Linux de eza, rg, fd, bat, fzf, nvim depuis les
# releases GitHub. Aucun root, aucune compilation.
#
# Usage: lite/fetch-bins.sh <x86_64|aarch64> <outdir> [outil...]
#
# nvim n'est pas un binaire seul (runtime, parsers) : l'archive est extraite
# dans <outdir>/../opt/nvim-<version> et <outdir>/nvim en est un lien.

# Versions figées : reproductible et auditable chez un client
RG_VERSION=15.2.0
FD_VERSION=10.5.0
BAT_VERSION=0.26.1
EZA_VERSION=0.23.5
FZF_VERSION=0.74.5
# 0.11.x : la config nvim suit l'API 0.11 (nvim-treesitter branche master)
NVIM_VERSION=0.11.6

usage() {
    echo "Usage: $(basename "$0") <x86_64|aarch64> <outdir> [outil...]"
}

# Remplit TOOLS pour une architecture : "<bin> <version> <url>"
set_tools() {
    local musl eza_triple fzf_arch nvim_url
    case "$1" in
        x86_64)
            musl=x86_64-unknown-linux-musl
            eza_triple=x86_64-unknown-linux-musl
            fzf_arch=amd64
            # neovim-releases : même version, compilée contre une glibc ancienne
            # (2.17), donc compatible avec les vieux serveurs (RHEL/CentOS 7…)
            nvim_url="https://github.com/neovim/neovim-releases/releases/download/v$NVIM_VERSION/nvim-linux-x86_64.tar.gz"
            ;;
        aarch64)
            musl=aarch64-unknown-linux-musl
            # Pas de build musl aarch64 publié pour eza
            eza_triple=aarch64-unknown-linux-gnu
            fzf_arch=arm64
            nvim_url="https://github.com/neovim/neovim/releases/download/v$NVIM_VERSION/nvim-linux-arm64.tar.gz"
            ;;
        *) echo "Architecture non supportée: $1"; exit 1 ;;
    esac
    TOOLS=(
        "rg   $RG_VERSION https://github.com/BurntSushi/ripgrep/releases/download/$RG_VERSION/ripgrep-$RG_VERSION-$musl.tar.gz"
        "fd   $FD_VERSION https://github.com/sharkdp/fd/releases/download/v$FD_VERSION/fd-v$FD_VERSION-$musl.tar.gz"
        "bat  $BAT_VERSION https://github.com/sharkdp/bat/releases/download/v$BAT_VERSION/bat-v$BAT_VERSION-$musl.tar.gz"
        "eza  $EZA_VERSION https://github.com/eza-community/eza/releases/download/v$EZA_VERSION/eza_$eza_triple.tar.gz"
        "fzf  $FZF_VERSION https://github.com/junegunn/fzf/releases/download/v$FZF_VERSION/fzf-$FZF_VERSION-linux_$fzf_arch.tar.gz"
        "nvim $NVIM_VERSION $nvim_url"
    )
}

[[ $# -ge 2 ]] || { usage; exit 1; }
ARCH="$1"
OUT="$2"
shift 2
WANTED=" ${*:-rg fd bat eza fzf nvim} "
set_tools "$ARCH"

mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
OPT="$(dirname "$OUT")/opt"

for entry in "${TOOLS[@]}"; do
    read -r bin version url <<< "$entry"
    [[ "$WANTED" == *" $bin "* ]] || continue
    stamp="$OUT/.$bin.version"
    old="$(cat "$stamp" 2>/dev/null || true)"
    if [[ -x "$OUT/$bin" && "$old" == "$version" ]]; then
        echo "[OK] $bin $version (cache)"
        continue
    fi

    echo "[..] $bin $version <- $url"
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    curl -fsSL "$url" -o "$tmp/archive.tar.gz"

    mkdir "$tmp/x"
    tar -xzf "$tmp/archive.tar.gz" -C "$tmp/x"

    if [[ "$bin" == nvim ]]; then
        root="$(find "$tmp/x" -mindepth 1 -maxdepth 1 -type d | head -1)"
        if [[ -z "$root" || ! -x "$root/bin/nvim" ]]; then
            echo "[ERREUR] bin/nvim introuvable dans l'archive"
            exit 1
        fi
        mkdir -p "$OPT"
        rm -rf "$OPT/nvim-$version"
        mv "$root" "$OPT/nvim-$version"
        ln -sfn "$OPT/nvim-$version/bin/nvim" "$OUT/nvim"
        [[ -n "$old" && "$old" != "$version" ]] && rm -rf "$OPT/nvim-$old"
    else
        found="$(find "$tmp/x" -type f -name "$bin" | head -1)"
        if [[ -z "$found" ]]; then
            echo "[ERREUR] $bin introuvable dans l'archive"
            exit 1
        fi
        install -m 755 "$found" "$OUT/$bin"
    fi

    echo "$version" > "$stamp"
    rm -rf "$tmp"
    trap - EXIT
    echo "[OK] $bin $version"
done
