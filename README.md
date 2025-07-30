# Terraform + Helm + ArgoCD Deployment Project

This project demonstrates a complete GitOps workflow using Terraform for infrastructure provisioning, Helm charts for application packaging, and ArgoCD for continuous deployment.

## Project Structure

```
.
├── terraform/                 # Terraform infrastructure code
│   ├── modules/
│   │   ├── kubernetes/       # Kubernetes cluster setup
│   │   └── argocd/          # ArgoCD installation
│   ├── environments/
│   │   └── dev/             # Development environment
│   └── scripts/             # Terraform helper scripts
├── helm-charts/              # Helm charts for applications
│   ├── backend/             # Statefulset backend application
│   ├── frontend/            # Frontend application
│   └── cronjobs/            # Cron jobs configuration
├── argocd/                   # ArgoCD application manifests
│   ├── applications/        # Application definitions
│   └── projects/           # ArgoCD project definitions
├── scripts/                  # Utility scripts
└── docs/                    # Documentation
```

## Prerequisites

- Terraform >= 1.0
- Helm >= 3.0
- kubectl
- Docker
- A Kubernetes cluster (EKS, GKE, AKS, or local like minikube)

## Quick Start

1. **Initialize Terraform:**
   ```bash
   cd terraform/environments/dev
   terraform init
   terraform plan
   terraform apply
   ```

2. **Deploy ArgoCD Applications:**
   ```bash
   kubectl apply -f argocd/applications/
   ```

3. **Access ArgoCD UI:**
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
   Then visit: https://localhost:8080

## Components

### Backend (StatefulSet)
- PostgreSQL database with persistent storage
- Redis cache for session management
- Application server with horizontal pod autoscaling

### Cron Jobs
- Database backup jobs
- Log rotation and cleanup
- Health check monitoring
- Data synchronization tasks

### Frontend
- Web application with ingress configuration
- Load balancer setup
- SSL/TLS termination

## Features

- ✅ Infrastructure as Code with Terraform
- ✅ Application packaging with Helm
- ✅ GitOps deployment with ArgoCD
- ✅ Stateful backend with persistent storage
- ✅ Automated cron jobs
- ✅ Multi-environment support
- ✅ Monitoring and logging
- ✅ Security best practices

## Environment Variables

Create a `terraform.tfvars` file in `terraform/environments/dev/`:

```hcl
project_name = "my-project"
environment  = "dev"
domain_name  = "example.com"
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `terraform plan`
5. Submit a pull request

## License

MIT License 