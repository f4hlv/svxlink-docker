#!/bin/sh
set -eu

SVXLINK_CONF="${SVXLINK_CONF:-/etc/svxlink/svxlink.conf}"
REMOTETRX_CONF="${REMOTETRX_CONF:-/etc/svxlink/remotetrx.conf}"
SVXREFLECTOR_CONF="${SVXREFLECTOR_CONF:-/etc/svxlink/svxreflector.conf}"

START_SVXLINK="${START_SVXLINK:-1}"
START_REMOTETRX="${START_REMOTETRX:-0}"
START_SVXREFLECTOR="${START_SVXREFLECTOR:-0}"

SVXLINK_ARGS="${SVXLINK_ARGS:-}"
REMOTETRX_ARGS="${REMOTETRX_ARGS:-}"
SVXREFLECTOR_ARGS="${SVXREFLECTOR_ARGS:-}"

pids=""

log() {
  echo "[$(date -Iseconds)] $*"
}

die() {
  log "ERREUR: $*"
  exit 1
}

need_file_if_enabled() {
  enabled="$1"
  file="$2"
  name="$3"
  if [ "$enabled" = "1" ] && [ ! -f "$file" ]; then
    die "Config $name introuvable: $file (montage volume attendu)"
  fi
}

start_bg() {
  name="$1"
  shift
  log "Démarrage: $name -> $*"
  "$@" &
  pid="$!"
  pids="$pids $pid"
  log "$name lancé (pid=$pid)"
}

stop_all() {
  log "Arrêt demandé, arrêt des processus: $pids"
  for pid in $pids; do
    kill -TERM "$pid" 2>/dev/null || true
  done

  i=0
  while [ $i -lt 10 ]; do
    alive=0
    for pid in $pids; do
      if kill -0 "$pid" 2>/dev/null; then
        alive=1
      fi
    done
    [ "$alive" -eq 0 ] && break
    i=$((i+1))
    sleep 1
  done

  for pid in $pids; do
    kill -KILL "$pid" 2>/dev/null || true
  done
  log "Arrêt terminé."
}

trap 'stop_all; exit 0' INT TERM

# Vérifications des binaires
if [ "$START_SVXLINK" = "1" ] && ! command -v svxlink >/dev/null 2>&1; then
  die "Binaire svxlink introuvable (paquet manquant ?)"
fi
if [ "$START_REMOTETRX" = "1" ] && ! command -v remotetrx >/dev/null 2>&1; then
  die "Binaire remotetrx introuvable (paquet manquant ?)"
fi
if [ "$START_SVXREFLECTOR" = "1" ] && ! command -v svxreflector >/dev/null 2>&1; then
  die "Binaire svxreflector introuvable (paquet manquant ?)"
fi

# Vérif des configs si les services sont activés
need_file_if_enabled "$START_SVXLINK" "$SVXLINK_CONF" "svxlink"
need_file_if_enabled "$START_REMOTETRX" "$REMOTETRX_CONF" "remotetrx"
need_file_if_enabled "$START_SVXREFLECTOR" "$SVXREFLECTOR_CONF" "svxreflector"

# Démarrages
# (souvent pratique de démarrer le reflector en premier s'il est utilisé)
if [ "$START_SVXREFLECTOR" = "1" ]; then
  start_bg "svxreflector" svxreflector --config "$SVXREFLECTOR_CONF" $SVXREFLECTOR_ARGS
fi

if [ "$START_REMOTETRX" = "1" ]; then
  start_bg "remotetrx" remotetrx --config "$REMOTETRX_CONF" $REMOTETRX_ARGS
fi

if [ "$START_SVXLINK" = "1" ]; then
  start_bg "svxlink" svxlink --config "$SVXLINK_CONF" $SVXLINK_ARGS
fi

# Petit message clair si rien n'est activé
# (attention: pids contient un espace initial; on teste sur la présence de chiffres)
if ! echo "$pids" | grep -q '[0-9]'; then
  die "Aucun service activé. Mets START_SVXLINK=1 et/ou START_REMOTETRX=1 et/ou START_SVXREFLECTOR=1"
fi

log "Tous les services demandés sont lancés. Attente…"

exit_code=0
for pid in $pids; do
  if ! wait "$pid"; then
    exit_code=1
  fi
done

log "Fin (exit_code=$exit_code)"
exit "$exit_code"
