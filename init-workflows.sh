#!/bin/sh
set -e

work_dir="/home/node/.n8n/n8nworkflows"

if [ -z "${GITHUB_URL}" ]; then
    echo "GITHUB_URL is not set"
    exit 1
fi

if [ -d "${work_dir}/.git" ]; then
    echo "Aktualisiere Repository..."
    git -C "${work_dir}" pull
else
    echo "Clone Repository..."
    git clone "${GITHUB_URL}" "${work_dir}"
fi

n8n import:workflow --input=/home/node/.n8n/n8nworkflows/workflows.json