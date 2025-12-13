FROM python:3.13-slim

RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app


COPY startup.sh /app/startup.sh
RUN chmod +x /app/startup.sh


CMD ["/app/startup.sh"]

