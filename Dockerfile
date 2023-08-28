# FROM debian:stable-slim
FROM debian:bullseye

LABEL maintainer="Vincent F4HLV <vincent@f4hlv.fr>" \
      description="Docker image for SvxLink"


# Install required packages and set up the svxlink user
RUN apt-get update && apt-get install -y \
    git cmake g++ make libjsoncpp-dev libsigc++-2.0-dev libgsm1-dev \
    libpopt-dev tcl8.6-dev libgcrypt20-dev libspeex-dev \
    libasound2-dev alsa-utils vorbis-tools \
    libopus-dev librtlsdr-dev libcurl4-openssl-dev curl wget cron mc nano \
    # groff doxygen \
    && rm -rf /var/lib/apt/lists/*


# Create user svxlink
RUN groupadd svxlink \
    && useradd -r -g daemon -G svxlink -c "SvxLink" svxlink

ENV GIT_URL=https://github.com/sm0svx/svxlink.git \
    # GIT_BRANCH=master \
    GIT_BRANCH=19.09.2 \
    NUM_CORES=4

# Set workdir to compile the source code
WORKDIR /root

RUN adduser svxlink dialout

VOLUME /etc/spotnik
VOLUME /etc/svxlink
VOLUME /usr/share/svxlink

COPY build_svxlink.sh /app/build_svxlink.sh
COPY build_spotnik.sh /app/build_spotnik.sh

RUN /app/build_svxlink.sh

EXPOSE 5198
EXPOSE 5199
EXPOSE 5200
EXPOSE 5550

COPY entrypoint.sh /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
