# Fleet Docker Deployment

A Docker Compose deployment for FleetDM with Traefik handling TLS termination.

## Services

- MySQL 8.0
- Redis 7
- Fleet
- Traefik

## Requirements

- Docker and Docker Compose v2
- Ports `80` and `443` open on the host
- A DNS A-record pointing to your host (e.g. `fleet.example.com`)

## First-time Setup

```bash
# Create required directories
mkdir -p fleet/{logs,vulndb} mysql/data

# Fix permissions
sudo chmod -R o+w fleet/{logs,vulndb} mysql/data

# Create the ACME certificate store (Traefik requires mode 600)
mkdir -p config/ACME
touch config/ACME/acme.json
chmod 600 config/ACME/acme.json

# Create the Docker network for Traefik
docker network create traefik_proxy

# Copy and edit the environment file
cp .env.example .env
nano .env

# Copy the credential templates and replace every CHANGE_ME
# (generate values with e.g. `openssl rand -base64 24`)
cp fleet/default.env.example fleet/default.env
cp mysql/default.env.example mysql/default.env
chmod 600 fleet/default.env mysql/default.env
nano fleet/default.env
nano mysql/default.env

# Edit the Traefik config and replace email@example.com with your address
nano config/traefik.toml
```

## Configuration

**`.env`** controls the Fleet version and domain:

```env
FLEET_VERSION=v4.86.2
FLEET_DOMAIN=fleet.example.com
```

**`fleet/default.env`** and **`mysql/default.env`** hold service credentials. They are created from the `*.example` templates and are git-ignored, so secrets never get committed. `FLEET_MYSQL_PASSWORD` must match `MYSQL_PASSWORD`. `fleet.sh` refuses to start while any `CHANGE_ME` placeholder remains.

The Fleet router uses the `secHeaders` middleware from `config/dynamic.yml` (HSTS, nosniff, frame options).

## Usage

All operations go through `fleet.sh`:

```bash
# Start the stack
./fleet.sh up

# Stop the stack
./fleet.sh down

# Restart only the Fleet service
./fleet.sh restart

# Upgrade Fleet to a new version
./fleet.sh upgrade
```

To follow logs after starting:

```bash
docker compose -f docker-compose-traefik-standalone.yml logs -f fleet
```

## Upgrading Fleet

```bash
./fleet.sh upgrade
```

The script will prompt for the new version tag (e.g. `v4.87.0`), update `.env`, pull the new image, run migrations, and restart the Fleet service.

## Data Persistence

All data is stored on the host under the service folders (`mysql/data`, `fleet/logs`, `fleet/vulndb`). Data survives container restarts as long as those directories are not deleted.

## External Traefik Stack

If you prefer to run Traefik as a separate stack shared across multiple projects, use `docker-compose-traefik.yml` instead:

```bash
docker compose -f docker-compose-traefik.yml up -d
```

See [this example repository](https://github.com/cbirkenbeul/docker-homelab/tree/master/compose-files-traefik-predefined/traefik) for a reference Traefik stack setup.
