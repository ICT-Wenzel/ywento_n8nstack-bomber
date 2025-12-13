#!/bin/sh
set -e

if [ -z "${GITHUB_URL}" ]; then
  echo "GITHUB_URL is not set"
  exit 1
fi

work_dir="/home/node/.n8n/n8nworkflows"
workflow_dir="/home/node/.n8n/workflows"

if [ -d "${work_dir}/.git" ]; then
  git -C "${work_dir}" pull
else
  git clone "${GITHUB_URL}" "${work_dir}"
fi

mkdir -p "$workflow_dir"

cp "$work_dir"/*.json "$workflow_dir"/

for file in "$workflow_dir"/*.json; do
    n8n import:workflow --input="$file" --overwrite
done

exec n8n