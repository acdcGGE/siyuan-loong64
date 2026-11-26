#!/usr/bin/env bash
# 在 LoongArch64 上原生编译 SiYuan 桌面版（内核 + 前端 + electron-builder 目录）
set -euo pipefail
cd "$(dirname "$0")/../.."

: "${GOPROXY:=https://mirrors.aliyun.com/goproxy/,direct}"
: "${NPM_REGISTRY:=https://registry.npmmirror.com}"
: "${ELECTRON_VERSION:=43.7.7}"
: "${ELECTRON_DIST:?请设置 ELECTRON_DIST 为解压后的 electron-loong64 运行时目录}"

export CGO_ENABLED=1 GOPROXY GOSUMDB=off GOFLAGS=-mod=mod

# 内核：cgo（sqlcipher + fts5），静态 PIE
mkdir -p app/kernel-linux
(cd kernel && go build -p "$(nproc)" -buildmode=pie -tags "fts5 sqlcipher" \
  -o ../app/kernel-linux/SiYuan-Kernel -ldflags "-s -w -extldflags -static-pie" .)

# 前端与 electron 打包目录
cd app
ELECTRON_SKIP_BINARY_DOWNLOAD=1 npm_config_registry="$NPM_REGISTRY" pnpm install --no-frozen-lockfile
npm_config_registry="$NPM_REGISTRY" pnpm run build
LOONG64_SKIP_OCR=1 LOONG64_SKIP_PANDOC=1 npm_config_registry="$NPM_REGISTRY" \
  pnpm exec electron-builder --linux dir --x64 --config electron-builder-linux.yml \
  -c.electronDist="$ELECTRON_DIST" -c.electronVersion="$ELECTRON_VERSION" \
  -c.npmRebuild=false --publish never

echo "完成：app/build/linux-unpacked"
