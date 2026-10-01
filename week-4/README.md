# Week 4: Docker Compose and Kubernetes

This project runs the incident tracker with a Flask web container and a PostgreSQL database. Docker Compose was used first, and the stack was then converted into Kubernetes manifests using kompose.

PostgreSQL uses persistent storage so ticket data can survive when a container or pod is replaced.

## Requirements

The week-4/.env file contains the database credentials and Flask secret. This file is ignored by Git and should never be committed.

## Run with Kubernetes

From week-4/, create the Kubernetes Secret from the local .env file:

    kubectl create secret generic db-credentials --from-env-file=.env

If the Secret already exists, this command will report that it already exists.

Apply the Kubernetes manifests:

    kubectl apply -f db-data-persistentvolumeclaim.yaml
    kubectl apply -f env-configmap.yaml
    kubectl apply -f db-service.yaml
    kubectl apply -f web-service.yaml
    kubectl apply -f db-deployment.yaml
    kubectl apply -f web-deployment.yaml

Docker Compose is stopped. Kubernetes now runs the application.

## Check

    kubectl get pods
    kubectl get svc
    kubectl get pvc

Both pods should show 1/1 Running, and the PVC should show Bound.

## Access the Application

Run:

    kubectl port-forward --address 0.0.0.0 service/web 8080:8080

Keep that terminal open and visit http://localhost:8080 in the Windows browser.
