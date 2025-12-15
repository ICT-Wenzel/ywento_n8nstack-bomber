#!/bin/sh
set -e

if [ -z "${GITHUB_URL}" ]; then
  echo "GITHUB_URL is not set"
  exit 1
fi

work_dir="/home/node/.n8n/n8nworkflows"

# Git Repository synchronisieren
if [ -d "${work_dir}/.git" ]; then
  echo "Aktualisiere Repository..."
  git -C "${work_dir}" pull
else
  echo "Clone Repository..."
  git clone "${GITHUB_URL}" "${work_dir}"
fi

# n8n im Hintergrund starten
echo "Starte n8n..."
n8n &
N8N_PID=$!

# Warten bis n8n wirklich bereit ist
echo "Warte auf n8n..."
for i in $(seq 1 30); do
  if wget -q --spider http://localhost:5678 2>/dev/null; then
    echo "n8n ist bereit!"
    break
  fi
  echo "Warte... ($i/30)"
  sleep 2
done

# Kurze zusätzliche Pause für vollständige Initialisierung
sleep 5

# Import durchführen
if [ -f "${work_dir}/workflow.json" ]; then
  echo "Importiere Workflows..."
  n8n import:workflow --input="${work_dir}/workflow.json" || echo "Import-Fehler ignoriert"
  echo "✓ Import abgeschlossen"
fi

# Auf n8n warten
echo "n8n läuft nun..."
wait $N8N_PID