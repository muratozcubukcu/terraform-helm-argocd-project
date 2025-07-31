# Argo CD with PostgreSQL StatefulSet

This repository contains Terraform and Helm scripts to deploy Argo CD with a PostgreSQL StatefulSet database for production-ready GitOps workflows.

## Architecture

The deployment includes:
- **Argo CD Server**: Web UI and API server
- **PostgreSQL StatefulSet**: Persistent database for Argo CD metadata
- **Redis**: Caching layer for improved performance
- **Ingress**: External access to Argo CD UI
- **RBAC**: Proper permissions and service accounts

## Prerequisites

- Kubernetes cluster (1.20+)
- kubectl configured
- Terraform (>= 1.0)
- Helm (>= 3.0)
- Ingress controller (nginx-ingress recommended)
- Storage class for persistent volumes

## Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd Proj
```

### 2. Configure Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Deploy with Terraform

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 4. Access Argo CD

After deployment, you can access Argo CD:

```bash
# Get the admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access locally
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then visit: https://localhost:8080
- Username: `admin`
- Password: (from the command above)

## Helm Deployment

Alternatively, you can deploy using Helm directly:

```bash
cd helm/argocd

# Add the Argo CD repository
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install the custom chart
helm install argocd-custom . -n argocd --create-namespace
```

## Configuration

### Terraform Variables

Key variables you can customize in `terraform.tfvars`:

- `argocd_namespace`: Namespace for Argo CD (default: "argocd")
- `postgresql_password`: Database password
- `postgresql_storage_size`: Storage size for PostgreSQL (default: "10Gi")
- `argocd_host`: Ingress hostname
- `storage_class`: Kubernetes storage class

### Helm Values

Customize the Helm deployment in `helm/argocd/values.yaml`:

- Resource limits and requests
- Ingress configuration
- PostgreSQL settings
- Redis configuration
- Security contexts

## Components

### PostgreSQL StatefulSet

- **Persistent Storage**: Uses PVC with configurable storage class
- **High Availability**: Single instance for simplicity (can be scaled)
- **Security**: Runs as non-root user with proper security context
- **Monitoring**: Includes Prometheus annotations

### Argo CD Server

- **Web UI**: Accessible via ingress
- **API Server**: REST API for automation
- **Database Integration**: Connected to PostgreSQL StatefulSet
- **Caching**: Redis for improved performance

### Redis

- **Caching**: Improves Argo CD performance
- **Persistence**: AOF enabled for data durability
- **Security**: No authentication (internal network only)

## Monitoring and Logging

### Health Checks

All components include:
- Liveness probes
- Readiness probes
- Resource limits and requests

### Logs

```bash
# Argo CD server logs
kubectl logs -n argocd deployment/argocd-server

# PostgreSQL logs
kubectl logs -n argocd statefulset/argocd-custom-postgresql

# Redis logs
kubectl logs -n argocd deployment/argocd-custom-redis
```

## Troubleshooting

### Common Issues

1. **PostgreSQL Connection Issues**
   ```bash
   kubectl exec -it -n argocd statefulset/argocd-custom-postgresql -- psql -U argocd -d argocd
   ```

2. **Storage Issues**
   ```bash
   kubectl get pvc -n argocd
   kubectl describe pvc -n argocd
   ```

3. **Ingress Issues**
   ```bash
   kubectl get ingress -n argocd
   kubectl describe ingress -n argocd
   ```

### Database Migration

If you need to migrate from the default SQLite to PostgreSQL:

1. Backup existing data
2. Update Argo CD configuration
3. Restart Argo CD components

## Security Considerations

- Change default passwords
- Use TLS certificates for ingress
- Configure network policies
- Enable audit logging
- Use dedicated service accounts

## Scaling

### Horizontal Scaling

```bash
# Scale Argo CD server
kubectl scale deployment argocd-server -n argocd --replicas=3

# Scale PostgreSQL (requires proper clustering setup)
kubectl scale statefulset argocd-custom-postgresql -n argocd --replicas=3
```

### Vertical Scaling

Update resource limits in `values.yaml`:

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

## Backup and Recovery

### PostgreSQL Backup

```bash
# Create backup
kubectl exec -it -n argocd statefulset/argocd-custom-postgresql -- pg_dump -U argocd argocd > backup.sql

# Restore backup
kubectl exec -i -n argocd statefulset/argocd-custom-postgresql -- psql -U argocd argocd < backup.sql
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 