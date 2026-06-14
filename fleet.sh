#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="docker-compose-traefik-standalone.yml"

case "${1:-up}" in
  up)
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
