# VMS Docker Setup — Quick Start

## First-time setup
1. Install Docker Desktop (or Docker Engine on Ubuntu 24.04 — you're already on it, so `sudo apt install docker.io docker-compose-plugin` works too).
2. Copy the env template and fill in real values:
   ```
   cp .env.example .env
   ```
   Never commit `.env` to git.
3. Put your actual Flutter project files inside `flutter_app/` (replacing the placeholder folder), and your FastAPI code inside `backend/`.

## Start everything
```
docker compose up --build
```
- Backend health check: http://localhost:8000/health
- Flutter web preview (device_preview enabled): http://localhost:8080
- Postgres: localhost:5432 (credentials from your `.env`)

## Everyday commands
| Command | What it does |
|---|---|
| `docker compose up` | Start all services (uses cached build) |
| `docker compose up --build` | Rebuild images first, then start |
| `docker compose down` | Stop and remove containers (DB data survives — it's in a volume) |
| `docker compose down -v` | Stop AND wipe the DB volume (fresh start) |
| `docker compose logs -f backend` | Tail logs for one service |
| `docker compose exec backend bash` | Open a shell inside the running backend container |
| `docker ps` | List currently running containers |
| `docker images` | List built images on your machine |

## How this maps to your VMS requirements
- `db` — PostgreSQL with `pgvector` pre-installed, for face-embedding storage + your encrypted user/officer tables.
- `backend` — FastAPI service for auth, appointments, QR issuance/validation, and (later) face-match calls.
- `flutter-web-preview` — a browser-testable build of your Flutter app with `device_preview` turned on, so you (or teammates) can check the UI across phone/tablet/kiosk screen sizes without needing every physical device. This is separate from your real mobile/kiosk build Docker never runs the actual mobile app, only this web-preview variant.

## Notes
- The `backend` service mounts your local `./backend` folder into the container (`volumes:`), so code edits reload live no rebuild needed for Python changes. You only need `--build` again after changing `requirements.txt` or the `Dockerfile`.
- When you're ready to add face recognition, uncomment `insightface`/`onnxruntime` in `requirements.txt` and rebuild expect that build to take noticeably longer (large ML deps).
