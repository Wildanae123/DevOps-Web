#!/bin/bash

# Ghibli Food Infrastructure Setup Script
# This script sets up the infrastructure using Terraform

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-production}
TERRAFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../terraform"
AWS_REGION=${AWS_REGION:-us-west-2}

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
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Please run 'aws configure'."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

setup_terraform_backend() {
    log_info "Setting up Terraform backend..."
    
    # Create S3 bucket for Terraform state
    local bucket_name="ghibli-food-terraform-state-$(date +%s)"
    
    if ! aws s3 ls "s3://ghibli-food-terraform-state" 2>/dev/null; then
        log_info "Creating S3 bucket for Terraform state..."
        aws s3api create-bucket \
            --bucket ghibli-food-terraform-state \
            --region ${AWS_REGION} \
            --create-bucket-configuration LocationConstraint=${AWS_REGION} 2>/dev/null || \
        aws s3api create-bucket \
            --bucket ghibli-food-terraform-state \
            --region us-east-1 2>/dev/null
        
        # Enable versioning
        aws s3api put-bucket-versioning \
            --bucket ghibli-food-terraform-state \
            --versioning-configuration Status=Enabled
        
        # Enable encryption
        aws s3api put-bucket-encryption \
            --bucket ghibli-food-terraform-state \
            --server-side-encryption-configuration '{
                "Rules": [
                    {
                        "ApplyServerSideEncryptionByDefault": {
                            "SSEAlgorithm": "AES256"
                        }
                    }
                ]
            }'
        
        log_success "Terraform state S3 bucket created"
    else
        log_info "Terraform state S3 bucket already exists"
    fi
    
    # Create DynamoDB table for state locking
    if ! aws dynamodb describe-table --table-name ghibli-food-terraform-locks --region ${AWS_REGION} &>/dev/null; then
        log_info "Creating DynamoDB table for state locking..."
        aws dynamodb create-table \
            --table-name ghibli-food-terraform-locks \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
            --region ${AWS_REGION}
        
        # Wait for table to be created
        aws dynamodb wait table-exists --table-name ghibli-food-terraform-locks --region ${AWS_REGION}
        log_success "DynamoDB table for state locking created"
    else
        log_info "DynamoDB table for state locking already exists"
    fi
}

init_terraform() {
    log_info "Initializing Terraform..."
    
    cd "${TERRAFORM_DIR}"
    
    # Initialize Terraform
    terraform init
    
    log_success "Terraform initialized"
}

validate_terraform() {
    log_info "Validating Terraform configuration..."
    
    cd "${TERRAFORM_DIR}"
    
    # Validate configuration
    terraform validate
    
    # Format configuration
    terraform fmt -recursive
    
    log_success "Terraform configuration validated"
}

plan_infrastructure() {
    log_info "Planning infrastructure changes..."
    
    cd "${TERRAFORM_DIR}"
    
    # Create terraform.tfvars if it doesn't exist
    if [[ ! -f "terraform.tfvars" ]]; then
        log_info "Creating terraform.tfvars file..."
        cat > terraform.tfvars <<EOF
# AWS Configuration
aws_region = "${AWS_REGION}"
environment = "${ENVIRONMENT}"

# Database Configuration
db_password = "$(openssl rand -base64 32)"

# Domain Configuration (update with your domain)
domain_name = "ghibli-food.example.com"

# Additional tags
additional_tags = {
  Owner = "$(whoami)"
  CreatedBy = "terraform"
  Environment = "${ENVIRONMENT}"
}
EOF
        log_warning "terraform.tfvars created with default values. Please review and update as needed."
    fi
    
    # Plan changes
    terraform plan -out=tfplan
    
    log_success "Infrastructure plan created"
}

apply_infrastructure() {
    log_info "Applying infrastructure changes..."
    
    cd "${TERRAFORM_DIR}"
    
    # Apply changes
    terraform apply tfplan
    
    log_success "Infrastructure applied successfully"
}

setup_kubeconfig() {
    log_info "Setting up kubectl configuration..."
    
    cd "${TERRAFORM_DIR}"
    
    # Get cluster name from Terraform output
    local cluster_name=$(terraform output -raw eks_cluster_id)
    
    if [[ -n "${cluster_name}" ]]; then
        # Update kubeconfig
        aws eks update-kubeconfig --region ${AWS_REGION} --name ${cluster_name}
        
        # Test cluster connection
        if kubectl cluster-info &>/dev/null; then
            log_success "kubectl configured successfully"
        else
            log_error "Failed to connect to EKS cluster"
            exit 1
        fi
    else
        log_error "Could not get cluster name from Terraform output"
        exit 1
    fi
}

