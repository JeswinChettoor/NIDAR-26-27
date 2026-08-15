#!/usr/bin/env bash

if docker ps --format '{{.Names}}' | grep -q "^nidar_airmouse_dev$"; then
    docker exec -it nidar_airmouse_dev bash
    exit 0
fi

CONTAINER_ID=$(docker ps --filter "name=nidar" --format "{{.ID}}" | head -n 1)

if [ -n "$CONTAINER_ID" ]; then
    docker exec -it "$CONTAINER_ID" bash
else
    echo "Error: No running NIDAR container found. Launch one first using ./run.sh"
    exit 1
fi
