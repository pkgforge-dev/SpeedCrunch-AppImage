#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.bg.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=https://bitbucket.org/heldercorreia/speedcrunch/raw/68c00cbe3fc3d493c76d4d2d2a240e0e8c839778/gfx/speedcrunch.svg
export DESKTOP=https://bitbucket.org/heldercorreia/speedcrunch/raw/68c00cbe3fc3d493c76d4d2d2a240e0e8c839778/pkg/org.speedcrunch.SpeedCrunch.desktop
export ALWAYS_SOFTWARE=1

# Deploy dependencies
quick-sharun ./AppDir/bin/*

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the test fails due to the app
# having issues running in the CI use --simple-test instead
quick-sharun --test ./dist/*.AppImage

