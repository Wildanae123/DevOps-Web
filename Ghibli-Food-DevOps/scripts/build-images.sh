#!/bin/bash

# Ghibli Food Application Docker Image Build Script
# This script builds and optionally pushes Docker images for all services

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REGISTRY=${REGISTRY:-"ghcr.io"}
NAMESPACE=${NAMESPACE:-"yourusername/ghibli-food"}
TAG=${TAG:-"latest"}
PUSH=${PUSH:-"false"}
BUILD_ARGS=${BUILD_ARGS:-""}

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../.."
BACKEND_DIR="${ROOT_DIR}/Back-End-Web/Ghibli-Food-Receipt-API"
FRONTEND_DIR="${ROOT_DIR}/Front-End-Web/Ghibli-Food-Receipt"
ML_DIR="${ROOT_DIR}/Machine-Learnimg-Web/Ghibli-Food-ML"
DOCKER_DIR="${SCRIPT_DIR}/../docker"

# Image names
BACKEND_IMAGE="${REGISTRY}/${NAMESPACE}/backend:${TAG}"
FRONTEND_IMAGE="${REGISTRY}/${NAMESPACE}/frontend:${TAG}"
ML_IMAGE="${REGISTRY}/${NAMESPACE}/ml-service:${TAG}"

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
    
    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
    
    # Check if required directories exist
    if [[ ! -d "${BACKEND_DIR}" ]]; then
        log_error "Backend directory not found: ${BACKEND_DIR}"
        exit 1
    fi
    
    if [[ ! -d "${FRONTEND_DIR}" ]]; then
        log_error "Frontend directory not found: ${FRONTEND_DIR}"
        exit 1
    fi
    
    if [[ ! -d "${ML_DIR}" ]]; then
        log_error "ML service directory not found: ${ML_DIR}"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

login_registry() {
    if [[ "${PUSH}" == "true" ]]; then
        log_info "Logging into container registry..."
        
        if [[ "${REGISTRY}" == "ghcr.io" ]]; then
            if [[ -n "${GITHUB_TOKEN}" ]]; then
                echo "${GITHUB_TOKEN}" | docker login ghcr.io -u "${GITHUB_ACTOR:-$(whoami)}" --password-stdin
                log_success "Logged into GitHub Container Registry"
            else
                log_warning "GITHUB_TOKEN not set. Skipping registry login."
            fi
        elif [[ "${REGISTRY}" == "registry.gitlab.com" ]]; then
            if [[ -n "${CI_REGISTRY_PASSWORD}" ]]; then
                echo "${CI_REGISTRY_PASSWORD}" | docker login "${REGISTRY}" -u "${CI_REGISTRY_USER}" --password-stdin
                log_success "Logged into GitLab Container Registry"
            else
                log_warning "CI_REGISTRY_PASSWORD not set. Skipping registry login."
            fi
        else
            log_warning "Unknown registry: ${REGISTRY}. Manual login may be required."
        fi
    fi
}

build_backend() {
    log_info "Building backend image..."
    
    cd "${BACKEND_DIR}"
    
    # Build the image
    docker build \
        -t "${BACKEND_IMAGE}" \
        ${BUILD_ARGS} \
        .
    
    log_success "Backend image built: ${BACKEND_IMAGE}"
}

build_frontend() {
    log_info "Building frontend image..."
    
    # Use custom Dockerfile if available, otherwise use standard build
    if [[ -f "${DOCKER_DIR}/Dockerfile.frontend" ]]; then
        docker build \
            -f "${DOCKER_DIR}/Dockerfile.frontend" \
            -t "${FRONTEND_IMAGE}" \
            --build-arg VITE_API_URL="${VITE_API_URL:-https://api.ghibli-food.example.com}" \
            --build-arg VITE_ML_API_URL="${VITE_ML_API_URL:-https://ml.ghibli-food.example.com}" \
            ${BUILD_ARGS} \
            "${FRONTEND_DIR}"
    else
        cd "${FRONTEND_DIR}"
        docker build \
            -t "${FRONTEND_IMAGE}" \
            ${BUILD_ARGS} \
            .
    fi
    
    log_success "Frontend image built: ${FRONTEND_IMAGE}"
}

build_ml_service() {
    log_info "Building ML service image..."
    
    cd "${ML_DIR}"
    
    # Build the image
    docker build \
        -t "${ML_IMAGE}" \
        ${BUILD_ARGS} \
        .
    
    log_success "ML service image built: ${ML_IMAGE}"
}

push_images() {
    if [[ "${PUSH}" == "true" ]]; then
        log_info "Pushing images to registry..."
        
        # Push backend
        log_info "Pushing backend image..."
        docker push "${BACKEND_IMAGE}"
        
        # Push frontend
        log_info "Pushing frontend image..."
        docker push "${FRONTEND_IMAGE}"
        
        # Push ML service
        log_info "Pushing ML service image..."
        docker push "${ML_IMAGE}"
        
        log_success "All images pushed successfully"
    else
        log_info "Skipping image push (PUSH=false)"
    fi
}

tag_images() {
    local additional_tag="${1}"
    
    if [[ -n "${additional_tag}" ]]; then
        log_info "Tagging images with additional tag: ${additional_tag}"
        
        # Tag backend
        docker tag "${BACKEND_IMAGE}" "${REGISTRY}/${NAMESPACE}/backend:${additional_tag}"
        
        # Tag frontend
        docker tag "${FRONTEND_IMAGE}" "${REGISTRY}/${NAMESPACE}/frontend:${additional_tag}"
        
        # Tag ML service
        docker tag "${ML_IMAGE}" "${REGISTRY}/${NAMESPACE}/ml-service:${additional_tag}"
        
        log_success "Images tagged with: ${additional_tag}"
        
        # Push additional tags if push is enabled
        if [[ "${PUSH}" == "true" ]]; then
            log_info "Pushing additional tags..."
            docker push "${REGISTRY}/${NAMESPACE}/backend:${additional_tag}"
            docker push "${REGISTRY}/${NAMESPACE}/frontend:${additional_tag}"
            docker push "${REGISTRY}/${NAMESPACE}/ml-service:${additional_tag}"
            log_success "Additional tags pushed"
        fi
    fi
}

