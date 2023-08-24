#!/bin/bash

# Clone or update the repo
if [ ! -e "/etc/svxlink/svxlink.conf" ] || [ ! -x "$(command -v svxlink)" ]; then
  git clone $GIT_URL /usr/src/svxlink
  cd /usr/src/svxlink
else
  cd /usr/src/svxlink
  git fetch
  git checkout master
  git reset --hard origin/master
fi

# Checkout the wanted branch
if [ -n "$GIT_BRANCH" ]; then
  git checkout $GIT_BRANCH
fi

# Find out how many cores we've got
num_cores=${NUM_CORES:-1}

# Create a build directory and build svxlink

[[ -d build ]] && rm -rf build
mkdir /usr/src/svxlink/build
# cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_SYSCONFDIR=/etc -DUSE_OSS=NO -DUSE_QT=NO \
      -DCMAKE_INSTALL_LOCALSTATEDIR=/var \
      -DCMAKE_BUILD_TYPE=Release ../svxlink/src
make -j$num_cores
	if [ $? -ne 0 ]; then
      echo -e "${ROUGE}Ne peut pas compiler Svxlink - Annulation${NORMAL}"
      exit 1
    fi
make install
make clean
rm -rf /usr/src/svxlink
ldconfig
