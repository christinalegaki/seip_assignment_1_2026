# Software Engineering in Practice — Assignment 1 (2026)
## Advanced DevOps: Production-Grade CI/CD, External Configuration, and Orchestration

---

## Project Structure & Component Analysis

Here is an explanation of what each core file in this repository does:

### 1. Dockerization (`Dockerfile`)
* Packages our Node.js application into a lightweight, isolated container image.
* It uses `node:18-alpine` to keep the final file size minimal and secure. It copies `package*.json` and runs `npm install` before copying the rest of the application code. This leverages Docker layer caching, meaning that if you change a line of code in `server.js`, Docker will skip downloading the dependencies again, making future builds near-instant.

### 2. CI/CD Pipeline (`.github/workflows/ci-cd.yaml`)
* Automates our build and deployment process.
* Every time you push code to the `main` branch, GitHub spawns a virtual environment, safely authenticates into the GitHub Container Registry (GHCR) using a temporary `${{ secrets.GITHUB_TOKEN }}`, builds the fresh Docker image, tags it as `:latest`, and publishes it to the cloud registry automatically.

### 3. Configuration Management (`k8s/configmap.yaml`)
* Handles external, non-sensitive environment variables.
* It decouples configuration from code by storing the `WELCOME_MESSAGE` and `NODE_ENV`. This complies with 12-Factor App principles, allowing us to change application behavior without rebuilding the Docker image.

### 4. Secret Management (`k8s/secret.yaml`)
* Securely injects sensitive data into the application container.
* It holds the `API_SECRET_KEY`. To ensure security, this value is manually Base64 encoded within the file, keeping raw plain-text passwords out of our source control.

### 5. Workload Orchestration (`k8s/deployment.yaml`)
* Defines how our application should run and scale inside Kubernetes.
* Spawns exactly 3 replicas (pods) of our application for high availability and load balancing.
* Enforces strict hardware limits (`100m`-`250m` CPU and `128Mi`-`256Mi` RAM) so the application cannot crash the host system.
* Automatically maps and injects keys from both our `ConfigMap` and `Secret` directly into the Node.js runtime process environment.
* Uses `livenessProbe` and `readinessProbe` targeted at `/health`. If a container freezes or becomes unhealthy, Kubernetes automatically terminates it and spins up a fresh one.

### 6. Networking (`k8s/service.yaml`)
* Exposes our pods to network traffic inside the cluster.
* It creates a stable internal IP (`ClusterIP`) acting as a load balancer. It listens on public port `80` and routes incoming internal traffic straight to port `3000` inside our active app containers.

---

## Step-by-Step Deployment Guide

Follow these sequential steps to set up, run, and verify the infrastructure on your local machine.

### Prerequisites
Fist of all, make sure we have Docker Desktop open and running in the background before starting.

### Step 1: Clone the Repository
Open your terminal and download your repository copy:

`git clone [https://github.com/christinalegaki/seip_assignment_1_2026.git](https://github.com/christinalegaki/seip_assignment_1_2026.git)
cd seip_assignment_1_2026`

### Step 2: Spin Up Minikube
Start your local Kubernetes cluster using Docker as the underlying driver:

`minikube start`

### Step 3: Apply Manifests Sequentially
Deploy all the declarative infrastructure components to the cluster at once by applying the entire directory:

`kubectl apply -f k8s/`

You will see confirmation text stating that the ConfigMap, Secret, Deployment, and Service have been successfully created.

### Step 4: Verify Cluster and Component State
Check if your resources are up and running properly:

* `kubectl get all -n default`, to check status of pods, deployments and services
* `kubectl get configmap,secret`, to verify that external configuration objects exist

Ensure all 3 pods display a `RUNNING` status and show `1/1` under the `READY` column before proceeding.

### Step 5: Port Forwarding & Network Mapping
Since ClusterIP isolates the network inside Minikube, map the service port directly to your local computer's loopback interface:

`kubectl port-forward svc/echo-api-service 8080:80`

### Interacting with Endpoints
While the port-forward tunnel is active, open your web browser or use a tool like `curl` to visit the following local URLs:

1. Root Endpoint: `http://localhost:8080/`
Fetches configuration values dynamically. It will display your custom greetings injected securely via the `ConfigMap`.

2. Secure Config Endpoint: `http://localhost:8080/secure-config`
Verifies secret injection. It will safely display an `Authorized` message along with a masked suffix of your secret key, showing that the system read the decoded Base64 `Secret` string perfectly at boot.
