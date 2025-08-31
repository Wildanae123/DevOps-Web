# Ghibli Food DevOps

A comprehensive DevOps solution for the Ghibli Food Recipe application, providing infrastructure as code, CI/CD pipelines, monitoring, and deployment automation for the multi-service architecture.

## 🏗️ Architecture Overview

This DevOps project orchestrates the deployment and management of:
- **Backend API** (Node.js/Express) - Recipe and user management
- **Frontend** (React/Vite) - User interface
- **ML Service** (Python/FastAPI) - Recommendation engine
- **PostgreSQL Database** - Data persistence
- **Monitoring Stack** - Prometheus, Grafana, alerting

## 📁 Project Structure

```
Ghibli-Food-DevOps/
├── docker/                    # Docker configurations
│   ├── docker-compose.yml    # Development environment
│   ├── docker-compose.prod.yml # Production overrides
│   └── Dockerfile.frontend    # Custom frontend Dockerfile
├── kubernetes/                # Kubernetes manifests
│   ├── namespace.yaml
│   ├── postgres.yaml
│   ├── backend.yaml
│   ├── frontend.yaml
│   ├── ml-service.yaml
│   └── ingress.yaml
├── ci-cd/                     # CI/CD pipeline configurations
│   ├── .github/workflows/     # GitHub Actions
│   └── .gitlab-ci.yml        # GitLab CI
├── monitoring/                # Monitoring and observability
│   ├── prometheus.yml
│   ├── alert_rules.yml
│   └── grafana/dashboards/
├── terraform/                 # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── iam.tf
├── nginx/                     # Reverse proxy configuration
│   └── nginx.conf
├── scripts/                   # Automation scripts
│   ├── deploy.sh
│   ├── build-images.sh
│   └── setup-infrastructure.sh
└── ansible/                   # Configuration management
    └── playbooks/
```

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- kubectl (Kubernetes CLI)
- Terraform (for AWS infrastructure)
- AWS CLI (configured with credentials)
- Helm (for Kubernetes package management)

### 1. Local Development Setup

```bash
# Clone the repositories (if not already done)
git clone <your-repo-url>
cd DevOps-Web/Ghibli-Food-DevOps

# Start all services locally
cd docker
docker-compose up -d

# Check services
docker-compose ps
```

**Access Points:**
- Frontend: http://localhost:3000
- Backend API: http://localhost:5000
- ML Service: http://localhost:8001
- Grafana: http://localhost:3001 (admin/admin123)
- Prometheus: http://localhost:9090

### 2. Production Infrastructure Setup

```bash
# Set up AWS infrastructure
./scripts/setup-infrastructure.sh production deploy

# Build and push container images
PUSH=true TAG=v1.0.0 ./scripts/build-images.sh build all

# Deploy to Kubernetes
./scripts/deploy.sh production deploy
```

### 3. CI/CD Pipeline Setup

#### GitHub Actions
1. Copy `.github/workflows/ci-cd.yml` to your repository
2. Set up repository secrets:
   ```
   KUBE_CONFIG_STAGING
   KUBE_CONFIG_PROD
   SLACK_WEBHOOK
   ```

#### GitLab CI
1. Copy `.gitlab-ci.yml` to your repository root
2. Configure CI/CD variables in GitLab settings

## 🐳 Container Images

### Building Images

```bash
# Build all images
./scripts/build-images.sh build all

# Build specific service
./scripts/build-images.sh build backend

# Build and push with custom tag
PUSH=true TAG=v1.0.0 ./scripts/build-images.sh build all

# Scan for vulnerabilities
./scripts/build-images.sh scan
```

### Image Registry Configuration

```bash
# GitHub Container Registry
export REGISTRY=ghcr.io
export NAMESPACE=yourusername/ghibli-food
export GITHUB_TOKEN=your_token

# GitLab Container Registry
export REGISTRY=registry.gitlab.com
export NAMESPACE=yourgroup/ghibli-food
```

## ☸️ Kubernetes Deployment

### Manual Deployment

