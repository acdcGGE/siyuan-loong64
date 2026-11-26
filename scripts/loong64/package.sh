#!/usr/bin/env bash
# 将 app/build/linux-unpacked 打包为 loong64 的 deb 与 tar.gz
set -euo pipefail
cd "$(dirname "$0")/../.."

OUT=app/build
UNPACKED=$OUT/linux-unpacked
VERSION=$(node -p "require('./app/package.json').version")
PKGDIR=$OUT/deb-root
ICON_DIR=app/src/assets/icon

[ -d "$UNPACKED" ] || { echo "缺少 $UNPACKED，请先运行 build.sh"; exit 1; }

rm -f "$UNPACKED/resources/pandoc.zip"
rm -rf "$OUT/siyuan-$VERSION-linux-loong64.tar.gz" "$OUT/siyuan_${VERSION}_loong64.deb" "$PKGDIR"
tar -czf "$OUT/siyuan-$VERSION-linux-loong64.tar.gz" -C "$UNPACKED" .

mkdir -p "$PKGDIR/opt/SiYuan" "$PKGDIR/usr/bin" "$PKGDIR/usr/share/applications" "$PKGDIR/DEBIAN"
for s in 16 32 48 64 128 256 512; do
  mkdir -p "$PKGDIR/usr/share/icons/hicolor/${s}x${s}/apps"
  cp "$ICON_DIR/${s}x${s}.png" "$PKGDIR/usr/share/icons/hicolor/${s}x${s}/apps/siyuan.png"
  cp "$ICON_DIR/${s}x${s}.png" "$PKGDIR/usr/share/icons/hicolor/${s}x${s}/apps/SiYuan-Kernel.png"
done
cp -a "$UNPACKED/." "$PKGDIR/opt/SiYuan/"
ln -sf /opt/SiYuan/siyuan "$PKGDIR/usr/bin/siyuan"

cat > "$PKGDIR/usr/share/applications/siyuan.desktop" <<'EOF'
[Desktop Entry]
Name=SiYuan
Comment=From thought to insight, with agents
Type=Application
Categories=Utility;
Exec=siyuan %U
Icon=siyuan
Terminal=false
StartupWMClass=SiYuan
MimeType=text/markdown;
EOF

SIZE=$(du -sk "$PKGDIR/opt" | cut -f1)
cat > "$PKGDIR/DEBIAN/control" <<EOF
Package: siyuan
Version: $VERSION
Architecture: loong64
Maintainer: Yunnan Liandi Technology Co., Ltd. <845765@qq.com>
Section: utils
Priority: optional
Installed-Size: $SIZE
Depends: libgtk-3-0, libnotify4, libnss3, libxss1, libxtst6, libasound2, libsecret-1-0, libgbm1
Description: From thought to insight, with agents
 SiYuan is a privacy-first, self-hosted personal knowledge management system.
EOF

# 无 dpkg-deb 时用 ar + tar 手工构造 deb
TMP=$OUT/deb-tmp
rm -rf "$TMP" && mkdir -p "$TMP"
echo -n "2.0" > "$TMP/debian-binary"
tar -czf "$TMP/control.tar.gz" -C "$PKGDIR/DEBIAN" .
tar -czf "$TMP/data.tar.gz" -C "$PKGDIR" ./opt ./usr
ar rcs "$OUT/siyuan_${VERSION}_loong64.deb" "$TMP/debian-binary" "$TMP/control.tar.gz" "$TMP/data.tar.gz"
rm -rf "$TMP"

ls -lh "$OUT/siyuan-$VERSION-linux-loong64.tar.gz" "$OUT/siyuan_${VERSION}_loong64.deb"
