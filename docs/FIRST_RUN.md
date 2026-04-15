# First Run

Diese Datei ist fuer deinen allerersten Test auf Ubuntu gedacht.

Wenn du nur wissen willst, welche Befehle du nacheinander eingeben sollst, arbeite genau diese Liste ab.

## Annahmen

- Du bist per SSH auf deinem Ubuntu-VPS eingeloggt.
- `botsoft.uk` zeigt in Cloudflare bereits auf deinen VPS.
- Du befindest dich in einem leeren oder passenden Arbeitsverzeichnis.

## Die ersten 10 Schritte

### 1. Basis-Pakete installieren

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release git
```

### 2. Docker-Repository einrichten

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 3. Docker installieren

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER"
newgrp docker
docker --version
docker compose version
```

### 4. Projektordner anlegen

```bash
mkdir -p ~/apps/ultimate-ki
cd ~/apps/ultimate-ki
pwd
```

Wenn du das Repo per Git klonst, dann stattdessen:

```bash
mkdir -p ~/apps
cd ~/apps
git clone https://github.com/dwhr-pi/Ultimate_KI_Setup.git ultimate-ki
cd ultimate-ki
```

### 5. Projektdateien pruefen

```bash
ls -la
ls -la openclaw
ls -la proxy
```

Du solltest unter anderem sehen:

- `docker-compose.prod.yml`
- `.env.botsoft.uk.example`
- `openclaw/openclaw.json`
- `proxy/Caddyfile`

### 6. Produktive `.env` anlegen

```bash
cp .env.botsoft.uk.example .env
nano .env
```

Passe mindestens diese Werte an:

```env
ACME_EMAIL=deine-mail@botsoft.uk
OPENCLAW_GATEWAY_TOKEN=hier-einen-langen-zufaelligen-token
GEMINI_API_KEY=hier-deinen-echten-gemini-key
```

Wenn du einen Token brauchst:

```bash
openssl rand -hex 32
```

### 7. Laufzeitordner anlegen

```bash
mkdir -p data/ollama
mkdir -p data/workspace
mkdir -p data/caddy/data
mkdir -p data/caddy/config
```

### 8. Compose-Datei vorab pruefen

```bash
docker compose --env-file .env -f docker-compose.prod.yml config > /tmp/ultimate-ki.compose.rendered.yml
tail -n 40 /tmp/ultimate-ki.compose.rendered.yml
```

Wenn hier ein Fehler erscheint, erst diesen beheben.

### 9. Stack starten

```bash
docker compose --env-file .env -f docker-compose.prod.yml up -d
docker compose -f docker-compose.prod.yml ps
```

### 10. Modell laden und Tests machen

```bash
docker compose -f docker-compose.prod.yml exec ollama ollama pull llama3.2:1b
docker compose -f docker-compose.prod.yml exec ollama ollama list
curl -fsS http://127.0.0.1/healthz
curl -I https://botsoft.uk/openclaw
curl https://botsoft.uk/ollama/api/tags
```

## Wenn etwas schiefgeht

Nutze sofort diese drei Befehle:

```bash
docker compose -f docker-compose.prod.yml logs --tail=100 proxy
docker compose -f docker-compose.prod.yml logs --tail=100 openclaw
docker compose -f docker-compose.prod.yml logs --tail=100 ollama
```

## Danach

Wenn der erste Testlauf funktioniert, arbeite fuer die saubere Absicherung und Kontrolle noch diese Dateien durch:

- `docs/DEPLOY_CHECKLIST.md`
- `docs/UBUNTU_DEPLOYMENT.md`
- `docs/UBUNTU_CLEANUP.md`
