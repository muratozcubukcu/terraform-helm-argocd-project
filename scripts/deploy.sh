#!/bin/bash

# Terraform + Helm + ArgoCD Deployment Script
# This script automates the deployment of the entire infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    command -v terraform >/dev/null 2>&1 || { print_error "Terraform is required but not installed. Aborting."; exit 1; }
    command -v helm >/dev/null 2>&1 || { print_error "Helm is required but not installed. Aborting."; exit 1; }
    command -v kubectl >/dev/null 2>&1 || { print_error "kubectl is required but not installed. Aborting."; exit 1; }
    
    print_success "All prerequisites are installed"
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    cd terraform/environments/dev
    
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Creating from example..."
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit terraform.tfvars with your configuration before continuing"
        exit 1
    fi
    
    terraform init
    print_success "Terraform initialized"
}

# Plan Terraform changes
plan_terraform() {
    print_status "Planning Terraform changes..."
    terraform plan -out=tfplan
    print_success "Terraform plan created"
}

# Apply Terraform changes
apply_terraform() {
    print_status "Applying Terraform changes..."
    terraform apply tfplan
    print_success "Terraform changes applied"
}

# Wait for ArgoCD to be ready
wait_for_argocd() {
    print_status "Waiting for ArgoCD to be ready..."
    
    # Wait for ArgoCD namespace
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
    
    print_success "ArgoCD is ready"
}

# Get ArgoCD admin password
get_argocd_password() {
    print_status "Getting ArgoCD admin password..."
    
    # Wait a bit for the secret to be created
    sleep 10
    
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    if [ -z "$ARGOCD_PASSWORD" ]; then
        print_warning "Could not retrieve ArgoCD password. You may need to get it manually:"
        echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d"
    else
        print_success "ArgoCD admin password: $ARGOCD_PASSWORD"
    fi
}

# Deploy ArgoCD applications
deploy_argocd_apps() {
    print_status "Deploying ArgoCD applications..."
    
    # Apply ArgoCD project
    kubectl apply -f ../../argocd/projects/default.yaml
    
    # Apply ArgoCD applications
    kubectl apply -f ../../argocd/applications/
    
    print_success "ArgoCD applications deployed"
}

# Show deployment status
show_status() {
    print_status "Deployment Status:"
    echo ""
    
    echo "Kubernetes Resources:"
    kubectl get all -n my-project-dev
    echo ""
    
    echo "ArgoCD Applications:"
    kubectl get applications -n argocd
    echo ""
    
    echo "ArgoCD Server URL:"
    echo "https://argocd.example.com (or kubectl port-forward svc/argocd-server -n argocd 8080:443)"
    echo ""
    
    echo "To access ArgoCD UI:"
    echo "1. kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "2. Open https://localhost:8080"
    echo "3. Username: admin"
    echo "4. Password: (see above or run: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
}

# Main deployment function
main() {
    print_status "Starting deployment..."
    
    check_prerequisites
    init_terraform
    plan_terraform
    
    read -p "Do you want to apply these changes? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        apply_terraform
        wait_for_argocd
        get_argocd_password
        deploy_argocd_apps
        show_status
        print_success "Deployment completed successfully!"
    else
        print_warning "Deployment cancelled"
        exit 0
    fi
}

# Handle script arguments
case "${1:-}" in
    "init")
        check_prerequisites
        init_terraform
        ;;
    "plan")
        init_terraform
        plan_terraform
        ;;
    "apply")
        init_terraform
        plan_terraform
        apply_terraform
        ;;
    "status")
        show_status
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  init    - Initialize Terraform"
        echo "  plan    - Plan Terraform changes"
        echo "  apply   - Apply Terraform changes"
        echo "  status  - Show deployment status"
        echo "  help    - Show this help message"
        echo ""
        echo "If no command is provided, runs the full deployment process"
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac 