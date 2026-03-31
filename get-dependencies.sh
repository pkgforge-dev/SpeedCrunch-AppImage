#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
# pacman -Syu --noconfirm PACKAGESHERE

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano ! mesa ! vulkan

# Comment this out if you need an AUR package
#make-aur-package PACKAGENAME

echo "Getting binary..."
echo "---------------------------------------------------------------"
VERSION=0.12
echo "$VERSION" > ~/version
TARBALL=https://bitbucket.org/heldercorreia/speedcrunch/downloads/SpeedCrunch-$VERSION-linux64.tar.bz2
wget --retry-connrefused --tries=30 "$TARBALL" -O /tmp/speedcrunch.tar.bz2
mkdir -p ./AppDir/bin
tar xvf /tmp/speedcrunch.tar.bz2
mv -v ./speedcrunch  ./AppDir/bin
