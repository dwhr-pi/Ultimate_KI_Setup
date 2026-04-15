# Ubuntu Cleanup

Diese Anleitung hilft dir dabei, alte Installationen von Docker-Containern, OpenClaw, Ollama, lokalen Dateien und optional auch Docker selbst von Ubuntu zu entfernen.

Wichtig:

- Erst pruefen, was wirklich weg soll.
- Nicht blind `/opt`, `/srv`, `~/` oder Docker-Volumes loeschen, wenn dort noch andere Projekte liegen.
- Wenn du nur dieses Projekt entfernen willst, loesche nur dessen Projektordner und die dazugehoerigen Container/Volumes.

## 1. Laufende Container und Compose-Projekte anzeigen

```bash
docker ps -a
docker compose ls
```

## 2. Dieses Projekt sauber stoppen und entfernen

Im Projektordner:

```bash
docker compose -f docker-compose.prod.yml down
```

Wenn du auch die benannten Netzwerke und anonyme Volumes des Compose-Projekts entfernen willst:

```bash
docker compose -f docker-compose.prod.yml down -v --remove-orphans
```

## 3. Projektdaten entfernen

Im Projektordner pruefen:

```bash
pwd
ls -la
```

Danach das Projektverzeichnis entfernen, wenn du sicher bist:

```bash
cd ..
rm -rf ultimate-ki
```

Wenn du einen anderen Ordnernamen verwendet hast, entsprechend anpassen.

## 4. Einzelne Docker-Reste finden

Images:

```bash
docker images
```

Volumes:

```bash
docker volume ls
```

Netzwerke:

```bash
docker network ls
```

Ungenutzte Objekte aufraeumen:

```bash
docker system prune -a
docker volume prune
```

Achtung:

- `docker system prune -a` entfernt auch ungenutzte Images anderer Projekte.
- `docker volume prune` entfernt ungenutzte Volumes aller Projekte.

## 5. Falls du fruehere manuelle OpenClaw-/Ollama-Installationen hattest

Hauefige Orte:

```bash
ls -la ~/openclaw_ultimate_setup
ls -la ~/openclaw
ls -la ~/.openclaw
ls -la ~/.ollama
ls -la /opt/openclaw
```

Wenn du sicher bist, dass sie weg sollen:

```bash
rm -rf ~/openclaw_ultimate_setup
rm -rf ~/openclaw
rm -rf ~/.openclaw
rm -rf ~/.ollama
sudo rm -rf /opt/openclaw
```

## 6. Systemd-Dienste pruefen

Falls fruehere Dienste eingerichtet wurden:

```bash
systemctl --user list-units --type=service | grep -i 'openclaw\|ollama'
sudo systemctl list-units --type=service | grep -i 'openclaw\|ollama'
```

Gefundene Dienste stoppen und deaktivieren:

```bash
systemctl --user stop <dienstname>
systemctl --user disable <dienstname>
sudo systemctl stop <dienstname>
sudo systemctl disable <dienstname>
```

## 7. Docker komplett entfernen

Nur wenn du Docker auf Ubuntu wirklich komplett loswerden willst:

```bash
sudo systemctl stop docker
sudo apt remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo apt autoremove -y --purge
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

Optional auch Docker-Repository wieder entfernen:

```bash
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/keyrings/docker.gpg
sudo apt update
```

## 8. Optionale Komplettbereinigung fuer dieses Repo

Im Repo liegt ein Hilfsscript:

```bash
chmod +x scripts/ubuntu_cleanup.sh
./scripts/ubuntu_cleanup.sh
```

Das Script fragt vor dem Loeschen nach Bestaetigung.

## 9. Was du normalerweise loeschen solltest

Wenn du nur diesen Test rueckgaengig machen willst, reicht meistens:

1. `docker compose down -v --remove-orphans`
2. Projektordner loeschen
3. Falls vorhanden `~/.openclaw`, `~/.ollama` und `/opt/openclaw` loeschen

## 10. Was du nicht vorschnell loeschen solltest

- globale Docker-Images anderer Projekte
- globale Docker-Volumes anderer Projekte
- nginx/caddy/apache anderer Deployments
- `/var/lib/docker`, wenn noch andere Container auf dem Server laufen
