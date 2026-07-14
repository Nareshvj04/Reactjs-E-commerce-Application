#!/bin/bash
echo "Stopping old production container instances..."
docker compose down || true

echo "Starting up fresh web server stack on port 80..."
docker compose up -d

