#!/bin/sh

set -eu

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1

APP=SpeedCrunch
SITE="heldercorreia/speedcrunch"
UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|continuous|*$ARCH.AppImage.zsync"
APPIMAGETOOL="https://github.com/pkgforge-dev/appimagetool-uruntime/releases/download/continuous/appimagetool-$ARCH.AppImage"

DESKTOP="https://bitbucket.org/heldercorreia/speedcrunch/raw/fa4f5d23f28b6458b54c617230f66af41fc94d7e/pkg/org.speedcrunch.SpeedCrunch.desktop"
ICON="https://bitbucket.org/heldercorreia/speedcrunch/raw/fa4f5d23f28b6458b54c617230f66af41fc94d7e/gfx/speedcrunch.svg"
DARKTHEME="https://raw.githubusercontent.com/pkgforge-dev/SpeedCrunch-AppImage/refs/heads/main/dark.stylesheet"

# CREATE DIRECTORIES
mkdir -p "./$APP/tmp"
cd "./$APP/tmp"

# DOWNLOAD AND EXTRACT THE ARCHIVE
APP_URL=$(curl -Ls https://api.bitbucket.org/2.0/repositories/"$SITE"/downloads \
  | sed 's/[()",{} ]/\n/g' | grep -o 'https.*SpeedCrunch.*64.*bz2$' | head -1)
wget "$APP_URL"
tar fx ./*.tar.*
rm -f ./*.tar.*
cd ..
mkdir -p ./AppDir/usr/bin
mv ./tmp/* ./AppDir/usr/bin
cd ./AppDir

# DESKTOP ENTRY AND ICON
wget "$DESKTOP" -O ./"$APP".desktop
wget "$ICON" -O ./org.speedcrunch.SpeedCrunch.png
ln -s ./org.speedcrunch.SpeedCrunch.png ./.DirIcon

export VERSION="$(echo "$APP_URL" | awk -F"-" '{print $(NF-1)}')"

# AppRun
cat >> ./AppRun << 'EOF'
#!/usr/bin/env sh
CURRENTDIR="$(readlink -f "$(dirname "$0")")"
export GCONV_PATH="$CURRENTDIR/usr/lib/gconv"
[ -f "$APPIMAGE".stylesheet ] && APPIMAGE_QT_THEME="$APPIMAGE.stylesheet"
[ -f "$APPIMAGE_QT_THEME" ] && set -- "$@" "-stylesheet" "$APPIMAGE_QT_THEME"
exec "$CURRENTDIR/ld-linux-x86-64.so.2" \
	--library-path "$CURRENTDIR/usr/lib" \
	"$CURRENTDIR"/usr/bin/speedcrunch "$@"
EOF
chmod +x ./AppRun

# BUNDLE ALL LIBS
mkdir -p ./usr/lib
ldd ./usr/bin/speedcrunch | awk -F"[> ]" '{print $4}' | xargs -I {} cp -vf {} ./usr/lib
mv ./usr/lib/ld-linux-x86-64.so.2 ./ || true
if [ ! -f ./ld-linux-x86-64.so.2 ]; then
  cp /lib64/ld-linux-x86-64.so.2 ./
fi
cp -rv /usr/lib/gconv ./usr/lib/gconv

find ./usr/lib ./usr/bin -type f -exec strip -s -R .comment --strip-unneeded {} ';'

# MAKE APPIMAGE
cd ..
wget -q "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool

# Do the thing!
URUNTIME_PRELOAD=1 ./appimagetool --comp zstd \
  --mksquashfs-opt -Xcompression-level --mksquashfs-opt 22 \
  -n -u "$UPINFO" "$PWD"/AppDir "$PWD"/"$APP"-"$VERSION"-anylinux-"$ARCH".AppImage
mv ./*.AppImage* ..
cd ..
rm -rf ./"$APP" || exit 1
echo "All Done!"
