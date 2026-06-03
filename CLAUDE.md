# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Eureka Service Discovery cluster running on AWS ECS Fargate, built with Spring Cloud Netflix Eureka (Java/Spring Boot), deployed via Terraform and GitHub Actions.

## GitHub Repository

**URL:** https://github.com/derekdegennaro/eurika-service-discovery (private)

The repository was created and published on 2026-06-02 using the GitHub CLI (`gh`):

```bash
# Install gh CLI
brew install gh

# Authenticate (requires workflow scope to push GitHub Actions files)
gh auth login                                  # initial login
gh auth refresh -h github.com --scopes workflow  # add workflow scope

# Wire gh as git credential helper
gh auth setup-git

# Create private repo from local git repo and push
gh repo create eurika-service-discovery \
  --private \
  --description "Eureka service discovery cluster on AWS ECS Fargate — Spring Boot, Terraform, GitHub Actions" \
  --source . \
  --remote origin \
  --push
```

The `workflow` scope is required because the repo contains `.github/workflows/` files. Without it GitHub rejects the push.

## Repository Structure

```
eurika-service-discovery/
├── src/                        # Spring Boot Eureka Server application
│   └── main/
│       ├── java/
│       └── resources/
├── terraform/                  # All AWS infrastructure (ECS, VPC, ECR, ALB, IAM)
│   ├── environments/
│   │   ├── dev/
│   │   └── prod/
│   └── modules/
│       ├── ecs/
│       ├── networking/
│       └── ecr/
├── .github/
│   └── workflows/
│       ├── build.yml           # Build, test, push Docker image to ECR
│       └── deploy.yml          # Apply Terraform and update ECS service
├── docker-compose.yml          # 3-node local cluster for development
├── Dockerfile
└── pom.xml
```

## Build & Test Commands

```bash
# Build and run tests
mvn clean verify

# Run a single test class
mvn test -Dtest=EurekaServerApplicationTests

# Run tests with a specific method
mvn test -Dtest=ClassName#methodName

# Build without tests
mvn clean package -DskipTests

# Run locally (default port 8761)
mvn spring-boot:run
```

## Local 3-Node Cluster (docker-compose)

`docker-compose.yml` spins up a 3-node Eureka cluster that mirrors the ECS peer replication topology. Each node is pre-configured with the other two as peers via `EUREKA_SERVICE_URL`.

```bash
# Start the cluster (builds image on first run)
docker compose up --build

# Start in background
docker compose up -d --build

# Tail logs for one node
docker compose logs -f eureka1

# Stop and remove containers
docker compose down
```

Dashboards once healthy (start_period is 60s):
- Node 1: http://localhost:8761
- Node 2: http://localhost:8762
- Node 3: http://localhost:8763

Each dashboard's **DS Replicas** section should show the other two nodes as registered peers.

## Docker (single node)

```bash
# Build image
docker build -t eurika-service-discovery .

# Run single node
docker run -p 8761:8761 eurika-service-discovery
```

> **Note:** The Dockerfile uses `maven:3.9-eclipse-temurin-17` and `eclipse-temurin:17-jre-jammy` (debian-based). Alpine variants of these images do not publish arm64 manifests and will fail on Apple Silicon.

## Testing Service Registration with curl

The Eureka REST API accepts JSON. All examples below target node 1 (`localhost:8761`); substitute port 8762 or 8763 to hit other nodes.

**Register an instance**
```bash
curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8761/eureka/apps/MY-SERVICE \
  -H "Content-Type: application/json" \
  -d '{
    "instance": {
      "instanceId":   "my-service-1",
      "hostName":     "localhost",
      "app":          "MY-SERVICE",
      "ipAddr":       "127.0.0.1",
      "status":       "UP",
      "port":         {"$": 8080, "@enabled": "true"},
      "securePort":   {"$": 8443, "@enabled": "false"},
      "dataCenterInfo": {
        "@class": "com.netflix.appinfo.InstanceInfo$DefaultDataCenterInfo",
        "name": "MyOwn"
      },
      "leaseInfo": {
        "renewalIntervalInSecs": 30,
        "durationInSecs":        90
      },
      "vipAddress":       "MY-SERVICE",
      "secureVipAddress": "MY-SERVICE",
      "homePageUrl":      "http://localhost:8080/",
      "statusPageUrl":    "http://localhost:8080/actuator/info",
      "healthCheckUrl":   "http://localhost:8080/actuator/health",
      "metadata": {"@class": "java.util.Collections$EmptyMap"}
    }
  }'
# Expect: 204
```

