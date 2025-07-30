terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

# Variables
variable "namespace" {
  description = "Namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "version" {
  description = "ArgoCD version to install"
  type        = string
  default     = "5.51.6"
}

variable "values" {
  description = "Additional Helm values for ArgoCD"
  type        = string
  default     = ""
}

# Create ArgoCD namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name   = var.namespace
    labels = var.labels
  }
}

# Add ArgoCD Helm repository
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    yamlencode({
      server = {
        extraArgs = ["--insecure"]
        ingress = {
          enabled = true
          annotations = {
            "kubernetes.io/ingress.class" = "nginx"
            "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
          }
          hosts = ["argocd.${var.domain_name}"]
          tls = [{
            secretName = "argocd-server-tls"
            hosts      = ["argocd.${var.domain_name}"]
          }]
        }
      }
      configs = {
        secret = {
          argocdServerAdminPassword = bcrypt("admin123") # Change this in production
        }
      }
      rbac = {
        create = true
        pspEnabled = false
      }
      repoServer = {
        resources = {
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
          requests = {
            cpu    = "250m"
            memory = "256Mi"
          }
        }
      }
      applicationSet = {
        enabled = true
      }
    }),
    var.values
  ]

  depends_on = [kubernetes_namespace.argocd]
}

# Create ArgoCD project
resource "kubectl_manifest" "argocd_project" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "default"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      description = "Default ArgoCD project"
      sourceRepos = ["*"]
      destinations = [{
        namespace = "*"
        server    = "https://kubernetes.default.svc"
      }]
      clusterResourceWhitelist = [{
        group = "*"
        kind  = "*"
      }]
      namespaceResourceWhitelist = [{
        group = "*"
        kind  = "*"
      }]
    }
  })

  depends_on = [helm_release.argocd]
}

# Create ArgoCD application for backend
resource "kubectl_manifest" "backend_app" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "backend"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/your-org/your-repo"
        targetRevision = "main"
        path          = "helm-charts/backend"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "my-project-dev"
      }
      syncPolicy = {
        automated = {
          prune      = true
          selfHeal   = true
          allowEmpty = false
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  })

  depends_on = [kubectl_manifest.argocd_project]
}

# Create ArgoCD application for frontend
resource "kubectl_manifest" "frontend_app" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "frontend"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/your-org/your-repo"
        targetRevision = "main"
        path          = "helm-charts/frontend"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "my-project-dev"
      }
      syncPolicy = {
        automated = {
          prune      = true
          selfHeal   = true
          allowEmpty = false
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  })

  depends_on = [kubectl_manifest.argocd_project]
}

# Create ArgoCD application for cronjobs
resource "kubectl_manifest" "cronjobs_app" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "cronjobs"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/your-org/your-repo"
        targetRevision = "main"
        path          = "helm-charts/cronjobs"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "my-project-dev"
      }
      syncPolicy = {
        automated = {
          prune      = true
          selfHeal   = true
          allowEmpty = false
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  })

  depends_on = [kubectl_manifest.argocd_project]
} 