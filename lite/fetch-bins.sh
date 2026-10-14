#!/usr/bin/env bash
set -euo pipefail

# Télécharge les binaires statiques Linux de eza, rg, fd, bat, fzf depuis
# les releases GitHub. Aucun root, aucune compilation.
#
# Usage: lite/fetch-bins.sh <x86_64|aarch64> <outdir> [outil...]

# Versions figées : reproductible et auditable chez un client
RG_VERSION=15.2.0
FD_VERSION=10.5.0
BAT_VERSION=0.26.1
EZA_VERSION=0.23.5
FZF_VERSION=0.74.5

usage() { echo "Usage: $(basename "$0") <x86_64|aarch64> <outdir> [outil...]"; }

[[ $# -ge 2 ]] || { usage; exit 1; }
ARCH="$1"
OUT="$2"
shift 2
WANTED=" ${*:-rg fd bat eza fzf} "

case "$ARCH" in
    x86_64)  MUSL=x86_64-unknown-linux-musl;  EZA_TRIPLE=x86_64-unknown-linux-musl; FZF_ARCH=amd64 ;;
    aarch64) MUSL=aarch64-unknown-linux-musl; EZA_TRIPLE=aarch64-unknown-linux-gnu; FZF_ARCH=arm64 ;;
    *) echo "Architecture non supportée: $ARCH"; exit 1 ;;
esac

# <binaire> <version> <url>
TOOLS=(
    "rg  $RG_VERSION  https://github.com/BurntSushi/ripgrep/releases/download/$RG_VERSION/ripgrep-$RG_VERSION-$MUSL.tar.gz"
    "fd  $FD_VERSION  https://github.com/sharkdp/fd/releases/download/v$FD_VERSION/fd-v$FD_VERSION-$MUSL.tar.gz"
    "bat $BAT_VERSION https://github.com/sharkdp/bat/releases/download/v$BAT_VERSION/bat-v$BAT_VERSION-$MUSL.tar.gz"
    "eza $EZA_VERSION https://github.com/eza-community/eza/releases/download/v$EZA_VERSION/eza_$EZA_TRIPLE.tar.gz"
    "fzf $FZF_VERSION https://github.com/junegunn/fzf/releases/download/v$FZF_VERSION/fzf-$FZF_VERSION-linux_$FZF_ARCH.tar.gz"
)

mkdir -p "$OUT"
for entry in "${TOOLS[@]}"; do
    read -r bin version url <<< "$entry"
    [[ "$WANTED" == *" $bin "* ]] || continue
    stamp="$OUT/.$bin.version"
    if [[ -x "$OUT/$bin" && "$(cat "$stamp" 2>/dev/null)" == "$version" ]]; then
        echo "[OK] $bin $version (cache)"
        continue
    fi

    echo "[..] $bin $version <- $url"
    tmp="$(mktemp -d)"
    curl -fsSL "$url" -o "$tmp/archive.tar.gz"
    mkdir "$tmp/x"
    tar -xzf "$tmp/archive.tar.gz" -C "$tmp/x"
    found="$(find "$tmp/x" -type f -name "$bin" | head -1)"
    if [[ -z "$found" ]]; then
        echo "[ERREUR] $bin introuvable dans l'archive"
        rm -rf "$tmp"
        exit 1
    fi
    install -m 755 "$found" "$OUT/$bin"
    echo "$version" > "$stamp"
    rm -rf "$tmp"
    echo "[OK] $bin $version"
done
