# SVXLINK #

SvxLink is a project that develops software targeting the ham radio community. It started out as an EchoLink application for Linux back in 2003 but has now evolved to be something much more advanced.

# Installation de Docker

```sh
$ curl -fsSL get.docker.com -o get-docker.sh
$ sudo sh get-docker.sh
```

# Installation de docker-compose **(N'est plus nécessaire)**

- (Debian)

```sh
$ sudo curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
$ chmod +x /usr/local/bin/docker-compose
```

* (Raspberry)

```sh
$ sudo apt-get -y install python-setuptools
$ sudo easy_install pip && sudo pip install docker-compose
```

# Build and Run svxlink
## Importer votre configuration

Ajouter le répertoire `/config` ou renommer `config_example`.

## Construction de l'image

```bash
$ git clone https://github.com/f4hlv/svxlink-docker.git
$ cd svxlink-docker
```

Edit docker-compose.yml and run

```sh
$ docker-compose up -d
```
## Volume
## Fichier spécifique
- `./svxlink.conf:/etc/svxlink/svxlink.conf` Exemple pour svxlink.conf
## Répertoire complet
- `./config/etc/svxlink:/etc/svxlink`
- `./config/usr/svxlink:/usr/share/svxlink`
- `./config/etc/svxlink:/etc/spotnik` (Pour le RRF)

## Console svxlink
Affiche les 500 dernières lignes
```sh
$ docker compose logs -f --tail=500
```

# Mise à jour de l'image svxlink

```sh
$ docker-compose build --no-cache
$ docker-compose up -d
```

# docker-compose

```yml
version: '3.2'
services:
  svxlink:
    build:
      context: .
      dockerfile: Dockerfile
    tty: true
    stdin_open: true
    container_name: svxlink
    ports:
       - 5198:5198/udp  #Echolink
       - 5199:5199/udp  #Echolink
       - 5200:5200/tcp  #Echolink
      #  - 5300:5300    #svxreflector
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./config/etc/svxlink:/etc/svxlink
      # - ./config/etc/spotnik:/etc/spotnik
      - ./config/usr/svxlink:/usr/share/svxlink
      - /sys/class/gpio/gpio22:/sys/class/gpio/gpio22 # GPIO Raspberry
      - /sys/class/gpio/gpio24:/sys/class/gpio/gpio24 # GPIO Raspberry
      - /sys/class/gpio/gpio17:/sys/class/gpio/gpio17 # GPIO Raspberry
      - /sys/class/gpio/gpio23:/sys/class/gpio/gpio23 # GPIO Raspberry
      - /dev/snd:/dev/snd
    environment:
      - GIT_URL=https://github.com/sm0svx/svxlink.git
      # - GIT_BRANCH=master # Branche Github
      - GIT_BRANCH=19.09.2
      - NUM_CORES=4 # CPU 
    devices:
      - /dev/snd:/dev/snd # Audio
    restart: always
```