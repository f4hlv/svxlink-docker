#!/bin/sh
# set -e

VERT="\\033[32m"
NORMAL="\\033[39m"
ROUGE="\\033[31m"
JAUNE="\\033[33m"
NC='\033[0m' # No Color


max_attempts=3
current_attempt=1

while [ $current_attempt -le $max_attempts ]; do
    # Vérifiez si l'exécutable svxlink existe
    if [ ! -e "/etc/svxlink/svxlink.conf" ] || [ ! -x "$(command -v svxlink)" ]; then
        echo "${JAUNE}Tentative $current_attempt : Installation de SvxLink.${NC}"
        /app/build_svxlink.sh

        echo "${JAUNE}Tentative $current_attempt : Installation de Spotnik.${NC}"
        # /app/build_spotnik.sh

        current_attempt=$((current_attempt + 1))
        sleep 10  # Pause de 10 secondes entre les tentatives
    fi


    if [ -z "$1" ]; then
        # Lancement de svxlink par défaut
        echo "Lancement de svxlink"
        # svxlink --config /etc/svxlink/svxlink.conf
        # remotetrx
        /etc/spotnik/restart
        # sleep 5
        # /etc/spotnik/view_svx
    else
        # Des arguments ont été passés, exécuter la commande avec les arguments
        echo "Lancement de la commande: $@"
        exec "$@"
    fi

done
echo "${ROUGE}L'installation de SvxLink a rencontré un problème après $max_attempts tentatives.${NC}"


