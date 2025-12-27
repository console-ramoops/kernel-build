#!/usr/bin/env bash
set -euo pipefail

# Variables
AK3="omansh-krishn/Anykernel3"
TOOLCHAIN_DIR="/home/runner/toolchain"
AK3_DIR="/home/runner/AnyKernel3"
KDIR="$(pwd)/kernel_workspace" 

# Clone AnyKernel3
if [ ! -d "$AK3_DIR" ]; then
    git clone https://github.com/"${AK3}" "${AK3_DIR}" -b santoni-nexus --depth=1
fi

# Environment Setup
PATH="${TOOLCHAIN_DIR}/bin/:$PATH"
export KBUILD_BUILD_USER="omansh-krishn"
export KBUILD_BUILD_HOST="projects-nexus"
export ARCH=arm64

cd "$KDIR"

echo "[…] Starting compilation for $DEFCONFIG..."
make O=out ARCH=arm64 $DEFCONFIG

# Compilation using Zyc Clang
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                      CC=clang \
                      LLVM=1 \
                      LLVM_IAS=1

# Zipping logic
VERSION=$(grep -oP '(?<=VERSION = ).*' Makefile | head -1).$(grep -oP '(?<=PATCHLEVEL = ).*' Makefile | head -1)
ZIP="Kernel-Build-${VERSION}.zip"

if [ -f out/arch/arm64/boot/Image.gz-dtb ]; then
    cp "out/arch/arm64/boot/Image.gz-dtb" "${AK3_DIR}"
    cd "${AK3_DIR}"
    zip -rq9 "../../${ZIP}" * -x "README.md"
    cd "../../"
    echo "[✓] Successfully created ${ZIP}"
else
    echo "[✘] Image.gz-dtb not found! Build failed."
    exit 1
fi
