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

# Prüfen ob workflow.json existiert
if [ ! -f "${work_dir}/workflow.json" ]; then
  echo "Keine workflow.json gefunden, starte n8n normal..."
  exec n8n
fi

# Import VOR dem Start
echo "Importiere Workflows..."
n8n import:workflow --input="${work_dir}/workflow.json"

echo "✓ Import abgeschlossen"

# n8n starten
echo "Starte n8n..."
exec n8n