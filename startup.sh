#!/bin/bash

set -e 

if [ -z "$GITHUB_URL" ]; then
  echo "GITHUB_URL is not set as environment variable"
  exit 1
fi

app_dir="/app/streamlit_app"

if [ -d "$app_dir/.git" ]; then
  git -C "$app_dir" pull
else
  git clone "$GITHUB_URL" "$app_dir"
fi

pip install -r "$app_dir/requirements.txt"

exec streamlit run "$app_dir/app.py" \
    --server.port=8501 \
    --server.address=0.0.0.0 \
    --server.headless=true \