scan_images() {
    log_info "Scanning images for vulnerabilities..."
    
    # Check if trivy is available
    if command -v trivy &> /dev/null; then
        # Scan backend
        log_info "Scanning backend image..."
        trivy image --exit-code 0 --severity HIGH,CRITICAL "${BACKEND_IMAGE}" || log_warning "Backend image has vulnerabilities"
        
        # Scan frontend
        log_info "Scanning frontend image..."
        trivy image --exit-code 0 --severity HIGH,CRITICAL "${FRONTEND_IMAGE}" || log_warning "Frontend image has vulnerabilities"
        
        # Scan ML service
        log_info "Scanning ML service image..."
        trivy image --exit-code 0 --severity HIGH,CRITICAL "${ML_IMAGE}" || log_warning "ML service image has vulnerabilities"
        
        log_success "Vulnerability scanning completed"
    else
        log_warning "Trivy not found. Skipping vulnerability scanning."
        log_info "Install trivy for vulnerability scanning: https://trivy.dev/"
    fi
}

cleanup_build_cache() {
    log_info "Cleaning up Docker build cache..."
    
    # Remove dangling images
    docker image prune -f
    
    # Remove build cache (optional)
    if [[ "${CLEANUP_CACHE:-false}" == "true" ]]; then
        docker builder prune -f
        log_info "Build cache cleaned"
    fi
    
    log_success "Cleanup completed"
}

show_image_info() {
    log_info "Built Images:"
    echo "================================"
    
    # Show image sizes
    docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" \
        | grep -E "(${NAMESPACE}/backend|${NAMESPACE}/frontend|${NAMESPACE}/ml-service)" \
        || log_warning "No images found matching the namespace"
    
    echo ""
    log_info "Image Details:"
    echo "Backend:    ${BACKEND_IMAGE}"
    echo "Frontend:   ${FRONTEND_IMAGE}"
    echo "ML Service: ${ML_IMAGE}"
    echo ""
}

build_compose_images() {
    log_info "Building images using Docker Compose..."
    
    cd "${SCRIPT_DIR}/../docker"
    
    # Build all images with Docker Compose
    docker-compose build
    
    # Tag images with proper names
    docker tag ghibli-food-devops_backend:latest "${BACKEND_IMAGE}"
    docker tag ghibli-food-devops_frontend:latest "${FRONTEND_IMAGE}"
    docker tag ghibli-food-devops_ml-service:latest "${ML_IMAGE}"
    
    log_success "Docker Compose build completed"
}

main() {
    log_info "Starting Docker image build process..."
    log_info "Registry: ${REGISTRY}"
    log_info "Namespace: ${NAMESPACE}"
    log_info "Tag: ${TAG}"
    log_info "Push: ${PUSH}"
    
    # Parse command line arguments
    local command="${1:-build}"
    local service="${2:-all}"
    
    case "${command}" in
        "build")
            check_prerequisites
            login_registry
            
            case "${service}" in
                "backend")
                    build_backend
                    ;;
                "frontend")
                    build_frontend
                    ;;
                "ml-service")
                    build_ml_service
                    ;;
                "all")
                    build_backend
                    build_frontend
                    build_ml_service
                    ;;
                *)
                    log_error "Unknown service: ${service}"
                    exit 1
                    ;;
            esac
            
            push_images
            show_image_info
            cleanup_build_cache
            log_success "Build process completed successfully!"
            ;;
        "compose")
            check_prerequisites
            login_registry
            build_compose_images
            push_images
            show_image_info
            cleanup_build_cache
            ;;
        "scan")
            scan_images
            ;;
        "tag")
            tag_images "${service}"
            ;;
        "push")
            push_images
            ;;
        "info")
            show_image_info
            ;;
        *)
            echo "Usage: $0 [command] [service|tag]"
            echo ""
            echo "Commands:"
            echo "  build [service]  - Build Docker images (default)"
            echo "  compose          - Build using Docker Compose"
            echo "  scan             - Scan images for vulnerabilities"
            echo "  tag [tag]        - Add additional tag to images"
            echo "  push             - Push images to registry"
            echo "  info             - Show built image information"
            echo ""
            echo "Services:"
            echo "  all         - Build all services (default)"
            echo "  backend     - Build backend service only"
            echo "  frontend    - Build frontend service only"
            echo "  ml-service  - Build ML service only"
            echo ""
            echo "Environment Variables:"
            echo "  REGISTRY         - Container registry (default: ghcr.io)"
            echo "  NAMESPACE        - Registry namespace (default: yourusername/ghibli-food)"
            echo "  TAG              - Image tag (default: latest)"
            echo "  PUSH             - Push images after build (default: false)"
            echo "  GITHUB_TOKEN     - GitHub token for GHCR authentication"
            echo "  VITE_API_URL     - Frontend API URL"
            echo "  VITE_ML_API_URL  - Frontend ML API URL"
            echo ""
            echo "Examples:"
            echo "  $0 build all"
            echo "  PUSH=true TAG=v1.0.0 $0 build"
            echo "  $0 scan"
            echo "  $0 tag v1.0.1"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"