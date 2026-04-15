# Deploy Checklist

Diese Checkliste ist fuer deinen ersten Test auf Ubuntu mit `botsoft.uk`, `Cloudflare`, `OpenClaw`, `Gemini` und `Ollama`.

Arbeite die Punkte der Reihe nach ab.

## 1. Server-Basis pruefen

- [ ] Du hast einen Ubuntu-VPS mit oeffentlicher IPv4.
- [ ] Du kannst dich per SSH anmelden.
- [ ] `sudo` funktioniert.
- [ ] Es laufen keine anderen Webserver auf Port `80` oder `443`.

Pruefen:

```bash
hostnamectl
whoami
sudo -v
sudo ss -tulpn | grep -E ':80|:443'
```

Wenn dort schon `nginx`, `apache2` oder ein anderer Proxy laeuft, zuerst klaeren, ob er weg muss oder Ports angepasst werden muessen.

## 2. Cloudflare vorbereiten

- [ ] `botsoft.uk` ist in Cloudflare vorhanden.
- [ ] Der `A`-Record zeigt auf die IPv4 des VPS.
- [ ] Optional zeigt ein `AAAA`-Record auf die IPv6 des VPS.
- [ ] Der Record ist `Proxied`.

Empfehlung:

- Hostname: `botsoft.uk`
- Proxy: an
- SSL/TLS Modus spaeter: `Full (strict)`

## 3. Ubuntu-Pakete installieren

- [ ] Grundpakete sind installiert.
- [ ] Docker Engine ist installiert.
- [ ] Docker Compose Plugin ist installiert.

Befehle:

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release git
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

Erwartung:

- `docker --version` liefert eine Version.
- `docker compose version` liefert eine Version.

## 4. Projektdateien auf den Server bringen

- [ ] Das Repo oder die Dateien liegen auf Ubuntu.
- [ ] Du befindest dich im richtigen Projektordner.

Beispiel:

```bash
mkdir -p ~/apps
cd ~/apps
git clone <DEIN-REPO-ODER-COPY> ultimate-ki
cd ultimate-ki
pwd
ls -la
```

Im Ordner muessen mindestens vorhanden sein:

- `docker-compose.prod.yml`
- `.env.botsoft.uk.example`
- `openclaw/openclaw.json`
- `proxy/Caddyfile`

## 5. `.env` korrekt anlegen

- [ ] Die produktive `.env` wurde erzeugt.
- [ ] E-Mail gesetzt.
- [ ] Gateway-Token gesetzt.
- [ ] Gemini-Key gesetzt.

Befehl:

```bash
cp .env.botsoft.uk.example .env
nano .env
```

Diese Werte unbedingt anpassen:

```env
ACME_EMAIL=deine-mail@botsoft.uk
OPENCLAW_GATEWAY_TOKEN=hier-einen-langen-zufaelligen-token-eintragen
GEMINI_API_KEY=hier-deinen-echten-gemini-key-eintragen
```

Token erzeugen:

```bash
openssl rand -hex 32
```

Pruefen:

```bash
grep -E '^(DOMAIN|PUBLIC_BASE_URL|ACME_EMAIL|OPENCLAW_GATEWAY_TOKEN|GEMINI_API_KEY)=' .env
```

Erwartung:

- `DOMAIN=botsoft.uk`
- `PUBLIC_BASE_URL=https://botsoft.uk`
- kein Platzhalter mehr bei Token und Gemini-Key

## 6. Firewall sauber setzen

- [ ] Nur `80` und `443` sind von aussen vorgesehen.
- [ ] `11434` und `18789` sind nicht direkt geoefnet.

