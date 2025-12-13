#!/bin/sh
set -e

if [ -z "${GITHUB_URL}" ]; then
  echo "GITHUB_URL is not set"
  exit 1
fi

work_dir="/home/node/.n8n/n8nworkflows"
workflow_dir="/home/node/.n8n/workflows"
workfloqw_file="${workflow_dir}/workflow.json"

# Clone oder pull
if [ -d "${work_dir}/.git" ]; then
  git -C "${work_dir}" pull
else
  git clone "${GITHUB_URL}" "${work_dir}"
fi

n8n import:workflow --input="$workflow_file"


exec n8n