install_cluster_components() {
    log_info "Installing cluster components..."
    
    # Install AWS Load Balancer Controller
    log_info "Installing AWS Load Balancer Controller..."
    
    # Create service account
    kubectl create serviceaccount aws-load-balancer-controller -n kube-system --dry-run=client -o yaml | kubectl apply -f -
    
    # Annotate service account with IAM role
    local alb_role_arn=$(cd "${TERRAFORM_DIR}" && terraform output -raw aws_load_balancer_controller_role_arn)
    kubectl annotate serviceaccount aws-load-balancer-controller \
        -n kube-system \
        eks.amazonaws.com/role-arn=${alb_role_arn} \
        --overwrite
    
    # Install AWS Load Balancer Controller using Helm
    if command -v helm &> /dev/null; then
        helm repo add eks https://aws.github.io/eks-charts
        helm repo update
        helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
            -n kube-system \
            --set clusterName=$(cd "${TERRAFORM_DIR}" && terraform output -raw eks_cluster_id) \
            --set serviceAccount.create=false \
            --set serviceAccount.name=aws-load-balancer-controller
    else
        log_warning "Helm not found. Please install AWS Load Balancer Controller manually."
    fi
    
    # Install metrics-server if not present
    if ! kubectl get deployment metrics-server -n kube-system &>/dev/null; then
        log_info "Installing metrics-server..."
        kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    fi
    
    log_success "Cluster components installed"
}

show_infrastructure_info() {
    log_info "Infrastructure Information:"
    echo "================================"
    
    cd "${TERRAFORM_DIR}"
    
    echo "VPC ID: $(terraform output -raw vpc_id)"
    echo "EKS Cluster: $(terraform output -raw eks_cluster_id)"
    echo "RDS Endpoint: $(terraform output -raw rds_instance_endpoint)"
    echo "Region: $(terraform output -raw region)"
    echo ""
    
    log_info "Next steps:"
    echo "1. Update your DNS to point to the load balancer"
    echo "2. Deploy the application using: ./scripts/deploy.sh"
    echo "3. Configure monitoring and alerting"
    echo ""
}

destroy_infrastructure() {
    log_warning "This will destroy ALL infrastructure resources!"
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirm
    
    if [[ "${confirm}" == "yes" ]]; then
        log_info "Destroying infrastructure..."
        
        cd "${TERRAFORM_DIR}"
        terraform destroy -auto-approve
        
        log_success "Infrastructure destroyed"
    else
        log_info "Destruction cancelled"
    fi
}

backup_state() {
    log_info "Backing up Terraform state..."
    
    cd "${TERRAFORM_DIR}"
    
    # Create backup directory
    local backup_dir="backups/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "${backup_dir}"
    
    # Backup state file
    if [[ -f "terraform.tfstate" ]]; then
        cp terraform.tfstate "${backup_dir}/"
        log_success "Local state backed up to ${backup_dir}"
    fi
    
    # Download and backup remote state
    terraform state pull > "${backup_dir}/terraform.tfstate.backup"
    log_success "Remote state backed up to ${backup_dir}"
}

main() {
    log_info "Starting Ghibli Food infrastructure setup..."
    log_info "Environment: ${ENVIRONMENT}"
    log_info "AWS Region: ${AWS_REGION}"
    
    # Parse command line arguments
    local command="${2:-deploy}"
    
    case "${command}" in
        "init")
            check_prerequisites
            setup_terraform_backend
            init_terraform
            validate_terraform
            ;;
        "plan")
            check_prerequisites
            plan_infrastructure
            ;;
        "deploy")
            check_prerequisites
            setup_terraform_backend
            init_terraform
            validate_terraform
            plan_infrastructure
            apply_infrastructure
            setup_kubeconfig
            install_cluster_components
            show_infrastructure_info
            log_success "Infrastructure setup completed successfully!"
            ;;
        "destroy")
            destroy_infrastructure
            ;;
        "backup")
            backup_state
            ;;
        "info")
            show_infrastructure_info
            ;;
        *)
            echo "Usage: $0 [environment] [command]"
            echo ""
            echo "Commands:"
            echo "  init     - Initialize Terraform and backend"
            echo "  plan     - Plan infrastructure changes"
            echo "  deploy   - Deploy infrastructure (default)"
            echo "  destroy  - Destroy infrastructure"
            echo "  backup   - Backup Terraform state"
            echo "  info     - Show infrastructure information"
            echo ""
            echo "Environment Variables:"
            echo "  AWS_REGION - AWS region (default: us-west-2)"
            echo ""
            echo "Examples:"
            echo "  $0 production deploy"
            echo "  $0 staging plan"
            echo "  AWS_REGION=us-east-1 $0 production deploy"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"