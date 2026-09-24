# Week 3: First Docker Container

I built and ran the Flask incident tracker in Docker on my Ubuntu VM.

## Build
From the repository root:

    cd week-3/app
    docker build -t incident-tracker:1.0 .

## Configure
Create an .env file in week-3/app containing:

    FLASK_SECRET_KEY=your-own-random-secret

Use a randomly generated value instead of the placeholder.
.env is excluded from Git and the Docker image.
.env.example contains only an example value.

## Run
From week-3/app:

    docker run -d -p 8080:5000 --env-file .env --name incident-tracker incident-tracker:1.0

For an existing stopped container:

    docker start incident-tracker

## Test
    docker ps
    curl http://localhost:8080

Open http://localhost:8080 in the Windows browser.
VirtualBox forwards Windows port 8080 to Ubuntu port 8080.
Docker forwards Ubuntu port 8080 to container port 5000.

## Results
The image built successfully, the container ran, and the application
loaded through both curl and the Windows browser.