Falls `ufw` verwendet wird:

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status
```

## 7. Verzeichnisse vorbereiten

- [ ] Datenverzeichnisse existieren.
- [ ] OpenClaw-Konfigurationsordner existiert.

```bash
mkdir -p data/ollama
mkdir -p data/workspace
mkdir -p data/caddy/data
mkdir -p data/caddy/config
mkdir -p openclaw
ls -la openclaw
ls -la data
```

Wichtig:

- `openclaw/openclaw.json` muss vorhanden bleiben.

## 8. Compose-Konfiguration vor dem Start pruefen

- [ ] Compose-Datei wird korrekt aufgeloest.
- [ ] Variablen werden aus `.env` gelesen.

```bash
docker compose --env-file .env -f docker-compose.prod.yml config > /tmp/ultimate-ki.compose.rendered.yml
tail -n 40 /tmp/ultimate-ki.compose.rendered.yml
```

Erwartung:

- kein YAML-Fehler
- drei Services sichtbar: `ollama`, `openclaw`, `proxy`

Wenn hier schon ein Fehler kommt, nicht weitermachen, sondern erst den Fehler beheben.

## 9. Stack starten

- [ ] Container wurden gestartet.

```bash
docker compose --env-file .env -f docker-compose.prod.yml up -d
docker compose -f docker-compose.prod.yml ps
```

Erwartung:

- Container fuer `ollama`, `openclaw`, `proxy` sichtbar
- Status nach kurzer Zeit `healthy` oder mindestens `running`

## 10. Logs direkt nach dem Start pruefen

- [ ] Proxy hat keinen Startfehler.
- [ ] OpenClaw hat keinen Config-/Auth-Fehler.
- [ ] Ollama ist erreichbar.

```bash
docker compose -f docker-compose.prod.yml logs --tail=100 proxy
docker compose -f docker-compose.prod.yml logs --tail=100 openclaw
docker compose -f docker-compose.prod.yml logs --tail=100 ollama
```

Achte besonders auf:

- Zertifikatsfehler
- Port-Bind-Fehler
- `invalid config`
- fehlende Umgebungsvariablen

## 11. Ollama-Modell laden

- [ ] Das Fallback-Modell wurde geladen.

```bash
docker compose -f docker-compose.prod.yml exec ollama ollama pull llama3.2:1b
docker compose -f docker-compose.prod.yml exec ollama ollama list
```

Erwartung:

- `llama3.2:1b` erscheint in der Liste

## 12. Lokale Healthchecks pruefen

- [ ] Proxy lebt lokal.
- [ ] Proxy-Healthcheck antwortet.
- [ ] Ollama antwortet ueber den Proxy.

```bash
curl -fsS http://127.0.0.1
curl -fsS http://127.0.0.1/healthz
curl -fsS http://127.0.0.1/ollama/api/tags
```

Erwartung:

- Root liefert `ultimate-ki proxy up`
- `/healthz` liefert erfolgreich `200`
- `/ollama/api/tags` liefert JSON

## 13. Externe Domain pruefen

- [ ] `botsoft.uk` ist erreichbar.
- [ ] HTTPS funktioniert.
- [ ] `/openclaw` antwortet.
- [ ] `/ollama` antwortet.

```bash
curl -I https://botsoft.uk/openclaw
curl https://botsoft.uk/ollama/api/tags
```

Erwartung:

- HTTPS-Verbindung erfolgreich
- keine direkte Portfreigabe fuer OpenClaw oder Ollama noetig

## 14. Wenn `/openclaw` nicht funktioniert

Pruefen:

```bash
docker compose -f docker-compose.prod.yml logs --tail=200 openclaw
docker compose -f docker-compose.prod.yml logs --tail=200 proxy
```

Moegliche Ursachen:

- OpenClaw-Image erwartet leicht andere Config-Felder
- Container ist noch nicht healthy
- `basePath` oder Proxy-Routing passt nicht zur Image-Version

## 15. Wenn Gemini nicht funktioniert

Pruefen:

```bash
grep GEMINI_API_KEY .env
docker compose -f docker-compose.prod.yml logs --tail=200 openclaw
```

Moegliche Ursachen:

- API-Key falsch
- Quota oder Zugriff bei Google gesperrt
- Modellname muss angepasst werden

Dann als erste Alternative:

```env
OPENCLAW_PRIMARY_MODEL=google/gemini-2.5-flash
```

oder spaeter ein anderes funktionierendes Gemini-Modell setzen.

## 16. Wenn du alte Installationen loeschen willst

Nutze:

- `docs/UBUNTU_CLEANUP.md`
- `scripts/ubuntu_cleanup.sh`

Schnellweg fuer dieses Projekt:

```bash
docker compose -f docker-compose.prod.yml down -v --remove-orphans
```

Danach kannst du Projektordner und alte lokale OpenClaw-/Ollama-Daten entfernen.

## 17. Abschlusscheck

- [ ] Domain zeigt auf den VPS
- [ ] Cloudflare Proxy ist aktiv
- [ ] `.env` enthaelt echte Secrets
- [ ] `proxy`, `openclaw`, `ollama` laufen
- [ ] `llama3.2:1b` ist geladen
- [ ] `https://botsoft.uk/openclaw` antwortet
- [ ] `https://botsoft.uk/ollama/api/tags` antwortet

Wenn alle Punkte erledigt sind, ist dein erster produktiver Testlauf sauber vorbereitet.
