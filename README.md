# SVXLINK #

SvxLink is a project that develops software targeting the ham radio community. It started out as an EchoLink application for Linux back in 2003 but has now evolved to be something much more advanced.

# Install Docker
```console
$ curl -fsSL get.docker.com -o get-docker.sh
$ sudo sh get-docker.sh
```

# Install docker-compose
* (Debian)
```console
$ sudo curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
$ chmod +x /usr/local/bin/docker-compose
```

* (Raspberry)
```console
$ sudo apt-get -y install python-setuptools
$ sudo easy_install pip && sudo pip install docker-compose
```

# Build and Run svxlink
```console
$ git clone https://github.com/f4hlv/svxlink-docker.git
$ cd svxlink-docker
```
Edit docker-compose.yml and run
```console
$ docker-compose up -d
```
## Volume
- `./svxlink.conf:/etc/svxlink/svxlink.conf` Path to the svxlink.conf File
- `./config/ModuleEchoLink.conf:/etc/svxlink/svxlink.d/ModuleEchoLink.conf` Path to the ModuleEchoLink.conf File
## Run console svxlink
```console
$ docker exec -it svxlink screen -x svxlink
```
# Update
```console
$ docker-compose build --no-cache
$ docker-compose up -d
```

# docker-compose
```yml
version: '3'
services:
  svxlink:
    build:
      context: .
      dockerfile: Dockerfile
    tty: true
    stdin_open: true
    container_name: svxlink
    ports:
      - 5198:5198/udp
      - 5199:5199/udp
      - 5200:5200/tcp
    volumes:
      - ./config/svxlink.conf:/etc/svxlink/svxlink.conf:ro
      - ./config/ModuleEchoLink.conf:/etc/svxlink/svxlink.d/ModuleEchoLink.conf:ro
#      - ./config/remotetrx.conf:/etc/svxlink/remotetrx.conf:ro
#      - ./config/sounds:/usr/share/svxlink/sounds:ro
    devices:
      - /dev/snd:/dev/snd
      - /dev/gpiomem:/dev/gpiomem
    restart: always
```
