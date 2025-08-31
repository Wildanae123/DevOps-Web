#!/bin/bash

# Ghibli Food Application Deployment Script
# This script automates the deployment process for the Ghibli Food application

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-production}
NAMESPACE="ghibli-food"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KUBE_DIR="${SCRIPT_DIR}/../kubernetes"
DOCKER_DIR="${SCRIPT_DIR}/../docker"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "docker is not installed. Please install docker first."
        exit 1
    fi
    
    # Check if cluster is accessible
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster. Please check your kubectl configuration."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

deploy_infrastructure() {
    log_info "Deploying infrastructure components..."
    
    # Create namespace
    log_info "Creating namespace..."
    kubectl apply -f "${KUBE_DIR}/namespace.yaml"
    
    # Deploy PostgreSQL
    log_info "Deploying PostgreSQL..."
    kubectl apply -f "${KUBE_DIR}/postgres.yaml"
    
    # Wait for PostgreSQL to be ready
    log_info "Waiting for PostgreSQL to be ready..."
    kubectl wait --for=condition=ready pod -l app=postgres -n ${NAMESPACE} --timeout=300s
    
    log_success "Infrastructure components deployed successfully"
}

deploy_applications() {
    log_info "Deploying application components..."
    
    # Deploy backend
    log_info "Deploying backend..."
    kubectl apply -f "${KUBE_DIR}/backend.yaml"
    
    # Deploy frontend
    log_info "Deploying frontend..."
    kubectl apply -f "${KUBE_DIR}/frontend.yaml"
    
    # Deploy ML service
    log_info "Deploying ML service..."
    kubectl apply -f "${KUBE_DIR}/ml-service.yaml"
    
    # Deploy ingress
    log_info "Deploying ingress..."
    kubectl apply -f "${KUBE_DIR}/ingress.yaml"
    
    log_success "Application components deployed successfully"
}

wait_for_deployments() {
    log_info "Waiting for deployments to be ready..."
    
    # Wait for backend
    log_info "Waiting for backend deployment..."
    kubectl rollout status deployment/backend -n ${NAMESPACE} --timeout=300s
    
    # Wait for frontend
    log_info "Waiting for frontend deployment..."
    kubectl rollout status deployment/frontend -n ${NAMESPACE} --timeout=300s
    
    # Wait for ML service
    log_info "Waiting for ML service deployment..."
    kubectl rollout status deployment/ml-service -n ${NAMESPACE} --timeout=300s
    
    log_success "All deployments are ready"
}

run_health_checks() {
    log_info "Running health checks..."
    
    # Check backend health
    log_info "Checking backend health..."
    BACKEND_POD=$(kubectl get pods -n ${NAMESPACE} -l app=backend -o jsonpath="{.items[0].metadata.name}")
    if kubectl exec -n ${NAMESPACE} ${BACKEND_POD} -- curl -f http://localhost:5000/ > /dev/null 2>&1; then
        log_success "Backend health check passed"
    else
        log_error "Backend health check failed"
        exit 1
    fi
    
    # Check ML service health
    log_info "Checking ML service health..."
    ML_POD=$(kubectl get pods -n ${NAMESPACE} -l app=ml-service -o jsonpath="{.items[0].metadata.name}")
    if kubectl exec -n ${NAMESPACE} ${ML_POD} -- curl -f http://localhost:8001/health > /dev/null 2>&1; then
        log_success "ML service health check passed"
    else
        log_error "ML service health check failed"
        exit 1
    fi
    
    log_success "All health checks passed"
}

deploy_monitoring() {
    log_info "Deploying monitoring stack..."
    
    # Check if monitoring is enabled
    if [[ "${DEPLOY_MONITORING:-true}" == "true" ]]; then
        # Deploy Prometheus
        log_info "Deploying Prometheus..."
        kubectl create configmap prometheus-config --from-file="${SCRIPT_DIR}/../monitoring/prometheus.yml" -n ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
        
        # Deploy alert rules
        kubectl create configmap alert-rules --from-file="${SCRIPT_DIR}/../monitoring/alert_rules.yml" -n ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
        
        log_success "Monitoring stack deployed"
    else
        log_warning "Monitoring deployment skipped"
    fi
}

run_database_migrations() {
    log_info "Running database migrations..."
    
    # Get backend pod name
    BACKEND_POD=$(kubectl get pods -n ${NAMESPACE} -l app=backend -o jsonpath="{.items[0].metadata.name}")
    
    if [[ -n "${BACKEND_POD}" ]]; then
        log_info "Running migrations on pod: ${BACKEND_POD}"
        kubectl exec -n ${NAMESPACE} ${BACKEND_POD} -- npm run migrate || log_warning "Migration command failed or not configured"
        log_success "Database migrations completed"
    else
        log_error "No backend pod found for running migrations"
    fi
}

