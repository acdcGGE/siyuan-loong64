#!/usr/bin/env bash
# 准备 loong64 OCR 资源：onnxruntime 运行时 + siyuan-ocr worker + PP-OCR 模型
set -euo pipefail
cd "$(dirname "$0")/../.."

: "${ONNX_PKG:=onnxruntime-cpu-1.29.0-3-loong64.pkg.tar.zst}"
: "${MIRROR:=https://mirrors.nju.edu.cn/loongarch/archlinux}"
: "${HF:=https://huggingface.co}"

DEST=app/stage/ocr/runtime/linux-loong64
MODELS=app/stage/ocr/models/tiny
mkdir -p "$DEST" "$MODELS/det" "$MODELS/rec"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# 1. onnxruntime 运行时（系统包，来自网络）
curl -fL --retry 3 -o "$TMP/onnx.pkg.tar.zst" "$MIRROR/extra/os/loong64/$ONNX_PKG"
mkdir -p "$TMP/onnx"
bsdtar -xf "$TMP/onnx.pkg.tar.zst" -C "$TMP/onnx" usr/lib
cp -L "$TMP/onnx/usr/lib/libonnxruntime.so.1.29.0" "$DEST/libonnxruntime.so"

# 2. PP-OCRv6 tiny 模型
base=https://huggingface.co/PaddlePaddle
for pair in \
  "PP-OCRv6_tiny_det_onnx/2ba1506c0380b8f0b03dd142459aac66d4421f6c/det" \
  "PP-OCRv6_tiny_rec_onnx/2612ab37152ae0a677521bae4e1e3d4fb4cf7c30/rec"; do
  repo=${pair%%/*}; rest=${pair#*/}; rev=${rest%%/*}; kind=${rest##*/}
  curl -fL --retry 3 -o "$MODELS/$kind/inference.onnx" "$HF/PaddlePaddle/$repo/resolve/$rev/inference.onnx"
  curl -fL --retry 3 -o "$MODELS/$kind/inference.yml" "$HF/PaddlePaddle/$repo/resolve/$rev/inference.yml"
done

# 3. OCR worker（本机架构）
(cd kernel && CGO_ENABLED=1 go build -trimpath -ldflags="-s -w" \
  -o "../$DEST/siyuan-ocr" ./ocr/cmd/ocr-worker)

ls -lh "$DEST" "$MODELS/det" "$MODELS/rec"
