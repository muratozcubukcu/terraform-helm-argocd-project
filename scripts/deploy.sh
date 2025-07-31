#!/bin/bash

# Argo CD Deployment Script
# This script automates the deployment of Argo CD with PostgreSQL StatefulSet

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed"
        exit 1
    fi
    
    # Check Helm
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed"
        exit 1
    fi
    
    # Check Kubernetes cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    print_status "All prerequisites are satisfied"
}

# Deploy with Terraform
deploy_terraform() {
    print_status "Deploying with Terraform..."
    
    cd terraform
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Check if terraform.tfvars exists
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found, creating from example..."
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit terraform.tfvars with your configuration before continuing"
        read -p "Press Enter to continue after editing terraform.tfvars..."
    fi
    
    # Plan deployment
    print_status "Planning Terraform deployment..."
    terraform plan
    
    # Ask for confirmation
    read -p "Do you want to apply this configuration? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Applying Terraform configuration..."
        terraform apply -auto-approve
    else
        print_warning "Deployment cancelled"
        exit 0
    fi
    
    cd ..
}

# Deploy with Helm
deploy_helm() {
    print_status "Deploying with Helm..."
    
    cd helm/argocd
    
    # Add Argo CD repository
    print_status "Adding Argo CD Helm repository..."
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    
    # Create namespace if it doesn't exist
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    # Install the chart
    print_status "Installing Argo CD Helm chart..."
    helm install argocd-custom . -n argocd --create-namespace
    
    cd ../..
}

# Wait for deployment
wait_for_deployment() {
    print_status "Waiting for Argo CD deployment to be ready..."
    
    # Wait for PostgreSQL StatefulSet
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=database -n argocd --timeout=300s
    
    # Wait for Argo CD server
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=server -n argocd --timeout=300s
    
    # Wait for Redis
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=redis -n argocd --timeout=300s
    
    print_status "All components are ready!"
}

# Get Argo CD admin password
get_admin_password() {
    print_status "Getting Argo CD admin password..."
    
    # Wait a bit for the secret to be created
    sleep 10
    
    # Get the password
    PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "Password not available yet")
    
    if [ "$PASSWORD" != "Password not available yet" ]; then
        echo -e "${GREEN}Argo CD Admin Password:${NC} $PASSWORD"
    else
        print_warning "Admin password not available yet. You can get it later with:"
        echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
    fi
}

# Show access information
show_access_info() {
    print_status "Argo CD deployment completed!"
    echo
    echo -e "${GREEN}Access Information:${NC}"
    echo "1. Port forward to access locally:"
    echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo
    echo "2. Access URL: https://localhost:8080"
    echo "   Username: admin"
    echo "   Password: (see above or run the get password command)"
    echo
    echo "3. Get admin password:"
    echo "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
    echo
    echo "4. Check deployment status:"
    echo "   kubectl get pods -n argocd"
    echo
    echo "5. View logs:"
    echo "   kubectl logs -n argocd deployment/argocd-server"
}

# Main deployment function
main() {
    echo "=========================================="
    echo "Argo CD with PostgreSQL StatefulSet Deployment"
    echo "=========================================="
    echo
    
    # Check prerequisites
    check_prerequisites
    
    # Choose deployment method
    echo "Choose deployment method:"
    echo "1. Terraform (recommended)"
    echo "2. Helm only"
    echo "3. Both"
    read -p "Enter your choice (1-3): " choice
    
    case $choice in
        1)
            deploy_terraform
            ;;
        2)
            deploy_helm
            ;;
        3)
            deploy_terraform
            deploy_helm
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
    
    # Wait for deployment
    wait_for_deployment
    
    # Get admin password
    get_admin_password
    
    # Show access information
    show_access_info
}

# Run main function
main "$@" 