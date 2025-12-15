#!/bin/sh
set -euo pipefail

# Simple logger with timestamp
log() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

if [ -z "${GITHUB_URL:-}" ]; then
  log "GITHUB_URL is not set"
  exit 1
fi

work_dir="/home/node/.n8n/n8nworkflows"

mkdir -p "${work_dir}"

# Git repository sync
if [ -d "${work_dir}/.git" ]; then
  log "Aktualisiere Repository..."
  git -C "${work_dir}" pull --ff-only || log "Warnung: git pull fehlgeschlagen"
else
  log "Klonen des Repositories..."
  git clone "${GITHUB_URL}" "${work_dir}"
fi

# Import workflows BEFORE starting n8n to avoid SQLite locking issues
workflow_file="${work_dir}/workflow.json"
if [ -f "${workflow_file}" ]; then
  log "Importiere Workflows aus ${workflow_file} ..."
  if n8n import:workflow --input="${workflow_file}"; then
    log "✓ Workflow-Import erfolgreich abgeschlossen"
  else
    log "Fehler beim Importieren der Workflows (wird fortgesetzt, n8n wird trotzdem gestartet)"
  fi
else
  log "Keine workflow.json im Repository gefunden – Überspringe Import"
fi

# Start n8n in the foreground as the main container process
log "Starte n8n..."
exec n8n