**List all registered apps**
```bash
curl -s -H "Accept: application/json" http://localhost:8761/eureka/apps | jq .
```

**Query a specific app**
```bash
curl -s -H "Accept: application/json" http://localhost:8761/eureka/apps/MY-SERVICE | jq .
```

**Send a heartbeat** (must be sent every `renewalIntervalInSecs` or the instance expires)
```bash
curl -s -o /dev/null -w "%{http_code}" -X PUT \
  http://localhost:8761/eureka/apps/MY-SERVICE/my-service-1
# Expect: 200
```

**Deregister an instance**
```bash
curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  http://localhost:8761/eureka/apps/MY-SERVICE/my-service-1
# Expect: 200
```

**Take an instance out of service** (without deregistering)
```bash
curl -s -o /dev/null -w "%{http_code}" -X PUT \
  "http://localhost:8761/eureka/apps/MY-SERVICE/my-service-1/status?value=OUT_OF_SERVICE"
# Expect: 200
```

**Verify peer replication** — register on node 1, then query node 2 to confirm replication:
```bash
# Register on node 1
curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8761/eureka/apps/MY-SERVICE \
  -H "Content-Type: application/json" -d '{ ... same payload ... }'

# Confirm replicated to node 2 (allow ~5s for replication)
curl -s -H "Accept: application/json" http://localhost:8762/eureka/apps/MY-SERVICE | jq .
```

## Terraform

All infrastructure lives in `terraform/`. State is stored in S3 with DynamoDB locking.

```bash
# Initialize (run once per environment)
cd terraform/environments/dev
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy environment
terraform destroy
```

Environments (`dev`, `prod`) each have their own `terraform.tfvars` and remote state configuration. Shared infrastructure modules live in `terraform/modules/`.

## GitHub Actions Workflows

- **build.yml** — triggers on push to any branch: runs `mvn verify`, builds Docker image, pushes to ECR (tagged with commit SHA and `latest` on `main`)
- **deploy.yml** — triggers on push to `main` (after build): runs `terraform apply` and forces a new ECS task deployment

Required GitHub Actions secrets:
- `AWS_ROLE_ARN` — ARN of the IAM role to assume via OIDC (e.g. `arn:aws:iam::123456789012:role/github-actions-eurika`)
- `AWS_ACCOUNT_ID`
- `AWS_REGION`
- `TF_STATE_BUCKET` — S3 bucket name for Terraform remote state

## Architecture

**ECS Fargate cluster** runs multiple Eureka server tasks behind an Application Load Balancer. Eureka peers are registered with each other using the ALB DNS name so any task can replicate registry state.

**High availability setup:**
- Minimum 2 Fargate tasks across multiple AZs
- Tasks register with each other via `eureka.client.serviceUrl.defaultZone` pointing to the ALB
- Health checks on `/actuator/health`

**Key Spring Boot config (`application.yml`) pattern:**
```yaml
eureka:
  instance:
    hostname: ${EUREKA_HOSTNAME:localhost}
  client:
    registerWithEureka: true
    fetchRegistry: true
    serviceUrl:
      defaultZone: ${EUREKA_SERVICE_URL:http://localhost:8761/eureka/}
  server:
    enableSelfPreservation: false  # disable in dev; enable in prod
```

`EUREKA_HOSTNAME` and `EUREKA_SERVICE_URL` are injected as ECS task environment variables by Terraform.

## Key Dependencies (pom.xml)

- `spring-cloud-starter-netflix-eureka-server`
- `spring-boot-starter-actuator` (health/readiness probes)
- Spring Boot parent version drives compatible Spring Cloud BOM version — keep these aligned.
