#!/usr/bin/env bash
set -euo pipefail

# Variables
DEFCONFIG="nexus_defconfig"
AK3="omansh-krishn/Anykernel3"
TOOLCHAIN_DIR="/home/runner/toolchain"
AK3_DIR="/home/runner/AnyKernel3"
KDIR="$(pwd)"

# Clone AnyKernel3
if [ ! -d "$AK3_DIR" ]; then
    echo "[…] Cloning AnyKernel3..."
    git clone https://github.com/"${AK3}" "${AK3_DIR}" -b santoni-nexus --depth=1
fi

# Environment Setup
PATH="${TOOLCHAIN_DIR}/bin/:$PATH"
export KBUILD_BUILD_USER="omansh-krishn"
export KBUILD_BUILD_HOST="projects-nexus"
export ARCH=arm64
export SUBARCH=arm64

# Building
echo "[…] Starting compilation..."
make O=out ${DEFCONFIG}

make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                      CC=clang \
                      LLVM=1 \
                      LLVM_IAS=1

# Zipping
VERSION=$(grep -oP '(?<=VERSION = ).*' Makefile | head -1).$(grep -oP '(?<=PATCHLEVEL = ).*' Makefile | head -1)
ZIP="Nexus-v0.9.5-${VERSION}.zip"

if [ -f out/arch/arm64/boot/Image.gz-dtb ]; then
    cp "out/arch/arm64/boot/Image.gz-dtb" "${AK3_DIR}"
    cd "${AK3_DIR}"
    zip -rq9 "${KDIR}/${ZIP}" * -x "README.md"
    cd "$KDIR"
    echo "[✓] Kernel successfully zipped: ${ZIP}"
else
    echo "[✘] Build failed! Image.gz-dtb not found."
    exit 1
fi

