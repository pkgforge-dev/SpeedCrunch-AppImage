#!/bin/sh
set -u
APP=speedcrunch
SITE="heldercorreia/speedcrunch"

# CREATE DIRECTORIES
[ -n "$APP" ] && mkdir -p "./$APP/tmp" && cd "./$APP/tmp" || exit 1

# DOWNLOAD AND EXTRACT THE ARCHIVE
version=$(curl -Ls https://api.bitbucket.org/2.0/repositories/"$SITE"/downloads | sed 's/[()",{} ]/\n/g' | grep -o 'https.*SpeedCrunch.*64.*bz2$' | head -1)
wget "$version" && tar fx ./*tar* && rm -f ./*tar* || exit 1
cd ..
mkdir -p "./$APP.AppDir/usr/bin" && mv ./tmp/* "./$APP.AppDir/usr/bin" || exit 1
cd "./$APP.AppDir" || exit 1

# DESKTOP ENTRY AND ICON
DESKTOP="https://bitbucket.org/heldercorreia/speedcrunch/raw/fa4f5d23f28b6458b54c617230f66af41fc94d7e/pkg/org.speedcrunch.SpeedCrunch.desktop"
ICON="https://bitbucket.org/heldercorreia/speedcrunch/raw/fa4f5d23f28b6458b54c617230f66af41fc94d7e/gfx/speedcrunch.svg"
wget $DESKTOP -O ./$APP.desktop && wget $ICON -O ./org.speedcrunch.SpeedCrunch.png && ln -s ./$APP.png ./.DirIcon

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
CURRENTDIR="$(readlink -f "$(dirname "$0")")"
exec "$CURRENTDIR"/usr/bin/speedcrunch "$@"
EOF
chmod a+x ./AppRun

# MAKE APPIMAGE
cd ..
APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
wget -q "$APPIMAGETOOL" -O ./appimagetool
chmod a+x ./appimagetool

# Do the thing!
export VERSION="$(echo "$version" | awk -F"-" '{print $(NF-1)}')"
export ARCH=x86_64
./appimagetool --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 1 ./"$APP".AppDir SpeedCrunch-"$VERSION"-"$ARCH".AppImage
[ -n "$APP" ] && mv ./*.AppImage .. && cd .. && rm -rf ./"$APP" || exit 1
echo "All Done!"
