FROM python:3.13-slim

RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app


COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh


CMD ["/app/start.sh"]

