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

# Start n8n first, then import against the running instance
log "Starte n8n..."
n8n &
N8N_PID=$!

# Wait until n8n is ready to accept HTTP connections
log "Warte auf n8n, bis es bereit ist..."
for i in $(seq 1 30); do
  if curl -sf "http://localhost:5678" >/dev/null 2>&1; then
    log "n8n ist bereit (Versuch ${i})"
    break
  fi
  log "n8n noch nicht bereit, warte... (${i}/30)"
  sleep 2
done

# Kurze zusätzliche Pause für vollständige Initialisierung
sleep 5

# Import workflows against the running n8n instance.
# To keep things idempotent and reduce noisy errors, only (re-)import
# when the workflow file content has changed since the last run.
workflow_file="${work_dir}/workflow.json"
import_state_file="/home/node/.n8n/.last_workflow_import.hash"

if [ -f "${workflow_file}" ]; then
  current_hash="$(sha256sum "${workflow_file}" | awk '{print $1}')"
  last_hash=""
  if [ -f "${import_state_file}" ]; then
    last_hash="$(cat "${import_state_file}" 2>/dev/null || true)"
  fi

  if [ "${current_hash}" != "${last_hash}" ]; then
    log "Änderung an workflow.json erkannt (oder erster Import) – importiere Workflows ..."

    max_retries=3
    import_ok=0

    for attempt in $(seq 1 "${max_retries}"); do
      if n8n import:workflow --input="${workflow_file}"; then
        import_ok=1
        break
      fi
      log "Workflow-Import fehlgeschlagen (Versuch ${attempt}/${max_retries}), warte 5 Sekunden und versuche es erneut..."
      sleep 5
    done

    if [ "${import_ok}" -eq 1 ]; then
      log "✓ Workflow-Import erfolgreich abgeschlossen"
      printf '%s\n' "${current_hash}" > "${import_state_file}" || log "Warnung: Konnte Import-Status nicht schreiben"
    else
      log "Fehler beim Importieren der Workflows nach ${max_retries} Versuchen (n8n läuft trotzdem weiter)"
    fi
  else
    log "workflow.json unverändert – Überspringe Import"
  fi
else
  log "Keine workflow.json im Repository gefunden – Überspringe Import"
fi

# Keep container running as long as n8n is running
log "n8n läuft nun, warte auf Prozessende..."
wait "${N8N_PID}"