#!/usr/bin/env bash
# 生成 Arch Linux 包：siyuan-<version>-<rel>-loong64.pkg.tar.zst
set -euo pipefail
cd "$(dirname "$0")/../.."

UNPACKED=app/build/linux-unpacked
[ -d "$UNPACKED" ] || { echo "缺少 $UNPACKED，请先运行 build.sh"; exit 1; }
VERSION=$(node -p "require('./app/package.json').version")
REL=${PKGREL:-1}
WORK=app/build/pkgbuild

rm -rf "$WORK"
mkdir -p "$WORK"
cp -a "$UNPACKED" "$WORK/linux-unpacked"
cp -a app/src/assets/icon "$WORK/icons"

cat > "$WORK/PKGBUILD" <<EOF
pkgname=siyuan
pkgver=$VERSION
pkgrel=$REL
pkgdesc="Privacy-first, self-hosted personal knowledge management system"
arch=('loong64')
url="https://b3log.org/siyuan"
license=('AGPL-3.0')
depends=('gtk3' 'nss' 'libxss' 'libxtst' 'alsa-lib' 'libsecret' 'libnotify' 'libxkbcommon' 'mesa')
options=('!strip' '!debug')


package() {
  install -d "\$pkgdir/opt/SiYuan" "\$pkgdir/usr/bin" "\$pkgdir/usr/share/applications"
  cp -a "\$startdir/linux-unpacked/." "\$pkgdir/opt/SiYuan/"
  ln -sf /opt/SiYuan/siyuan "\$pkgdir/usr/bin/siyuan"
  for s in 16 32 48 64 128 256 512; do
    install -Dm644 "\$startdir/icons/\${s}x\${s}.png" \
      "\$pkgdir/usr/share/icons/hicolor/\${s}x\${s}/apps/siyuan.png"
    install -Dm644 "\$startdir/icons/\${s}x\${s}.png" \
      "\$pkgdir/usr/share/icons/hicolor/\${s}x\${s}/apps/SiYuan-Kernel.png"
  done
  install -Dm644 /dev/stdin "\$pkgdir/usr/share/applications/siyuan.desktop" <<'DESK'
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
DESK
}
EOF

CONF_ARGS=()
[ -n "${MAKEPKG_CONF:-}" ] && CONF_ARGS=(--config "$MAKEPKG_CONF")
(cd "$WORK" && makepkg -A -f --nodeps --nocheck "${CONF_ARGS[@]}")
mv "$WORK"/siyuan-"$VERSION"-"$REL"-loong64.pkg.tar.zst app/build/
ls -lh app/build/siyuan-"$VERSION"-"$REL"-loong64.pkg.tar.zst
