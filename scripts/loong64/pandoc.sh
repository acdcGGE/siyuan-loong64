#!/usr/bin/env bash
# 生成 loong64 版 pandoc 压缩包（取自 Debian loong64 构建，附带所需动态库）
set -euo pipefail
cd "$(dirname "$0")/../.."

: "${PANDOC_VERSION:=3.11-1}"
: "${DEBIAN_POOL:=https://deb.debian.org/debian/pool}"
: "${PATCHELF:=patchelf}"
DEST=app/pandoc/pandoc-linux-loong64.zip

# pandoc 依赖的非 glibc 动态库（各发行版包名/so 版本不一致，随包附带）
LIBS="
main/l/lua5.4/liblua5.4-0_5.4.9-2_loong64.deb
main/liby/libyaml/libyaml-0-2_0.2.6-1_loong64.deb
main/g/gmp/libgmp10_6.3.0+dfsg-5+b2_loong64.deb
main/libf/libffi/libffi8_3.8.0-2_loong64.deb
main/n/numactl/libnuma1_2.0.19-1+b2_loong64.deb
"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

curl -fL --retry 3 -o "$TMP/pandoc.deb" \
  "$DEBIAN_POOL/main/p/pandoc/pandoc_${PANDOC_VERSION}_loong64.deb"
mkdir -p "$TMP/root" "$TMP/zip/bin" "$TMP/zip/lib"
(cd "$TMP" && ar x pandoc.deb && tar -xf data.tar.xz -C root)
cp "$TMP/root/usr/bin/pandoc" "$TMP/zip/bin/pandoc"
chmod 755 "$TMP/zip/bin/pandoc"

for path in $LIBS; do
  name=$(basename "$path")
  curl -fL --retry 3 -o "$TMP/$name" "$DEBIAN_POOL/$path"
  mkdir -p "$TMP/lib-$name"
  (cd "$TMP/lib-$name" && ar x "../$name" && tar -xf data.tar.xz ./usr/lib 2>/dev/null || tar -xf data.tar.xz usr/lib)
  while IFS= read -r -d '' lib; do
    cp -L "$lib" "$TMP/zip/lib/$(basename "$lib")"
  done < <(find "$TMP/lib-$name/usr/lib" -name "*.so.*" -print0)
done

"$PATCHELF" --set-rpath '$ORIGIN/../lib' "$TMP/zip/bin/pandoc"
for lib in "$TMP"/zip/lib/*.so.*; do
  "$PATCHELF" --set-rpath '$ORIGIN' "$lib"
done

python3 - "$TMP/zip" "$DEST" <<'PY'
import os, sys, zipfile
root, out = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for dirpath, _, files in os.walk(root):
        for name in files:
            path = os.path.join(dirpath, name)
            z.write(path, os.path.relpath(path, root))
PY

ls -lh "$DEST"
