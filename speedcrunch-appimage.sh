#!/bin/sh

set -ex

ARCH="$(uname -m)"
VERSION=0.12
TARBALL="https://bitbucket.org/heldercorreia/speedcrunch/downloads/SpeedCrunch-$VERSION-linux64.tar.bz2"

ARCH="$(uname -m)"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
URUNTIME_LITE="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-lite-$ARCH"
SHARUN="https://github.com/VHSgunzo/sharun/releases/latest/download/sharun-$ARCH-aio"
UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

DESKTOP="https://bitbucket.org/heldercorreia/speedcrunch/raw/fa4f5d23f28b6458b54c617230f66af41fc94d7e/pkg/org.speedcrunch.SpeedCrunch.desktop"
ICON="https://bitbucket.org/heldercorreia/speedcrunch/raw/fa4f5d23f28b6458b54c617230f66af41fc94d7e/gfx/speedcrunch.svg"


# CREATE DIRECTORIES
mkdir -p ./AppDir/shared/bin && (
	cd ./AppDir
	wget --retry-connrefused --tries=30 "$TARBALL" -O ./speedcrunch.tar.bz2
	tar xvf ./speedcrunch.tar.bz2
	rm -f   ./speedcrunch.tar.bz2
	mv -v   ./speedcrunch  ./shared/bin

	# Add desktop and icon
	wget --retry-connrefused --tries=30 "$DESKTOP" -O  ./speedcrunch.desktop
	wget --retry-connrefused --tries=30 "$ICON"    -O  ./speedcrunch.png
	cp -v ./speedcrunch.png ./.DirIcon

	# deploy libs
	wget --retry-connrefused --tries=30 "$SHARUN" -O ./sharun-aio
	chmod +x ./sharun-aio
	xvfb-run -a -- \
		./sharun-aio l -p -v -e -s -k \
			./shared/bin/speedcrunch \
			/usr/lib/gconv/UTF*      \
			/usr/lib/gconv/UNICODE*  \
			/usr/lib/gconv/LATIN*    \
			/usr/lib/gconv/ANSI*     \
			/usr/lib/gconv/CP*
	rm -f ./sharun-aio

	cat <<-'EOF' >> ./AppRun
	#!/bin/sh
	CURRENTDIR="$(cd "${0%/*}" && echo "$PWD")"
	[ -f "$APPIMAGE".stylesheet ] && APPIMAGE_QT_THEME="$APPIMAGE.stylesheet"
	[ -f "$APPIMAGE_QT_THEME" ] && set -- "$@" "-stylesheet" "$APPIMAGE_QT_THEME"
	exec "$CURRENTDIR"/bin/speedcrunch "$@"
	EOF
	chmod +x ./AppRun

	# prepare sharun
	./sharun -g
)

[ -n "$VERSION" ] && echo "$VERSION" > ~/version

# MAKE APPIMAGE WITH URUNTIME
wget --retry-connrefused --tries=30 "$URUNTIME"      -O  ./uruntime
wget --retry-connrefused --tries=30 "$URUNTIME_LITE" -O  ./uruntime-lite
chmod +x ./uruntime*

# Keep the mount point (speeds up launch time)
sed -i 's|URUNTIME_MOUNT=[0-9]|URUNTIME_MOUNT=0|' ./uruntime-lite

# Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime-lite --appimage-addupdinfo "$UPINFO"

echo "Generating AppImage..."
./uruntime \
	--appimage-mkdwarfs -f               \
	--set-owner 0 --set-group 0          \
	--no-history --no-create-timestamp   \
	--compression zstd:level=22 -S26 -B8 \
	--header uruntime-lite               \
	-i ./AppDir                          \
	-o ./SpeedCrunch-"$VERSION"-anylinux-"$ARCH".AppImage

# make appbundle
UPINFO="$(echo "$UPINFO" | sed 's#.AppImage.zsync#*.AppBundle.zsync#g')"
wget --retry-connrefused --tries=30 \
	"https://github.com/xplshn/pelf/releases/latest/download/pelf_$ARCH" -O ./pelf
chmod +x ./pelf
echo "Generating [dwfs]AppBundle..."
./pelf \
	--compression "-C zstd:level=22 -S26 -B8"      \
	--appbundle-id="SpeedCrunch-$VERSION"            \
	--appimage-compat --disable-use-random-workdir \
	--add-updinfo "$UPINFO"                        \
	--add-appdir ./AppDir                          \
	--output-to ./SpeedCrunch-"$VERSION"-anylinux-"$ARCH".dwfs.AppBundle

zsyncmake ./*.AppImage -u  ./*.AppImage
zsyncmake ./*.AppBundle -u ./*.AppBundle

mkdir -p ./dist
mv -v ./*.AppImage*  ./dist
mv -v ./*.AppBundle* ./dist

echo "All Done!"
