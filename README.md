# Ultimate KI Setup

Produktionsreifes Basis-Setup fuer `OpenClaw + Ollama + Reverse Proxy` mit klarer Service-Trennung:

- `/openclaw` fuer das OpenClaw Gateway und die Control UI
- `/ollama` fuer die Ollama API
- `/proxy` als vorgelagerter Reverse Proxy

## Analyse des Upstream-Projekts

Das referenzierte Repository `dwhr-pi/VPS-_Kubernate-_Ollama_OpenClaw_installation` ist ein guter Ideen- und Automatisierungs-Startpunkt, aber fuer produktiven Betrieb noch nicht sauber genug:

- Es ist vor allem ein interaktives Shell-Installer-Repository.
- `OpenClaw` wird dort nur per `git clone`, `pnpm install` und `pnpm build` vorbereitet.
- Die eigentliche Konfiguration bleibt weitgehend manuell.
- Es gibt keine klar getrennte, reproduzierbare Drei-Service-Compose-Struktur fuer produktiven Betrieb.
- Healthchecks, Log-Rotation und ein sauberer Reverse Proxy fehlen in einer deploybaren Form.

Dieses Repo liefert deshalb eine bewusst reduzierte, produktionsorientierte Struktur, die sich einfacher auf einem VPS mit `botsoft.uk` betreiben laesst.

## Wichtige Architekturentscheidung

Wenn du mit "Cloudfront" eigentlich `Cloudflare` meinst: Fuer dein DS-Lite-Szenario ist `Cloudflare` die sinnvolle Komponente, nicht Amazon CloudFront.

Warum:

- DS-Lite erschwert eingehende IPv4-Verbindungen zu Hause massiv.
- Ein VPS mit oeffentlicher IPv4/IPv6 ist der richtige externe Eintrittspunkt.
- `botsoft.uk` sollte auf den VPS zeigen und bei Cloudflare idealerweise als proxied DNS-Eintrag laufen.
- Falls du Dienste aus dem Heimnetz statt direkt vom VPS bereitstellen willst, ist `Cloudflare Tunnel` noch sauberer.

## Zielbild

```text
Internet
  -> Cloudflare DNS / Proxy
  -> botsoft.uk
  -> proxy (Caddy)
     -> /openclaw -> OpenClaw Gateway
     -> /ollama   -> Ollama API
```

Dabei gilt:

- `proxy` ist der einzige oeffentlich exponierte Container.
- `openclaw` und `ollama` bleiben nur im internen Docker-Netz.
- Gemini ist primaeres LLM.
- Ollama ist lokaler Fallback fuer OpenClaw.

## Enthaltene Dateien

- `.env.example`
- `.env.botsoft.uk.example`
- `docker-compose.prod.yml`
- `openclaw/openclaw.json`
- `proxy/Caddyfile`
- `.gitignore`
- `docs/UBUNTU_DEPLOYMENT.md`
- `docs/UBUNTU_CLEANUP.md`
- `docs/DEPLOY_CHECKLIST.md`
- `scripts/ubuntu_cleanup.sh`

## Schnellstart

1. `.env.example` nach `.env` kopieren und Werte setzen.
   Fuer deinen Fall kannst du direkt `.env.botsoft.uk.example` als Basis nehmen.
2. Bei Bedarf DNS fuer `botsoft.uk` auf den VPS legen.
3. Stack starten:

```bash
docker compose --env-file .env -f docker-compose.prod.yml up -d
```

4. Lokales Ollama-Fallback-Modell einmalig pullen:

```bash
docker compose -f docker-compose.prod.yml exec ollama ollama pull llama3.2:1b
```

5. Danach testen:

```bash
curl -I https://botsoft.uk/openclaw
curl https://botsoft.uk/ollama/api/tags
```

Ausfuehrliche Schritt-fuer-Schritt-Dokumentation fuer Ubuntu und Cloudflare:

- `docs/UBUNTU_DEPLOYMENT.md`
- `docs/UBUNTU_CLEANUP.md`
- `docs/DEPLOY_CHECKLIST.md`

## Healthchecks und Logging

- `openclaw`: HTTP-Liveness ueber `/healthz`
- `ollama`: CLI-/API-Check auf laufende Instanz
- `proxy`: lokales `/healthz`
- Docker Log-Rotation ist pro Service aktiviert (`json-file`, `max-size`, `max-file`)

## Hinweise zu OpenClaw

Die wichtigste Datei ist `openclaw/openclaw.json`:

- Gateway-Auth laeuft ueber Token.
- Die Control UI wird unter `/openclaw` ausgeliefert.
- Standardmodell ist Gemini.
- Fallback ist Ollama.
- Das gesamte OpenClaw-Config-Verzeichnis wird persistent nach `/home/node/.openclaw` gemountet.

Wenn du spaeter ein anderes lokales Ollama-Modell nutzen willst, passe beides an:

- `OLLAMA_MODEL` in `.env`
- das Modell unter `models.providers.ollama.models` in `openclaw/openclaw.json`

## Empfehlung fuer deinen Fall

Fuer `botsoft.uk` und DS-Lite ist die robusteste Variante:

- Deployment auf dem VPS
- Cloudflare Proxy aktiviert
- OpenClaw nicht direkt auf Port `18789` ins Internet stellen
- nur `80/443` am Proxy veroeffentlichen

Das ist deutlich sicherer und sauberer als ein direkt exponiertes Gateway.
