#!/bin/sh
set -e

if [ -z "${GITHUB_URL}" ]; then
  echo "GITHUB_URL is not set"
  exit 1
fi

work_dir="/home/node/.n8n/n8nworkflows"
temp_import="/tmp/n8n_import"

if [ -d "${work_dir}/.git" ]; then
  git -C "${work_dir}" pull
else
  git clone "${GITHUB_URL}" "${work_dir}"
fi

n8n &
N8N_PID=$!

sleep 10

if [ -f "${work_dir}/workflow.json" ]; then
  echo "Bereite Import vor..."
  mkdir -p "${temp_import}"
  cp "${work_dir}/workflow.json" "${temp_import}/"
  
  echo "Importiere workflow..."
  n8n import:workflow --separate --overwrite --input="${temp_import}"

  rm -rf "${temp_import}"
  echo "✓ Import abgeschlossen"
fi

wait $N8N_PID