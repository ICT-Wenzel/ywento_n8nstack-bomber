#!/bin/sh
set -e

if [ -z "${GITHUB_URL}" ]; then
  echo "GITHUB_URL is not set"
  exit 1
fi

work_dir="/home/node/.n8n/n8nworkflows"
temp_import="/tmp/n8n_import"

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

# Import VOR dem Start von n8n
echo "Bereite Import vor..."
mkdir -p "${temp_import}"
cp "${work_dir}/workflow.json" "${temp_import}/"

echo "Importiere Workflows..."
n8n import:workflow --separate --input="${temp_import}"

rm -rf "${temp_import}"
echo "✓ Import abgeschlossen"

# Jetzt n8n starten
echo "Starte n8n..."
exec n8n