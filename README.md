# DevOps Web Projects

This directory contains DevOps and infrastructure management components for web applications.

## Table of Contents
- [Ghibli-Food-DevOps Overview](#ghibli-food-devops)
- [Project Integration](#project-integration)
- [Quick Setup Guide](#quick-setup-guide)
- [Architecture Components](#architecture-components)
- [Deployment Environments](#deployment-environments)
- [Integration Examples](#integration-examples)

---

## Projects

### Ghibli-Food-DevOps
A comprehensive DevOps solution for the Ghibli Food Recipe application ecosystem.

**Core Features:**
- **Infrastructure as Code** with Terraform (AWS EKS, RDS, VPC, ALB)
- **Container Orchestration** with Docker and Kubernetes
- **CI/CD Pipelines** for GitHub Actions and GitLab CI
- **Monitoring Stack** with Prometheus, Grafana, and alerting
- **Automated Deployment** scripts and workflows
- **Security Scanning** with Trivy and container vulnerability assessment
- **Multi-environment Support** (development, staging, production)

**Advanced Features:**
- **GitOps Workflow** with ArgoCD for continuous deployment
- **Service Mesh** with Istio for advanced traffic management
- **Secrets Management** with Kubernetes secrets and external providers
- **Auto-scaling** with HPA and VPA for optimal resource utilization
- **Log Aggregation** with ELK stack for centralized logging
- **Backup & Disaster Recovery** automated backup strategies

---

## 🔗 Project Integration

This DevOps project serves as the operational foundation for the entire Ghibli Food Recipe platform:

### 🎨 Frontend Deployment (Front-End-Web)
- **Static Asset Hosting**: Nginx-based serving with CDN integration
- **Environment Configuration**: Dynamic environment variable injection
- **Build Pipeline**: Automated Vite builds with optimization
- **SSL/TLS**: Automatic certificate management with Let's Encrypt

### 🔧 Backend Deployment (Back-End-Web)
- **API Gateway**: Ingress controller with rate limiting and authentication
- **Load Balancing**: Multiple replica deployment with health checks
- **Database Connection**: Secure connection pooling to PostgreSQL
- **Environment Isolation**: Separate configs for dev, staging, production

### 🗄️ Database Operations (Database-Web)
- **Database Hosting**: Managed PostgreSQL on AWS RDS or Kubernetes
- **Backup Automation**: Scheduled backups with retention policies
- **Migration Deployment**: Automated schema updates during deployments
- **Connection Security**: VPC networking and encryption at rest/in transit

### 🤖 ML Service Deployment (Machine-Learning-Web)
- **Model Serving**: High-availability FastAPI deployment
- **GPU Scheduling**: Optional GPU nodes for intensive training workloads
- **Model Storage**: Persistent volumes for model artifacts
- **Performance Monitoring**: Custom metrics for recommendation accuracy

**Quick Start:**
```bash
cd Ghibli-Food-DevOps

# Local development
docker-compose up -d

# Production infrastructure
./scripts/setup-infrastructure.sh production deploy
./scripts/deploy.sh production deploy
```

**Access Points:**
- **Application**: http://localhost (via Nginx)
- **Backend API**: http://localhost/api
- **ML Service**: http://localhost/ml-api
- **Database Admin**: http://localhost:3001
- **Monitoring**: http://localhost:3002

---

## 🚀 Quick Setup Guide

### Prerequisites
- **Docker & Docker Compose** for local development
- **Kubernetes** cluster (local or cloud)
- **Terraform** for infrastructure provisioning
- **kubectl** for Kubernetes management
- **helm** for package management

### Local Development Setup

1. **Clone and Configure**
   ```bash
   cd DevOps-Web/Ghibli-Food-DevOps
   cp .env.example .env.local
   ```

2. **Start Local Development Stack**
   ```bash
   docker-compose -f docker-compose.local.yml up -d
   ```

3. **Verify Services**
   ```bash
   docker-compose ps
   curl http://localhost:3000/health  # Frontend
   curl http://localhost:5000/api/v1/health  # Backend
   curl http://localhost:8001/health  # ML Service
   ```

### Staging/Production Deployment

1. **Infrastructure Provisioning**
   ```bash
   cd terraform/
   terraform init
   terraform plan -var-file="environments/staging.tfvars"
   terraform apply -var-file="environments/staging.tfvars"
   ```

2. **Application Deployment**
   ```bash
   ./scripts/deploy.sh staging
   ```

3. **Verify Deployment**
   ```bash
   kubectl get pods -n ghibli-food
   kubectl get ingress -n ghibli-food
   ```

---

## 🏗️ Architecture Components

### Container Architecture

```yaml
# docker-compose.yml
version: '3.8'
services:
  frontend:
    build:
      context: ../../Front-End-Web/Ghibli-Food-Receipt
      dockerfile: Dockerfile
    environment:
      - VITE_API_URL=http://backend:5000/api/v1
      - VITE_ML_URL=http://ml-service:8001
    ports:
      - "3000:3000"
    depends_on:
      - backend
      - ml-service

  backend:
    build:
      context: ../../Back-End-Web/Ghibli-Food-Receipt-API
      dockerfile: Dockerfile
    environment:
      - NODE_ENV=production
      - DB_HOST=postgres
      - ML_SERVICE_URL=http://ml-service:8001
      - REDIS_URL=redis://redis:6379
    ports:
      - "5000:5000"
    depends_on:
      - postgres
      - redis

  ml-service:
    build:
      context: ../../Machine-Learnimg-Web/Ghibli-Food-ML
      dockerfile: Dockerfile
    environment:
      - API_PORT=8001
      - DATABASE_URL=postgresql://user:pass@postgres:5432/ghibli_food_db
      - REDIS_URL=redis://redis:6379/1
    ports:
      - "8001:8001"
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=ghibli_food_db
      - POSTGRES_USER=ghibli_api_user
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ../Database-Web/Ghibli-Food-Database/schemas:/docker-entrypoint-initdb.d
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    depends_on:
      - frontend
      - backend
      - ml-service

volumes:
  postgres_data:
  redis_data:
```

### Kubernetes Deployment Manifests

**Frontend Deployment**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: ghibli-food
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: ghibli-food/frontend:latest
        ports:
        - containerPort: 3000
        env:
        - name: VITE_API_URL
          value: "https://api.ghibli-food.com/api/v1"
        - name: VITE_ML_URL
          value: "https://ml.ghibli-food.com"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: ghibli-food
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 3000
  type: ClusterIP
```

**Backend Deployment**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: ghibli-food
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: ghibli-food/backend:latest
        ports:
        - containerPort: 5000
        env:
        - name: NODE_ENV
          value: "production"
        - name: DB_HOST
          value: "postgres-service"
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: app-secret
              key: jwt-secret
        - name: ML_SERVICE_URL
          value: "http://ml-service:8001"
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /api/v1/health
            port: 5000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/v1/health
            port: 5000
          initialDelaySeconds: 10
          periodSeconds: 5
```

### CI/CD Pipeline Configuration

**GitHub Actions Workflow**
```yaml
name: Deploy Ghibli Food Platform
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: [frontend, backend, ml-service]
    steps:
    - uses: actions/checkout@v3
    
    - name: Run Tests - Frontend
      if: matrix.service == 'frontend'
      run: |
        cd Front-End-Web/Ghibli-Food-Receipt
        npm ci
        npm run test:ci
        npm run build

    - name: Run Tests - Backend
      if: matrix.service == 'backend'
      run: |
        cd Back-End-Web/Ghibli-Food-Receipt-API
        npm ci
        npm run test:ci
        npm run lint

    - name: Run Tests - ML Service
      if: matrix.service == 'ml-service'
      run: |
        cd Machine-Learnimg-Web/Ghibli-Food-ML
        pip install -r requirements.txt
        pytest tests/
        flake8 src/

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Login to Container Registry
      uses: docker/login-action@v2
      with:
        registry: ${{ secrets.DOCKER_REGISTRY }}
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
    
    - name: Build and Push Images
      run: |
        cd DevOps-Web/Ghibli-Food-DevOps
        ./scripts/build-images.sh
        ./scripts/push-images.sh

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-west-2
    
    - name: Deploy to Production
      run: |
        cd DevOps-Web/Ghibli-Food-DevOps
        ./scripts/deploy.sh production
```

---

## 🔌 Integration Examples

### Nginx Configuration for Service Routing

```nginx
events {
    worker_connections 1024;
}

http {
    upstream frontend {
        server frontend:3000;
    }
    
    upstream backend {
        server backend:5000;
    }
    
    upstream ml-service {
        server ml-service:8001;
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=ml_limit:10m rate=5r/s;

    server {
        listen 80;
        server_name localhost;

        # Frontend
        location / {
            proxy_pass http://frontend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Backend API
        location /api/ {
            limit_req zone=api_limit burst=20 nodelay;
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # ML Service
        location /ml-api/ {
            limit_req zone=ml_limit burst=10 nodelay;
            rewrite ^/ml-api/(.*) /$1 break;
            proxy_pass http://ml-service;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Database Admin (development only)
        location /db-admin/ {
            proxy_pass http://db-admin:3001;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        # Health checks
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
```

### Monitoring Configuration

**Prometheus Configuration**
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'frontend'
    static_configs:
      - targets: ['frontend:3000']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'backend'
    static_configs:
      - targets: ['backend:5000']
    metrics_path: '/api/v1/metrics'
    scrape_interval: 15s

  - job_name: 'ml-service'
    static_configs:
      - targets: ['ml-service:8001']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']
    scrape_interval: 30s

  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']
    scrape_interval: 30s
```

**Alert Rules**
```yaml
groups:
  - name: application_alerts
    rules:
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High error rate detected"
        description: "Error rate is above 10% for 5 minutes"

    - alert: DatabaseConnectionHigh
      expr: pg_stat_database_numbackends > 80
      for: 2m
      labels:
        severity: critical
      annotations:
        summary: "Database connection count high"
        description: "PostgreSQL connection count is above 80"

    - alert: MLServiceDown
      expr: up{job="ml-service"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "ML Service is down"
        description: "ML recommendation service is not responding"
```

### Terraform Infrastructure

**Main Infrastructure**
```hcl
# main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  enable_vpn_gateway = false
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = local.common_tags
}

# EKS Cluster
module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = "${var.project_name}-cluster"
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  eks_managed_node_groups = {
    main = {
      desired_size = var.node_desired_size
      max_size     = var.node_max_size
      min_size     = var.node_min_size

      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      k8s_labels = {
        Environment = var.environment
        Application = var.project_name
      }
    }
  }

  tags = local.common_tags
}

# RDS Instance
resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-db"

  engine         = "postgres"
  engine_version = "15.3"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = var.db_backup_retention
  backup_window          = var.db_backup_window
  maintenance_window     = var.db_maintenance_window

  skip_final_snapshot = var.environment != "production"
  deletion_protection = var.environment == "production"

  tags = local.common_tags
}
```

### Deployment Automation Scripts

**Build and Deploy Script**
```bash
#!/bin/bash
# scripts/deploy.sh

set -e

ENVIRONMENT=${1:-development}
ACTION=${2:-deploy}

echo "🚀 Deploying Ghibli Food Platform to $ENVIRONMENT"

# Load environment variables
source .env.$ENVIRONMENT

# Build images if not exists or force rebuild
if [[ "$ACTION" == "build" ]] || [[ ! $(docker images -q ghibli-food/frontend:$ENVIRONMENT) ]]; then
    echo "📦 Building Docker images..."
    docker build -t ghibli-food/frontend:$ENVIRONMENT ../../Front-End-Web/Ghibli-Food-Receipt
    docker build -t ghibli-food/backend:$ENVIRONMENT ../../Back-End-Web/Ghibli-Food-Receipt-API
    docker build -t ghibli-food/ml-service:$ENVIRONMENT ../../Machine-Learnimg-Web/Ghibli-Food-ML
    docker build -t ghibli-food/db-admin:$ENVIRONMENT ../../Database-Web/Ghibli-Food-Database
fi

# Deploy based on environment
if [[ "$ENVIRONMENT" == "development" ]]; then
    echo "🔧 Starting local development environment..."
    docker-compose -f docker-compose.dev.yml up -d
elif [[ "$ENVIRONMENT" == "staging" ]] || [[ "$ENVIRONMENT" == "production" ]]; then
    echo "☸️  Deploying to Kubernetes cluster..."
    
    # Update kubeconfig
    aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
    
    # Create namespace if not exists
    kubectl create namespace ghibli-food --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply secrets
    kubectl apply -f kubernetes/secrets/$ENVIRONMENT/
    
    # Apply configurations
    kubectl apply -f kubernetes/configmaps/$ENVIRONMENT/
    
    # Deploy applications
    kubectl apply -f kubernetes/deployments/
    kubectl apply -f kubernetes/services/
    kubectl apply -f kubernetes/ingress/
    
    # Wait for deployments
    kubectl wait --for=condition=available --timeout=300s deployment/frontend -n ghibli-food
    kubectl wait --for=condition=available --timeout=300s deployment/backend -n ghibli-food
    kubectl wait --for=condition=available --timeout=300s deployment/ml-service -n ghibli-food
    
    echo "✅ Deployment completed successfully!"
    
    # Show deployment status
    kubectl get pods -n ghibli-food
    kubectl get ingress -n ghibli-food
fi

echo "🎉 Ghibli Food Platform deployed to $ENVIRONMENT!"
```

## Architecture

```
DevOps-Web/
├── Ghibli-Food-DevOps/      # Complete DevOps solution
│   ├── docker/              # Container configurations
│   ├── kubernetes/          # K8s manifests
│   ├── ci-cd/              # CI/CD pipelines
│   ├── monitoring/          # Observability stack
│   ├── terraform/           # Infrastructure as Code
│   ├── scripts/             # Automation scripts
│   └── nginx/              # Reverse proxy config
└── README.md               # This file
```

## Technology Stack

- **Orchestration**: Kubernetes, Docker Compose
- **Infrastructure**: Terraform, AWS (EKS, RDS, VPC, ALB)
- **CI/CD**: GitHub Actions, GitLab CI
- **Monitoring**: Prometheus, Grafana, Loki, Promtail
- **Security**: Trivy, RBAC, Network policies
- **Networking**: Nginx, Ingress controllers
- **Automation**: Bash scripts, Ansible playbooks

## Integration with Applications

This DevOps project seamlessly integrates with:

1. **Back-End-Web/Ghibli-Food-Receipt-API** - Node.js API server
2. **Front-End-Web/Ghibli-Food-Receipt** - React frontend
3. **Machine-Learning-Web/Ghibli-Food-ML** - Python ML service

## Deployment Environments

### Local Development
- Docker Compose for quick local setup
- All services available on localhost
- Real-time code changes with volume mounts

### Staging
- Kubernetes deployment on AWS EKS
- Automated deployment from `develop` branch
- Full monitoring and logging enabled

### Production
- Highly available Kubernetes cluster
- Manual approval for deployments
- Complete security hardening and monitoring

## Getting Started

1. **Prerequisites Setup**:
   ```bash
   # Install required tools
   brew install docker kubectl terraform helm aws-cli
   # Or use your preferred package manager
   ```

2. **Clone and Setup**:
   ```bash
   git clone <your-repo>
   cd DevOps-Web/Ghibli-Food-DevOps
   ```

3. **Local Development**:
   ```bash
   docker-compose up -d
   ```

4. **Cloud Deployment**:
   ```bash
   ./scripts/setup-infrastructure.sh production deploy
   ```

## Key Features

### 🚀 **Automated Deployments**
- Zero-downtime rolling updates
- Automated rollback on failures
- Environment-specific configurations

### 📊 **Comprehensive Monitoring**
- Real-time application metrics
- Infrastructure health monitoring
- Custom dashboards and alerts

### 🔒 **Security First**
- Container vulnerability scanning
- Network segmentation with policies
- Secrets management and rotation

### 🔄 **CI/CD Integration**
- Multi-branch pipeline support
- Automated testing and quality gates
- Container registry integration

### 📈 **Auto-scaling**
- Horizontal pod autoscaling
- Cluster autoscaling for cost optimization
- Database auto-scaling capabilities

## Monitoring and Observability

- **Metrics**: Prometheus for metrics collection
- **Visualization**: Grafana dashboards
- **Logging**: Loki for log aggregation
- **Alerting**: Alert Manager for notifications
- **Tracing**: Distributed tracing support

## Contributing

1. Follow infrastructure as code best practices
2. Test changes in local environment first
3. Document configuration changes
4. Ensure security compliance

## Support

For DevOps-related issues:
- Check monitoring dashboards for system health
- Review deployment logs and metrics
- Consult the troubleshooting guides
- Create issues for infrastructure problems

---

**Powering reliable deployments for the Ghibli Food Recipe platform** 🍜✨