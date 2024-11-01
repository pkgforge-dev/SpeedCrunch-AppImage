#!/bin/sh
set -u
APP=speedcrunch
SITE="heldercorreia/speedcrunch"
export ARCH="$(uname -m)"
APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage"

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

export VERSION="$(echo "$version" | awk -F"-" '{print $(NF-1)}')"

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
CURRENTDIR="$(readlink -f "$(dirname "$0")")"
export GCONV_PATH="$CURRENTDIR/usr/lib/gconv"
exec "$CURRENTDIR/ld-linux-x86-64.so.2" \
	--library-path "$CURRENTDIR/usr/lib" \
	"$CURRENTDIR"/usr/bin/speedcrunch "$@"
EOF
chmod a+x ./AppRun

# BUNDLE ALL LIBS
mkdir -p ./usr/lib
ldd ./usr/bin/speedcrunch | awk -F"[> ]" '{print $4}' | xargs -I {} cp -f {} ./usr/lib
mv ./usr/lib/ld-linux-x86-64.so.2 ./

if [ ! -f ./ld-linux-x86-64.so.2 ]; then
  cp /lib64/ld-linux-x86-64.so.2 ./ || exit 1
fi

cp -r /usr/lib/gconv ./usr/lib/gconv || exit 1

# MAKE APPIMAGE
cd ..
wget -q "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool

# Do the thing!
./appimagetool --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 10 \
  -u "gh-releases-zsync|Samueru-sama|SpeedCrunch-AppImage|continuous|*x86_64.AppImage.zsync" \
  ./"$APP".AppDir SpeedCrunch-"$VERSION"-"$ARCH".AppImage 
[ -n "$APP" ] && mv ./*.AppImage* .. && cd .. && rm -rf ./"$APP" || exit 1
echo "All Done!"
