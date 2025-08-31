# DevOps-Web - Ghibli Food Recipe Platform

A comprehensive DevOps solution providing infrastructure as code, container orchestration, CI/CD pipelines, and monitoring for the entire Ghibli Food Recipe application ecosystem.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Project Integration](#project-integration)
- [Quick Setup Guide](#quick-setup-guide)
- [Technology Stack](#technology-stack)
- [Configuration](#configuration)
- [Integration Examples](#integration-examples)
- [Deployment](#deployment)
- [Development](#development)
- [Contributing](#contributing)

---

## Overview

The **DevOps-Web** component serves as the operational foundation for the entire Ghibli Food Recipe platform, providing comprehensive infrastructure management, automated deployment pipelines, and monitoring solutions. This service ensures reliable, scalable, and secure deployment across development, staging, and production environments.

This solution includes Infrastructure as Code with Terraform, container orchestration with Docker and Kubernetes, automated CI/CD pipelines, comprehensive monitoring with Prometheus and Grafana, and advanced security scanning and compliance measures.

---

## Features

### Core Features
- **Infrastructure as Code** - Terraform modules for AWS EKS, RDS, VPC, and ALB provisioning
- **Container Orchestration** - Docker and Kubernetes deployment configurations
- **CI/CD Pipelines** - GitHub Actions and GitLab CI automated workflows
- **Monitoring Stack** - Prometheus, Grafana, and AlertManager integration
- **Automated Deployment** - Multi-environment deployment scripts and workflows

### Advanced Features
- **GitOps Workflow** - ArgoCD for continuous deployment and configuration management
- **Service Mesh** - Istio integration for advanced traffic management and security
- **Security Scanning** - Trivy container vulnerability assessment and compliance checks
- **Auto-scaling** - HPA and VPA for optimal resource utilization
- **Backup & Disaster Recovery** - Automated backup strategies and failover procedures

---

## Project Integration

This DevOps service provides the operational foundation for the entire Ghibli Food Recipe platform:

### 🎨 **Frontend Integration** (Front-End-Web)
- **Static Asset Hosting** - Nginx-based serving with CDN integration and SSL/TLS
- **Build Pipeline** - Automated Vite builds with optimization and minification
- **Environment Configuration** - Dynamic environment variable injection per deployment stage
- **Performance Monitoring** - Real User Monitoring (RUM) and Core Web Vitals tracking

### 🔧 **Backend Integration** (Back-End-Web)
- **API Gateway** - Ingress controller with rate limiting, authentication, and load balancing
- **Container Deployment** - Multiple replica deployment with health checks and rolling updates
- **Environment Isolation** - Separate configurations for development, staging, and production
- **Service Discovery** - Kubernetes service mesh for inter-service communication

### 🗄️ **Database Integration** (Database-Web)
- **Database Hosting** - Managed PostgreSQL on AWS RDS with high availability
- **Backup Automation** - Scheduled backups with retention policies and point-in-time recovery
- **Migration Deployment** - Automated schema updates during application deployments
- **Performance Monitoring** - Database performance metrics and slow query detection

### 🤖 **ML Integration** (Machine-Learning-Web)
- **Model Serving** - High-availability FastAPI deployment with auto-scaling
- **GPU Scheduling** - Optional GPU nodes for intensive ML training workloads
- **Model Storage** - Persistent volumes and S3 integration for model artifacts
- **Performance Monitoring** - Custom metrics for ML model accuracy and inference speed

---

## Quick Setup Guide

### Prerequisites
- **Docker & Docker Compose** for local development and containerization
- **Kubernetes** cluster (local via minikube/kind or cloud provider)
- **Terraform** for infrastructure provisioning
- **kubectl** for Kubernetes cluster management
- **helm** for Kubernetes package management

### Local Development Setup

1. **Clone and Configure Environment**
   ```bash
   cd DevOps-Web/Ghibli-Food-DevOps
   cp .env.example .env.local
   ```
   
   Configure the following variables:
   ```env
   # Environment
   ENVIRONMENT=development
   
   # Docker Registry
   DOCKER_REGISTRY=localhost:5000
   
   # Database
   POSTGRES_PASSWORD=your_strong_password
   
   # Monitoring
   GRAFANA_PASSWORD=admin_password
   ```

2. **Start Local Development Stack**
   ```bash
   # Start all services
   docker-compose -f docker-compose.dev.yml up -d
   ```

3. **Verify Services**
   ```bash
   # Check service status
   docker-compose ps
   
   # Health checks
   curl http://localhost:3000/health      # Frontend
   curl http://localhost:5000/api/v1/health  # Backend
   curl http://localhost:8001/health      # ML Service
   curl http://localhost:3001/health      # Database Admin
   ```

### Production Deployment

1. **Infrastructure Provisioning**
   ```bash
   cd terraform/
   
   # Initialize Terraform
   terraform init
   
   # Plan infrastructure changes
   terraform plan -var-file="environments/production.tfvars"
   
   # Apply infrastructure
   terraform apply -var-file="environments/production.tfvars"
   ```

2. **Application Deployment**
   ```bash
   # Deploy to Kubernetes
   ./scripts/deploy.sh production
   
   # Verify deployment
   kubectl get pods -n ghibli-food
   kubectl get ingress -n ghibli-food
   ```

3. **Monitoring Setup**
   ```bash
   # Install monitoring stack
   helm install monitoring ./helm/monitoring
   
   # Access Grafana
   kubectl port-forward svc/grafana 3000:3000 -n monitoring
   ```

---

## Technology Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| **Docker** | 24+ | Containerization platform |
| **Kubernetes** | 1.28+ | Container orchestration |
| **Terraform** | 1.5+ | Infrastructure as Code |
| **Helm** | 3.x | Kubernetes package manager |
| **GitHub Actions** | Latest | CI/CD automation |
| **Nginx** | 1.24+ | Reverse proxy and load balancer |

### Infrastructure & Cloud
| Technology | Purpose |
|------------|---------|
| **AWS EKS** | Managed Kubernetes service |
| **AWS RDS** | Managed PostgreSQL database |
| **AWS VPC** | Network isolation and security |
| **AWS ALB** | Application load balancing |
| **AWS S3** | Object storage for artifacts |

### Monitoring & Observability
| Technology | Purpose |
|------------|---------|
| **Prometheus** | Metrics collection and storage |
| **Grafana** | Metrics visualization and dashboards |
| **AlertManager** | Alert routing and management |
| **Loki** | Log aggregation and analysis |
| **Jaeger** | Distributed tracing |

---

## Configuration

### Environment Variables

```env
# Environment Configuration
ENVIRONMENT=production
AWS_REGION=us-west-2
CLUSTER_NAME=ghibli-food-cluster

# Docker Configuration
DOCKER_REGISTRY=your-registry.com
IMAGE_TAG=latest

# Database Configuration
DB_INSTANCE_CLASS=db.t3.medium
DB_ALLOCATED_STORAGE=100
DB_BACKUP_RETENTION=7

# Monitoring Configuration
PROMETHEUS_RETENTION=30d
GRAFANA_ADMIN_PASSWORD=your_secure_password
ALERT_EMAIL=alerts@yourdomain.com

# SSL/TLS Configuration
DOMAIN_NAME=ghibli-food.com
SSL_CERT_EMAIL=admin@yourdomain.com

# Scaling Configuration
MIN_REPLICAS=2
MAX_REPLICAS=10
CPU_TARGET_UTILIZATION=70
MEMORY_TARGET_UTILIZATION=80
```

### Kubernetes Configuration
```yaml
# Resource limits and requests
resources:
  frontend:
    requests: { memory: "256Mi", cpu: "250m" }
    limits: { memory: "512Mi", cpu: "500m" }
  backend:
    requests: { memory: "512Mi", cpu: "500m" }
    limits: { memory: "1Gi", cpu: "1000m" }
  ml-service:
    requests: { memory: "1Gi", cpu: "1000m" }
    limits: { memory: "2Gi", cpu: "2000m" }
```

---

## Integration Examples

### Docker Compose Configuration
```yaml
# docker-compose.yml
version: '3.8'

services:
  frontend:
    build:
      context: ../../Front-End-Web/Ghibli-Food-Receipt
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - VITE_API_URL=http://backend:5000/api/v1
      - VITE_ML_URL=http://ml-service:8001
    depends_on:
      - backend
      - ml-service
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  backend:
    build:
      context: ../../Back-End-Web/Ghibli-Food-Receipt-API
      dockerfile: Dockerfile
    ports:
      - "5000:5000"
    environment:
      - NODE_ENV=production
      - DB_HOST=postgres
      - ML_SERVICE_URL=http://ml-service:8001
    depends_on:
      - postgres
      - redis
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/api/v1/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  ml-service:
    build:
      context: ../../Machine-Learnimg-Web/Ghibli-Food-ML
      dockerfile: Dockerfile
    ports:
      - "8001:8001"
    environment:
      - API_PORT=8001
      - DATABASE_URL=postgresql://user:pass@postgres:5432/ghibli_food_db
    depends_on:
      - postgres
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=ghibli_food_db
      - POSTGRES_USER=ghibli_api_user
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ../Database-Web/Ghibli-Food-Database/schemas:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ghibli_api_user"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
  redis_data:
```

### Kubernetes Deployment
```yaml
# kubernetes/deployments/frontend.yaml
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
```

### CI/CD Pipeline
```yaml
# .github/workflows/deploy.yml
name: Deploy Ghibli Food Platform

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: [frontend, backend, ml-service, database]
    steps:
    - uses: actions/checkout@v4
    
    - name: Test Frontend
      if: matrix.service == 'frontend'
      run: |
        cd Front-End-Web/Ghibli-Food-Receipt
        npm ci
        npm run test:ci
        npm run build

    - name: Test Backend
      if: matrix.service == 'backend'
      run: |
        cd Back-End-Web/Ghibli-Food-Receipt-API
        npm ci
        npm run test:ci
        npm run lint

    - name: Test ML Service
      if: matrix.service == 'ml-service'
      run: |
        cd Machine-Learnimg-Web/Ghibli-Food-ML
        pip install -r requirements.txt
        pytest tests/
        flake8 src/

    - name: Test Database
      if: matrix.service == 'database'
      run: |
        cd Database-Web/Ghibli-Food-Database
        npm ci
        npm test

  security-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        format: 'sarif'
        output: 'trivy-results.sarif'

  build:
    needs: [test, security-scan]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - uses: actions/checkout@v4
    
    - name: Build and Push Docker Images
      run: |
        cd DevOps-Web/Ghibli-Food-DevOps
        ./scripts/build-images.sh
        ./scripts/push-images.sh

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - uses: actions/checkout@v4
    
    - name: Deploy to Production
      run: |
        cd DevOps-Web/Ghibli-Food-DevOps
        ./scripts/deploy.sh production
```

### Terraform Infrastructure
```hcl
# terraform/main.tf
terraform {
  required_version = ">= 1.5"
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

# EKS Cluster
module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = var.cluster_name
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

  skip_final_snapshot = var.environment != "production"
  deletion_protection = var.environment == "production"

  tags = local.common_tags
}
```

---

## Deployment

### Deployment Scripts
```bash
#!/bin/bash
# scripts/deploy.sh

set -e

ENVIRONMENT=${1:-development}
ACTION=${2:-deploy}

echo "🚀 Deploying Ghibli Food Platform to $ENVIRONMENT"

# Load environment variables
source .env.$ENVIRONMENT

# Build images if needed
if [[ "$ACTION" == "build" ]] || [[ "$ACTION" == "deploy" ]]; then
    echo "📦 Building Docker images..."
    ./scripts/build-images.sh
    
    if [[ "$ENVIRONMENT" != "development" ]]; then
        ./scripts/push-images.sh
    fi
fi

# Deploy based on environment
case $ENVIRONMENT in
    "development")
        echo "🔧 Starting local development environment..."
        docker-compose -f docker-compose.dev.yml up -d
        ;;
    "staging"|"production")
        echo "☸️ Deploying to Kubernetes cluster..."
        
        # Update kubeconfig
        aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
        
        # Create namespace if not exists
        kubectl create namespace ghibli-food --dry-run=client -o yaml | kubectl apply -f -
        
        # Apply secrets and configs
        kubectl apply -f kubernetes/secrets/$ENVIRONMENT/
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
        ;;
esac

echo "🎉 Ghibli Food Platform deployed to $ENVIRONMENT!"
```

### Monitoring Configuration
```yaml
# helm/monitoring/values.yml
prometheus:
  retention: 30d
  replicas: 2
  resources:
    requests:
      memory: 2Gi
      cpu: 1000m
    limits:
      memory: 4Gi
      cpu: 2000m

grafana:
  adminPassword: ${GRAFANA_ADMIN_PASSWORD}
  persistence:
    enabled: true
    size: 10Gi
  dashboards:
    - name: application-metrics
      folder: Applications
      file: dashboards/application-metrics.json

alertmanager:
  config:
    global:
      smtp_smarthost: 'smtp.gmail.com:587'
      smtp_from: 'alerts@yourdomain.com'
    route:
      group_by: ['alertname']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'web.hook'
    receivers:
    - name: 'web.hook'
      email_configs:
      - to: '${ALERT_EMAIL}'
        subject: 'Ghibli Food Platform Alert'
```

---

## Development

### Development Scripts
```bash
# Local development
npm run dev:local          # Start all services locally
npm run dev:build          # Build all Docker images
npm run dev:logs           # View all service logs

# Infrastructure management
npm run infra:plan         # Plan Terraform changes
npm run infra:apply        # Apply Terraform changes
npm run infra:destroy      # Destroy Terraform resources

# Deployment management
npm run deploy:staging     # Deploy to staging
npm run deploy:production  # Deploy to production
npm run deploy:rollback    # Rollback deployment

# Monitoring and debugging
npm run logs:follow        # Follow logs across all services
npm run debug:port-forward # Set up port forwarding for debugging
npm run health:check       # Check health of all services
```

### Testing
- **Infrastructure Tests**: Terratest for infrastructure validation
- **Integration Tests**: End-to-end testing across all services
- **Security Tests**: Container and infrastructure security scanning
- **Performance Tests**: Load testing and performance benchmarking

### Monitoring and Debugging
- **Service Logs**: Centralized logging with ELK stack
- **Metrics**: Prometheus metrics collection and Grafana visualization
- **Alerts**: AlertManager for proactive issue detection
- **Tracing**: Distributed tracing with Jaeger for request flow analysis

---

## Contributing

1. **Infrastructure Standards**
   - Use Terraform modules for reusable infrastructure components
   - Follow Infrastructure as Code best practices
   - Version all infrastructure changes
   - Use consistent naming conventions across environments

2. **Container Guidelines**
   - Multi-stage Dockerfiles for optimized image sizes
   - Security scanning for all container images
   - Resource limits and health checks for all containers
   - Use Alpine Linux base images when possible

3. **Deployment Practices**
   - Zero-downtime deployments with rolling updates
   - Feature flags for gradual rollouts
   - Automated rollback procedures
   - Comprehensive testing before production deployment

4. **Security Requirements**
   - Regular security scanning of images and infrastructure
   - Network policies for service isolation
   - Secrets management with external secret stores
   - RBAC implementation for Kubernetes access

---

**Part of the Ghibli Food Recipe Platform Ecosystem** 🍜✨