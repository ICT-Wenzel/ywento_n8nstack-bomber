#!/bin/sh
set -e

if [ -z "${GITHUB_URL}" ]; then
  echo "GITHUB_URL is not set"
  exit 1
fi

work_dir="/home/node/.n8n/n8nworkflows"

if [ -d "${work_dir}/.git" ]; then
  git -C "${work_dir}" pull
else
  git clone "${GITHUB_URL}" "${work_dir}"
fi

n8n &
N8N_PID=$!

sleep 10
n8n import:workflow --input=/home/node/.n8n/n8nworkflows/workflow.json

wait $N8N_PID