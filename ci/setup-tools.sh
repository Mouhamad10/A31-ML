#!/usr/bin/env bash
set -euo pipefail

ROOT="${GITHUB_WORKSPACE:-$PWD}"
TOOLS="$ROOT/.ci-tools"
BIN="$TOOLS/bin"

mkdir -p "$TOOLS" "$BIN"

sudo apt-get update

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    bc \
    bison \
    build-essential \
    cpio \
    device-tree-compiler \
    flex \
    gcc-aarch64-linux-gnu \
    git \
    lz4 \
    libelf-dev \
    libssl-dev \
    libncurses-dev \
    p7zip-full \
    python3 \
    python3-pip \
    unzip \
    wget \
    xz-utils \
    zstd \
    curl \
    jq

export PATH="$BIN:$PATH"

if [ ! -d "$TOOLS/Android-Image-Kitchen/.git" ]; then
    git clone --depth=1 \
        https://github.com/osm0sis/Android-Image-Kitchen.git \
        "$TOOLS/Android-Image-Kitchen"
fi

if [ ! -d "$TOOLS/mkbootimg/.git" ]; then
    git clone --depth=1 \
        https://github.com/osm0sis/mkbootimg.git \
        "$TOOLS/mkbootimg"
fi

if [ ! -d "$TOOLS/avb/.git" ]; then
    git clone --depth=1 \
        https://github.com/AndroidBootloader/platform_external_avb.git \
        "$TOOLS/avb"
fi

if [ ! -x "$BIN/avbtool" ]; then
    ln -sf "$TOOLS/avb/avbtool.py" "$BIN/avbtool"
    chmod +x "$TOOLS/avb/avbtool.py"
fi

if [ ! -d "$TOOLS/simg2img/.git" ]; then
    git clone --depth=1 \
        https://github.com/anestisb/android-simg2img.git \
        "$TOOLS/simg2img"

    make -C "$TOOLS/simg2img" -j"$(nproc)"

    for tool in simg2img img2simg append2simg simg2simg; do
        if [ -x "$TOOLS/simg2img/$tool" ]; then
            ln -sf "$TOOLS/simg2img/$tool" "$BIN/$tool"
        fi
    done
fi

if [ ! -d "$TOOLS/lptools/.git" ]; then
    git clone --depth=1 \
        https://github.com/itsNileshHere/android-lptools.git \
        "$TOOLS/lptools"

    (
        cd "$TOOLS/lptools"
        chmod +x make.sh
        ./make.sh
    )

    for tool in lpmake lpunpack lpdump lpadd lpflash; do
        if [ -x "$TOOLS/lptools/bin/$tool" ]; then
            ln -sf "$TOOLS/lptools/bin/$tool" "$BIN/$tool"
        fi
    done
fi

if [ ! -d "$TOOLS/Patchlocator/.git" ]; then
    git clone --depth=1 \
        https://github.com/seclab-ucr/Patchlocator.git \
        "$TOOLS/Patchlocator"
fi

if [ ! -d "$TOOLS/binwalk-src/.git" ]; then
    git clone --depth=1 \
        https://github.com/ReFirmLabs/binwalk.git \
        "$TOOLS/binwalk-src"
fi

printf '%s\n' "TOOLBOX READY"
printf '%s\n' "tool directory: $TOOLS"

printf '\n%s\n' "VERSIONS"

git --version
dtc --version | head -n 1
lz4 --version 2>&1 | head -n 1
python3 --version
"$BIN/avbtool" version 2>&1 || true
"$BIN/simg2img" --help >/dev/null 2>&1 && printf '%s\n' "simg2img: OK" || true
"$BIN/lpmake" --help >/dev/null 2>&1 && printf '%s\n' "lpmake: OK" || true
"$BIN/lpunpack" --help >/dev/null 2>&1 && printf '%s\n' "lpunpack: OK" || true

printf '\n%s\n' "DISK"
df -h "$ROOT"

printf '\n%s\n' "TOOLBOX SIZE"
du -sh "$TOOLS"
