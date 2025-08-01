#!/bin/sh

set -eux

ARCH="$(uname -m)"
case "$ARCH" in
	'x86_64')  PKG_TYPE='x86_64.pkg.tar.zst';;
	'aarch64') PKG_TYPE='aarch64.pkg.tar.xz';;
	''|*) echo "Unknown arch: $ARCH"; exit 1;;
esac

echo "Installing build dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	base-devel        \
	curl              \
	fontconfig        \
	freetype2         \
	git               \
	libxcb            \
	libxcursor        \
	libxi             \
	libxkbcommon      \
	libxkbcommon-x11  \
	libxrandr         \
	libxtst           \
	ncurses           \
	patch             \
	pulseaudio        \
	wget              \
	xorg-server-xvfb  \
	zsync

echo "All done!"
echo "---------------------------------------------------------------"
