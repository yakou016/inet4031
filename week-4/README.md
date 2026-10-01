# Week 4: Docker Compose with PostgreSQL

This runs the incident tracker and PostgreSQL together. PostgreSQL stores ticket data in a Docker named volume, so tickets remain after the containers are removed and recreated.

## Requirements

Docker with Compose and a week-4/.env file. Copy .env.example to .env, then replace the example values with real credentials. Do not commit .env.

## Run

From week-4/:

    docker compose up -d --build

## Check

    docker compose ps

Open http://localhost:8080 in a browser. Both containers should report healthy.

## Stop

    docker compose down

This removes the containers but keeps the database volume. Adding -v also deletes the volume and its ticket data.
