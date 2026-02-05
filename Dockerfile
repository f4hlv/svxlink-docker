FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        git cmake g++ make doxygen groff curl sudo \
        libsigc++-2.0-dev libgsm1-dev libpopt-dev tcl8.6-dev \
        libgcrypt20-dev libspeex-dev libasound2-dev alsa-utils \
        vorbis-tools qtbase5-dev qttools5-dev \
        qttools5-dev-tools libopus-dev librtlsdr-dev \
        libjsoncpp-dev libcurl4-openssl-dev libgpiod-dev \
        libogg-dev ladspa-sdk libssl-dev \
        ca-certificates openssl \
    && rm -rf /var/lib/apt/lists/*

ENV GIT_URL=https://github.com/sm0svx/svxlink.git \
    GIT_BRANCH=master \
    NUM_CORES=4

# Compilation de SVXLink
COPY build-svxlink.sh /usr/local/bin/build-svxlink.sh
RUN chmod +x /usr/local/bin/build-svxlink.sh

# Crée un répertoire de build
WORKDIR /build
RUN /usr/local/bin/build-svxlink.sh

# Dossiers usuels
RUN mkdir -p /etc/svxlink /var/log/svxlink /var/lib/svxlink && \
    useradd -r -u 1000 -g audio -G audio,dialout -m -d /home/svx svx || true

ENV SVXLINK_CONF=/etc/svxlink/svxlink.conf \
    SVXLINK_LOG=/var/log/svxlink \
    SVXLINK_RUN_ARGS=""

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
# CMD ["svxlink"]
