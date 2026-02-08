# SVXLink Docker Setup

SvxLink is an open-source software suite designed for the **amateur radio (ham radio)** community.  
Originally started in 2003 as an EchoLink application for Linux, SvxLink has evolved into a powerful and flexible system supporting:

- FM repeaters  
- Remote transceivers  
- Reflectors  
- Voice services and logic scripting  

This repository provides a **Docker-based setup** to simplify building, configuring, and running SvxLink in a clean, reproducible environment.

✅ Compatible with **Debian Trixie**  
✅ Supports **GPIOD-based GPIO management**

---

## Features

- Easy deployment using Docker and Docker Compose  
- Run SvxLink, RemoteTrx, and/or SvxReflector from a single image  
- Flexible configuration using volumes  
- Environment variables to control startup behavior  
- Ideal for Raspberry Pi, mini PCs, or servers  

---

## Prerequisites

- Linux host (Debian recommended)
- Docker
- Docker Compose (v2)

---

## Install Docker

If Docker is not already installed on your system, install it using the official script:

```sh
curl -fsSL get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

Verify installation:

```sh
docker --version
docker compose version
```

---

## Build and Run SvxLink

### Clone the Repository

```sh
git clone https://github.com/f4hlv/svxlink-docker.git
cd svxlink-docker
```

### Configure and Start

Edit `docker-compose.yml` to match your needs, then start the container:

### Retrieve Original SvxLink Files

If you want to extract the original SvxLink configuration and data files from the container:

```sh
mkdir -p config/etc config/usr/share

docker compose cp svxlink:/etc/svxlink config/etc/
docker compose cp svxlink:/usr/share/svxlink config/usr/share/
```

This is useful as a starting point for customization.
```sh
docker compose up -d
```

---

## View SvxLink Logs

Display the last 500 log lines and follow output in real time:

```sh
docker compose logs -f --tail=500
```

---

## Update the SvxLink Image

To rebuild the image from scratch and restart the container:

```sh
docker compose build --no-cache
docker compose up -d
```

---

## Configuration Volumes

SvxLink configuration is managed using Docker volumes.

### Import Your Own Configuration

Edit or add files inside the `/config` directory.  
You may override only the files you need or mount full directories.

### Mount a Single Configuration File

Example for `svxlink.conf`:

```yaml
./svxlink.conf:/etc/svxlink/svxlink.conf
```

### Mount Full Directories

```yaml
./config/etc/svxlink:/etc/svxlink
./config/usr/share/svxlink:/usr/share/svxlink
```

---

## Environment Variables

Environment variables allow you to choose which services start and which configuration files are used.

### Enable Services at Startup

Set the value to `1` to enable, `0` to disable:

```env
START_SVXLINK=1
START_REMOTETRX=0
START_SVXREFLECTOR=0
```

### Select Configuration Files

```env
SVXLINK_CONF=/etc/svxlink/svxlink.conf
REMOTETRX_CONF=/etc/svxlink/remotetrx.conf
SVXREFLECTOR_CONF=/etc/svxlink/svxreflector.conf
```

### Log file
Example for svxlink
```env
SVXLINK_ARGS=--logfile=/var/log/svxlink/svxlink.log
```

---

## Notes

- Make sure your audio devices and GPIO access are properly configured on the host
- Running on Raspberry Pi may require additional permissions (`--device`, `--privileged`, or udev rules)
- This setup is intended for experienced amateur radio operators

---

## License

SvxLink is licensed under the **GPL**.  
This Docker setup follows the same spirit of openness and reuse.

---

## Author

Docker setup maintained by **F4HLV**  
Contributions and pull requests are welcome 🚀
