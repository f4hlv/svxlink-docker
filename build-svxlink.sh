#!/usr/bin/env bash
set -euo pipefail

: "${GIT_URL:=https://github.com/sm0svx/svxlink.git}"
: "${GIT_BRANCH:=master}"
: "${NUM_CORES:=1}"

WORKDIR="${WORKDIR:-/build}"
SRC_DIR="${SRC_DIR:-$WORKDIR/svxlink}"
BUILD_DIR="${BUILD_DIR:-$SRC_DIR/build}"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

if [ ! -d "$SRC_DIR/.git" ]; then
  git clone --recursive "$GIT_URL" "$SRC_DIR"
fi

cd "$SRC_DIR"
git fetch --all --tags
git checkout "$GIT_BRANCH"
git submodule update --init --recursive

# Build out-of-tree, comme ton exemple
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_INSTALL_SYSCONFDIR=/etc \
      -DCMAKE_INSTALL_LOCALSTATEDIR=/var \
      -DCPACK_GENERATOR=DEB \
      -DCMAKE_BUILD_TYPE=Release \
      ../src

make -j"$NUM_CORES"
rm -f ./*.deb
make package
dpkg -i ./*.deb

svxlink --version || true