```bash
# Deploy infrastructure components
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/postgres.yaml

# Wait for database
kubectl wait --for=condition=ready pod -l app=postgres -n ghibli-food --timeout=300s

# Deploy applications
kubectl apply -f kubernetes/backend.yaml
kubectl apply -f kubernetes/frontend.yaml
kubectl apply -f kubernetes/ml-service.yaml
kubectl apply -f kubernetes/ingress.yaml

# Check deployment status
kubectl get pods -n ghibli-food
```

### Automated Deployment

```bash
# Full deployment with health checks
./scripts/deploy.sh production deploy

# Rollback deployment
./scripts/deploy.sh production rollback

# Check deployment info
./scripts/deploy.sh production info
```

## 🌩️ AWS Infrastructure

### Terraform Configuration

The infrastructure includes:
- **VPC** with public/private subnets across 3 AZs
- **EKS Cluster** with managed node groups
- **RDS PostgreSQL** with automated backups
- **Application Load Balancer** with SSL termination
- **IAM roles** and security groups
- **CloudWatch** logging and monitoring

### Infrastructure Commands

```bash
# Initialize Terraform
./scripts/setup-infrastructure.sh production init

# Plan changes
./scripts/setup-infrastructure.sh production plan

# Deploy infrastructure
./scripts/setup-infrastructure.sh production deploy

# Show infrastructure info
./scripts/setup-infrastructure.sh production info

# Backup state
./scripts/setup-infrastructure.sh production backup
```

### Terraform Variables

Create `terraform/terraform.tfvars`:
```hcl
aws_region = "us-west-2"
environment = "production"
domain_name = "ghibli-food.example.com"
db_password = "secure-password-here"

# Node configuration
node_desired_size = 3
node_min_size = 1
node_max_size = 10

# Database configuration
db_instance_class = "db.t3.micro"
db_allocated_storage = 20
```

## 📊 Monitoring and Observability

### Metrics Collection

- **Application metrics**: Custom metrics from backend and ML service
- **Infrastructure metrics**: Node Exporter for system metrics
- **Database metrics**: PostgreSQL exporter
- **Container metrics**: cAdvisor for container insights

### Dashboards

Pre-configured Grafana dashboards:
- Application Overview
- Infrastructure Health
- Database Performance
- ML Model Performance

### Alerting

Alert rules for:
- Application downtime
- High error rates
- Resource utilization
- Database connectivity
- ML model performance

### Log Aggregation

- **Loki**: Log aggregation and storage
- **Promtail**: Log collection from containers
- **Grafana**: Log visualization and search

## 🔄 CI/CD Pipeline

### Pipeline Stages

1. **Test**: Unit tests, integration tests, linting
2. **Security**: Vulnerability scanning, dependency audit
3. **Build**: Docker image building with multi-arch support
4. **Deploy**: Automated deployment to staging/production
5. **Monitor**: Post-deployment health checks

### Branch Strategy

- `main`: Production deployments
- `develop`: Staging deployments
- `feature/*`: Feature branches (PR builds)

### Deployment Environments

- **Staging**: Auto-deploy from `develop` branch
- **Production**: Manual approval required for `main` branch

## 🔒 Security

### Security Features

- **Container scanning**: Trivy vulnerability assessment
- **Secrets management**: Kubernetes secrets and AWS Parameter Store
- **Network policies**: Kubernetes network segmentation
- **RBAC**: Role-based access control
- **SSL/TLS**: Automated certificate management
- **Security headers**: Nginx security configuration

### Security Scanning

```bash
# Scan container images
./scripts/build-images.sh scan

# Kubernetes security audit (if kube-score installed)
kube-score score kubernetes/*.yaml
```

## 📈 Scaling and Performance

### Auto-scaling Configuration

- **Horizontal Pod Autoscaler**: CPU/memory-based scaling
- **Cluster Autoscaler**: Node-level scaling
- **Database scaling**: RDS auto-scaling for storage

### Performance Optimization

- **Multi-stage builds**: Optimized container images
- **CDN integration**: Static asset optimization
- **Database optimization**: Connection pooling, indexing
- **Caching**: Redis for application caching

