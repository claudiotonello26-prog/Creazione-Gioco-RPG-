#!/usr/bin/env bash
# Mette online il server di Gym Oath su un server Linux appena creato
# (Ubuntu 24.04). Si lancia come root; si può rilanciare per aggiornare.
#
#   curl -fsSL https://raw.githubusercontent.com/claudiotonello26-prog/Creazione-Gioco-RPG-/main/server/deploy/install.sh | bash
#
# Variabili facoltative: BRANCH (ramo del repository, di base main) e
# SERVER_HOST (un dominio tuo; senza, si usa <ip>.sslip.io, gratis).
set -euo pipefail

REPO=https://github.com/claudiotonello26-prog/Creazione-Gioco-RPG-.git
BRANCH=${BRANCH:-main}
DIR=/opt/gym-oath

if [ "$(id -u)" != 0 ]; then
  echo "Lancialo come root (sudo -i)." >&2
  exit 1
fi

echo "== Programmi: Docker e git"
if ! command -v docker >/dev/null || ! docker compose version >/dev/null 2>&1; then
  apt-get update -q
  apt-get install -y -q ca-certificates curl git
  curl -fsSL https://get.docker.com | sh
fi
command -v git >/dev/null || apt-get install -y -q git

echo "== Codice del server (ramo $BRANCH)"
if [ -d "$DIR/.git" ]; then
  git -C "$DIR" fetch -q origin "$BRANCH"
  git -C "$DIR" checkout -q -B "$BRANCH" "origin/$BRANCH"
else
  git clone -q --depth 1 --branch "$BRANCH" "$REPO" "$DIR"
fi
cd "$DIR/server"

echo "== Password (create una volta sola, restano in $DIR/server/.env)"
if [ ! -f .env ]; then
  rand() { tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$1"; }
  ip=$(curl -fsS https://api.ipify.org || hostname -I | awk '{print $1}')
  cat > .env <<ENV
SERVER_HOST=${SERVER_HOST:-$(echo "$ip" | tr . -).sslip.io}
POSTGRES_PASSWORD=$(rand 32)
NAKAMA_SESSION_KEY=$(rand 32)
NAKAMA_REFRESH_KEY=$(rand 32)
NAKAMA_HTTP_KEY=$(rand 32)
NAKAMA_CONSOLE_PASSWORD=$(rand 20)
ENV
  chmod 600 .env
fi

echo "== Firewall: solo SSH, HTTP e HTTPS"
if command -v ufw >/dev/null; then
  ufw allow OpenSSH >/dev/null
  ufw allow 80/tcp >/dev/null
  ufw allow 443/tcp >/dev/null
  ufw --force enable >/dev/null
fi

echo "== Avvio"
docker compose -f docker-compose.yml -f docker-compose.prod.yml pull -q
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

host=$(grep '^SERVER_HOST=' .env | cut -d= -f2)
echo
echo "Fatto. Aspetta un minuto che arrivi il certificato, poi controlla:"
echo "  curl https://$host/healthcheck"
echo
echo "Nell'app, Impostazioni > Server:  https://$host"
echo "Console di amministrazione (dal tuo PC):"
echo "  ssh -L 7351:127.0.0.1:7351 root@<ip>  poi apri http://localhost:7351"
echo "  utente admin, password in $DIR/server/.env (NAKAMA_CONSOLE_PASSWORD)"
