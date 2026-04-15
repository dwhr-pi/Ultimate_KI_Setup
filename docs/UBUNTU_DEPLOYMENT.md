# Ubuntu Deployment mit Cloudflare

Diese Anleitung beschreibt die naechsten Schritte fuer deinen Test auf Ubuntu mit `botsoft.uk`, `Cloudflare`, `OpenClaw`, `Gemini`, `Ollama` und dem vorgelagerten Reverse Proxy.

## Zielbild

```text
Cloudflare DNS/Proxy
  -> botsoft.uk
  -> Ubuntu VPS
  -> Caddy Proxy
     -> /openclaw
     -> /ollama
```

Wichtig:

- `proxy` ist oeffentlich.
- `openclaw` und `ollama` bleiben intern.
- Gemini ist primaer.
- Ollama ist lokaler Fallback.

## 1. Ubuntu vorbereiten

Als Benutzer mit `sudo`:

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release git
```

Docker Engine und Compose Plugin installieren, falls noch nicht vorhanden:

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER"
newgrp docker
docker --version
docker compose version
```

## 2. Projekt auf Ubuntu ablegen

Beispiel:

```bash
mkdir -p ~/apps
cd ~/apps
git clone <DEIN-REPO-ODER-COPY> ultimate-ki
cd ultimate-ki
```

Wenn du das Repo nicht per Git nutzt, kopiere einfach diese Dateien nach Ubuntu:

- `.env.example`
- `docker-compose.prod.yml`
- `openclaw/openclaw.json`
- `proxy/Caddyfile`
- `README.md`
- `docs/`

## 3. `.env` anlegen

Aus Vorlage erzeugen:

```bash
cp .env.example .env
```

Fuer `botsoft.uk` ist diese Vorlage noch passender:

```bash
cp .env.botsoft.uk.example .env
```

Dann `.env` bearbeiten:

```bash
nano .env
```

Mindestens diese Werte setzen:

```env
DOMAIN=botsoft.uk
PUBLIC_BASE_URL=https://botsoft.uk
ACME_EMAIL=deine-mail@botsoft.uk
OPENCLAW_GATEWAY_TOKEN=einen-langen-zufaelligen-token-setzen
GEMINI_API_KEY=dein-echter-gemini-key
OPENCLAW_PRIMARY_MODEL=google/gemini-2.5-flash
OPENCLAW_FALLBACK_MODEL=ollama/llama3.2:1b
OLLAMA_MODEL=llama3.2:1b
```

Token erzeugen:

```bash
openssl rand -hex 32
```

## 4. Cloudflare korrekt setzen

Fuer `botsoft.uk` in Cloudflare:

1. `A`-Record auf die oeffentliche IPv4 des VPS setzen.
2. Optional `AAAA`-Record auf die oeffentliche IPv6 des VPS setzen.
3. Proxy-Status auf `Proxied` lassen.
4. SSL/TLS in Cloudflare auf `Full (strict)` setzen, sobald das Zertifikat aktiv ist.

Empfehlung:

- `botsoft.uk` direkt auf den VPS zeigen lassen.
- Keine direkte Freigabe von `18789` oder `11434` in der Firewall.
- Nur `80` und `443` von aussen offen lassen.

## 5. Firewall auf Ubuntu

Falls `ufw` aktiv ist:

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status
```

Nicht freigeben:

- `11434`
- `18789`

## 6. Verzeichnisse anlegen

```bash
mkdir -p data/ollama
mkdir -p data/workspace
mkdir -p data/caddy/data
mkdir -p data/caddy/config
mkdir -p openclaw
```

Pruefen, dass `openclaw/openclaw.json` vorhanden ist.

## 7. Stack starten

```bash
docker compose --env-file .env -f docker-compose.prod.yml up -d
```

Status pruefen:

```bash
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs -f proxy
docker compose -f docker-compose.prod.yml logs -f openclaw
docker compose -f docker-compose.prod.yml logs -f ollama
```

## 8. Ollama-Modell laden

Einmalig nach dem ersten Start:

```bash
docker compose -f docker-compose.prod.yml exec ollama ollama pull llama3.2:1b
```

Dann pruefen:

```bash
docker compose -f docker-compose.prod.yml exec ollama ollama list
```

## 9. Healthchecks und Funktion testen

Lokal auf dem VPS:

```bash
curl -fsS http://127.0.0.1
curl -fsS http://127.0.0.1/healthz
curl -I https://botsoft.uk/openclaw
curl https://botsoft.uk/ollama/api/tags
```

Optional intern gegen OpenClaw:

```bash
docker compose -f docker-compose.prod.yml exec openclaw sh -lc 'wget -qO- http://127.0.0.1:18789/healthz'
```

## 10. Wenn etwas nicht startet

### Proxy startet, aber Domain geht nicht

- DNS noch nicht propagiert
- Port `80`/`443` blockiert
- Cloudflare zeigt noch auf falsche IP

### OpenClaw startet nicht

- `OPENCLAW_GATEWAY_TOKEN` fehlt
- Image wurde nicht geladen
- Konfigurationsschema passt nicht zur Image-Version

Dann zuerst Logs ansehen:

```bash
docker compose -f docker-compose.prod.yml logs --tail=200 openclaw
```

### Ollama antwortet, aber kein Modell verfuegbar

Dann das Modell noch einmal ziehen:

```bash
docker compose -f docker-compose.prod.yml exec ollama ollama pull llama3.2:1b
```

## 11. Was du als naechstes tun musst

1. Ubuntu vorbereiten und Docker installieren.
2. Dieses Repo bzw. diese Dateien nach Ubuntu kopieren.
3. `.env` erzeugen und echte Werte eintragen.
4. Cloudflare `A`-/`AAAA`-Record auf den VPS setzen.
5. Nur `80` und `443` in der Firewall oeffnen.
6. `docker compose ... up -d` starten.
7. Ollama-Modell pullen.
8. Domain und Healthchecks testen.

## 12. Sicherheits-Hinweise

- `.env` nie committen.
- `OPENCLAW_GATEWAY_TOKEN` stark und zufaellig setzen.
- `11434` und `18789` nicht direkt veroeffentlichen.
- Falls du spaeter Cloudflare Tunnel statt direkter DNS-Nutzung willst, kann der Proxy-Aufbau fast gleich bleiben.