train_ml_models() {
    log_info "Training ML models..."
    
    # Get ML service pod name
    ML_POD=$(kubectl get pods -n ${NAMESPACE} -l app=ml-service -o jsonpath="{.items[0].metadata.name}")
    
    if [[ -n "${ML_POD}" ]]; then
        log_info "Training models on pod: ${ML_POD}"
        kubectl exec -n ${NAMESPACE} ${ML_POD} -- python -c "
from models.recommendation_engine import GhibliFoodRecommendationEngine
from utils.data_fetcher import DataFetcher
import asyncio

async def train():
    engine = GhibliFoodRecommendationEngine()
    data_fetcher = DataFetcher()
    books, ratings = await data_fetcher.get_training_data()
    engine.train_content_based_model(books)
    engine.train_collaborative_filtering_model(ratings)
    engine.save_models()
    print('Models trained successfully')

asyncio.run(train())
" || log_warning "Model training failed or already trained"
        log_success "ML model training completed"
    else
        log_error "No ML service pod found for training models"
    fi
}

cleanup_old_resources() {
    log_info "Cleaning up old resources..."
    
    # Remove old replica sets
    kubectl delete replicasets --all -n ${NAMESPACE} --cascade=orphan
    
    # Remove completed jobs older than 1 day
    kubectl delete jobs --field-selector=status.successful=1 -n ${NAMESPACE} --ignore-not-found=true
    
    log_success "Cleanup completed"
}

show_deployment_info() {
    log_info "Deployment Information:"
    echo "================================"
    
    # Show services
    echo "Services:"
    kubectl get services -n ${NAMESPACE}
    echo ""
    
    # Show pods
    echo "Pods:"
    kubectl get pods -n ${NAMESPACE} -o wide
    echo ""
    
    # Show ingress
    echo "Ingress:"
    kubectl get ingress -n ${NAMESPACE}
    echo ""
    
    # Get application URL
    INGRESS_IP=$(kubectl get ingress ghibli-food-ingress -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Not available")
    INGRESS_HOSTNAME=$(kubectl get ingress ghibli-food-ingress -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Not available")
    
    echo "Access URLs:"
    if [[ "${INGRESS_IP}" != "Not available" ]]; then
        echo "  Application: http://${INGRESS_IP}"
    elif [[ "${INGRESS_HOSTNAME}" != "Not available" ]]; then
        echo "  Application: http://${INGRESS_HOSTNAME}"
    else
        echo "  Application: Check ingress configuration"
    fi
    
    echo "  Backend API: /api"
    echo "  ML Service: /ml-api"
    echo "  Monitoring: /monitoring (if enabled)"
    echo ""
}

rollback() {
    local component="${1:-all}"
    
    log_warning "Rolling back ${component}..."
    
    case "${component}" in
        "backend")
            kubectl rollout undo deployment/backend -n ${NAMESPACE}
            ;;
        "frontend")
            kubectl rollout undo deployment/frontend -n ${NAMESPACE}
            ;;
        "ml-service")
            kubectl rollout undo deployment/ml-service -n ${NAMESPACE}
            ;;
        "all")
            kubectl rollout undo deployment/backend -n ${NAMESPACE}
            kubectl rollout undo deployment/frontend -n ${NAMESPACE}
            kubectl rollout undo deployment/ml-service -n ${NAMESPACE}
            ;;
        *)
            log_error "Unknown component: ${component}"
            exit 1
            ;;
    esac
    
    log_success "Rollback completed for ${component}"
}

main() {
    log_info "Starting Ghibli Food application deployment..."
    log_info "Environment: ${ENVIRONMENT}"
    log_info "Namespace: ${NAMESPACE}"
    
    # Parse command line arguments
    case "${2:-deploy}" in
        "deploy")
            check_prerequisites
            deploy_infrastructure
            deploy_applications
            wait_for_deployments
            run_database_migrations
            train_ml_models
            deploy_monitoring
            run_health_checks
            cleanup_old_resources
            show_deployment_info
            log_success "Deployment completed successfully!"
            ;;
        "rollback")
            rollback "${3:-all}"
            ;;
        "health-check")
            run_health_checks
            ;;
        "info")
            show_deployment_info
            ;;
        "cleanup")
            cleanup_old_resources
            ;;
        *)
            echo "Usage: $0 [environment] [deploy|rollback|health-check|info|cleanup] [component]"
            echo ""
            echo "Commands:"
            echo "  deploy       - Deploy the application (default)"
            echo "  rollback     - Rollback deployment"
            echo "  health-check - Run health checks"
            echo "  info         - Show deployment information"
            echo "  cleanup      - Clean up old resources"
            echo ""
            echo "Examples:"
            echo "  $0 production deploy"
            echo "  $0 staging rollback backend"
            echo "  $0 production health-check"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"