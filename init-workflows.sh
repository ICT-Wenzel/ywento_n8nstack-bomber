#!/bin/sh
set -e

if [ -z "${GITHUB_URL}" ]; then
    echo "GITHUB_URL is not set"
    exit 1
fi

work_dir="/home/node/.n8n/n8nworkflows"
temp_import="/tmp/n8n_import"

# === SCHRITT 1: Git Sync ===
if [ -d "${work_dir}/.git" ]; then
    echo "Aktualisiere Repository..."
    git -C "${work_dir}" pull
else
    echo "Clone Repository..."
    git clone "${GITHUB_URL}" "${work_dir}"
fi

# === SCHRITT 2: n8n im Hintergrund starten ===
echo "Starte n8n im Hintergrund..."
n8n &
N8N_PID=$!

# === SCHRITT 3: Warten bis n8n bereit ist ===
echo "Warte auf n8n..."
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if curl -f http://localhost:5678/healthz >/dev/null 2>&1; then
        echo "✓ n8n ist bereit!"
        break
    fi
    attempt=$((attempt + 1))
    echo "Warte... ($attempt/$max_attempts)"
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    echo "✗ n8n konnte nicht gestartet werden"
    kill $N8N_PID 2>/dev/null || true
    exit 1
fi

# === SCHRITT 4: Import durchführen ===
echo "Importiere Workflows..."
mkdir -p "${temp_import}"
cp "${work_dir}/workflow.json" "${temp_import}/"
n8n import:workflow --separate --input="${temp_import}"
rm -rf "${temp_import}"
echo "✓ Import abgeschlossen"

# === SCHRITT 5: Im Vordergrund weiterlaufen lassen ===
echo "n8n läuft (PID: $N8N_PID)"
wait $N8N_PID