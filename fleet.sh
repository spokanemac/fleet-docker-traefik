#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="docker-compose-traefik-standalone.yml"

preflight() {
  local missing=0
  for f in .env fleet/default.env mysql/default.env config/ACME/acme.json; do
    if [[ ! -f "$f" ]]; then
      echo "Missing $f (see First-time Setup in README.md)" >&2
      missing=1
    fi
  done
  if grep -q CHANGE_ME fleet/default.env mysql/default.env 2>/dev/null; then
    echo "Replace CHANGE_ME placeholders in fleet/default.env and mysql/default.env" >&2
    missing=1
  fi
  [[ $missing -eq 0 ]] || exit 1
}

case "${1:-up}" in
  up)
    preflight
    docker compose -f "$COMPOSE_FILE" pull
    docker compose -f "$COMPOSE_FILE" up -d
    echo "Stack started. Run: docker compose -f $COMPOSE_FILE logs -f to follow logs."
    ;;
  down)
    docker compose -f "$COMPOSE_FILE" down
    ;;
  restart)
    docker compose -f "$COMPOSE_FILE" restart fleet
    ;;
  upgrade)
    preflight
    echo "Current version: $(grep FLEET_VERSION .env)"
    read -rp "New Fleet version (e.g. v4.59.0): " VERSION
    sed -i "s/^FLEET_VERSION=.*/FLEET_VERSION=${VERSION}/" .env
    docker compose -f "$COMPOSE_FILE" pull fleet fleet-migrate
    docker compose -f "$COMPOSE_FILE" up -d fleet-migrate
    docker compose -f "$COMPOSE_FILE" up -d fleet
    docker compose -f "$COMPOSE_FILE" logs -f fleet
    ;;
  *)
    echo "Usage: $0 {up|down|restart|upgrade}"
    exit 1
    ;;
esac
