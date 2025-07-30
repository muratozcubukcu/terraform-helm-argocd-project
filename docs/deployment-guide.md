# Deployment Guide

This guide walks you through deploying the complete infrastructure using Terraform, Helm, and ArgoCD.

## Prerequisites

Before starting, ensure you have the following tools installed:

- **Terraform** >= 1.0
- **Helm** >= 3.0
- **kubectl** (configured to access your Kubernetes cluster)
- **Docker** (for building images if needed)

### Installation Commands

#### macOS (using Homebrew)
```bash
# Install Terraform
brew install terraform

# Install Helm
brew install helm

# Install kubectl
brew install kubectl

# Install Docker Desktop
brew install --cask docker
```

#### Linux (Ubuntu/Debian)
```bash
# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Install Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) keyring=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update && sudo apt-get install helm

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

## Quick Start

### 1. Clone and Setup

```bash
# Clone your repository
git clone <your-repo-url>
cd <your-repo-name>

# Copy and edit the configuration
cp terraform/environments/dev/terraform.tfvars.example terraform/environments/dev/terraform.tfvars
```

### 2. Configure Your Environment

Edit `terraform/environments/dev/terraform.tfvars`:

```hcl
# Project Configuration
project_name = "my-awesome-app"
environment  = "dev"
domain_name  = "myapp.example.com"

# Kubernetes Configuration
kubernetes_config_path = "~/.kube/config"

# ArgoCD Configuration
argocd_version = "5.51.6"

# Feature Flags
enable_monitoring = true
enable_logging    = true

# Storage Configuration
storage_class = "fast-ssd"
```

### 3. Deploy Everything

```bash
# Run the automated deployment script
./scripts/deploy.sh
```

Or deploy step by step:

```bash
# Initialize Terraform
cd terraform/environments/dev
terraform init

# Plan the deployment
terraform plan -out=tfplan

# Apply the changes
terraform apply tfplan

# Deploy ArgoCD applications
kubectl apply -f ../../argocd/projects/default.yaml
kubectl apply -f ../../argocd/applications/
```

## Manual Deployment Steps

### Step 1: Infrastructure Setup

1. **Initialize Terraform**
   ```bash
   cd terraform/environments/dev
   terraform init
   ```

2. **Review the Plan**
   ```bash
   terraform plan
   ```

3. **Apply Infrastructure**
   ```bash
   terraform apply
   ```

### Step 2: ArgoCD Setup

1. **Wait for ArgoCD to be Ready**
   ```bash
   kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
   ```

2. **Get ArgoCD Admin Password**
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

3. **Access ArgoCD UI**
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
   Then visit: https://localhost:8080

### Step 3: Application Deployment

1. **Create ArgoCD Project**
   ```bash
   kubectl apply -f argocd/projects/default.yaml
   ```

2. **Deploy Applications**
   ```bash
   kubectl apply -f argocd/applications/
   ```

## Monitoring Your Deployment

### Check Application Status

```bash
# Check all resources in your namespace
kubectl get all -n my-project-dev

# Check ArgoCD applications
kubectl get applications -n argocd

# Check specific application status
kubectl describe application backend -n argocd
```

### View Logs

```bash
# Backend application logs
kubectl logs -f deployment/backend-app -n my-project-dev

# PostgreSQL logs
kubectl logs -f statefulset/backend-postgresql -n my-project-dev

# Redis logs
kubectl logs -f statefulset/backend-redis -n my-project-dev

# Cron job logs
kubectl logs -f job/cronjobs-db-backup-<timestamp> -n my-project-dev
```

### Monitor Cron Jobs

```bash
# List all cron jobs
kubectl get cronjobs -n my-project-dev

# Check cron job status
kubectl describe cronjob cronjobs-db-backup -n my-project-dev

# View cron job history
kubectl get jobs -n my-project-dev
```

## Troubleshooting

### Common Issues

1. **ArgoCD Application Stuck in Progress**
   ```bash
   # Check application events
   kubectl describe application backend -n argocd
   
   # Check pod status
   kubectl get pods -n my-project-dev
   ```

2. **Storage Issues**
   ```bash
   # Check PVC status
   kubectl get pvc -n my-project-dev
   
   # Check storage classes
   kubectl get storageclass
   ```

3. **Network Issues**
   ```bash
   # Check services
   kubectl get svc -n my-project-dev
   
   # Check ingress
   kubectl get ingress -n my-project-dev
   ```

### Debug Commands

```bash
# Get detailed information about a resource
kubectl describe <resource-type> <resource-name> -n my-project-dev

# Check events in namespace
kubectl get events -n my-project-dev --sort-by='.lastTimestamp'

# Check ArgoCD server logs
kubectl logs -f deployment/argocd-server -n argocd
```

## Cleanup

### Remove Applications

```bash
# Delete ArgoCD applications
kubectl delete -f argocd/applications/

# Delete ArgoCD project
kubectl delete -f argocd/projects/default.yaml
```

### Destroy Infrastructure

```bash
cd terraform/environments/dev
terraform destroy
```

## Security Considerations

1. **Change Default Passwords**
   - Update PostgreSQL passwords in `helm-charts/backend/values.yaml`
   - Update Redis passwords in `helm-charts/backend/values.yaml`
   - Change ArgoCD admin password

2. **Network Security**
   - Configure network policies
   - Use proper ingress annotations
   - Enable TLS/SSL

3. **RBAC**
   - Review and customize service accounts
   - Implement least privilege access

4. **Secrets Management**
   - Use external secret management (HashiCorp Vault, AWS Secrets Manager, etc.)
   - Rotate secrets regularly

## Production Considerations

1. **High Availability**
   - Deploy multiple replicas
   - Use pod anti-affinity
   - Configure proper resource limits

2. **Monitoring**
   - Set up Prometheus and Grafana
   - Configure alerting
   - Monitor resource usage

3. **Backup Strategy**
   - Regular database backups
   - Backup ArgoCD configuration
   - Test restore procedures

4. **Scaling**
   - Configure HPA (Horizontal Pod Autoscaler)
   - Monitor performance metrics
   - Plan for capacity growth 