## 🛠️ Maintenance and Operations

### Regular Tasks

```bash
# Update dependencies
./scripts/update-dependencies.sh

# Database backups
kubectl exec -n ghibli-food deployment/postgres -- pg_dump ghibli_food_db

# Log rotation and cleanup
./scripts/cleanup.sh

# Security updates
./scripts/security-updates.sh
```

### Troubleshooting

```bash
# Check application logs
kubectl logs -f deployment/backend -n ghibli-food

# Debug networking issues
kubectl get events -n ghibli-food

# Check resource usage
kubectl top pods -n ghibli-food

# Database connection test
kubectl exec -it deployment/backend -n ghibli-food -- npm run db:test
```

### Backup and Recovery

```bash
# Database backup
kubectl exec deployment/postgres -n ghibli-food -- pg_dump ghibli_food_db > backup.sql

# Application configuration backup
kubectl get all -n ghibli-food -o yaml > app-backup.yaml

# Persistent volume backup
./scripts/backup-volumes.sh
```

## 🔧 Configuration

### Environment Variables

#### Backend Service
```yaml
NODE_ENV: production
DB_HOST: postgres-service
DB_PORT: 5432
JWT_SECRET: <secret>
FRONTEND_ORIGIN: https://ghibli-food.example.com
```

#### Frontend Service
```bash
VITE_API_URL=https://ghibli-food.example.com/api
VITE_ML_API_URL=https://ghibli-food.example.com/ml-api
```

#### ML Service
```yaml
MAIN_API_URL: http://backend-service:5000/api/v1
POSTGRES_SERVER: postgres-service
MODEL_PATH: /app/models/
```

### Domain Configuration

1. Update DNS records to point to the load balancer
2. Configure SSL certificates in AWS Certificate Manager
3. Update ingress configuration with your domain

## 📚 Integration Guide

### Integrating with Existing Projects

1. **Backend Integration**: 
   - Add Dockerfile to your backend project
   - Configure health check endpoints
   - Add metrics endpoints for monitoring

2. **Frontend Integration**:
   - Update build process for containerization
   - Configure environment variables for API endpoints
   - Add health check for the web server

3. **ML Service Integration**:
   - Ensure ML service has proper health checks
   - Configure model persistence storage
   - Add metrics for model performance

## 🤝 Contributing

### Development Workflow

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-deployment-feature`
3. Test changes locally with Docker Compose
4. Update documentation as needed
5. Submit a pull request

### Code Standards

- Use meaningful commit messages
- Follow Infrastructure as Code best practices
- Document all configuration changes
- Test deployment scripts before committing

## 📋 Troubleshooting Guide

### Common Issues

#### Pod Stuck in Pending State
```bash
# Check node resources
kubectl describe nodes

# Check pod events
kubectl describe pod <pod-name> -n ghibli-food
```

#### Database Connection Issues
```bash
# Test database connectivity
kubectl exec -it deployment/backend -n ghibli-food -- nc -zv postgres-service 5432

# Check database logs
kubectl logs deployment/postgres -n ghibli-food
```

#### Load Balancer Not Accessible
```bash
# Check ingress status
kubectl get ingress -n ghibli-food

# Check load balancer controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### Performance Issues
```bash
# Check resource usage
kubectl top pods -n ghibli-food
kubectl top nodes

# Check HPA status
kubectl get hpa -n ghibli-food
```

## 📞 Support

For issues and questions:
- Create an issue in the repository
- Check the monitoring dashboards for system health
- Review application logs for error details
- Consult the troubleshooting guide above

## 📝 License

This project is licensed under the ISC License - see the LICENSE file for details.

## 🔗 Related Projects

- **Back-End-Web/Ghibli-Food-Receipt-API**: Main API server
- **Front-End-Web/Ghibli-Food-Receipt**: React frontend application  
- **Machine-Learning-Web/Ghibli-Food-ML**: ML recommendation service

---

**Infrastructure managed with ❤️ for the Ghibli Food Recipe community**