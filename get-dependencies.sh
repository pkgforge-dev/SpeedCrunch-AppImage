#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm cmake qt6-tools

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano ! mesa ! vulkan

# If the application needs to be manually built that has to be done down here

# speedcrunch's tags are still on Qt5 (0.12), no Qt6 tag exists yet
# so this will fail to build until upstream tags a version that works with Qt
# TODO remove this once upstream makes a new tag that builds with Qt6!
exit 1

echo "Building speedcrunch..."
echo "---------------------------------------------------------------"
git clone https://bitbucket.org/heldercorreia/speedcrunch ./speedcrunch && (
	cd ./speedcrunch
6
	git fetch --tags origin
	TAG=$(git tag --sort=-v:refname | grep -vi 'preview\|alpha\|beta' | head -1)
	git checkout "$TAG"

	cmake -S ./src -B ./build -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr
	cmake --build ./build
	cmake --install ./build

	echo "$TAG" > ~/version
)
