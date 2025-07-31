terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Create namespace for Argo CD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      name = "argocd"
    }
  }
}

# Create namespace for applications
resource "kubernetes_namespace" "applications" {
  metadata {
    name = "applications"
    labels = {
      name = "applications"
    }
  }
}

# Add Argo CD Helm repository
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.51.6"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  set {
    name  = "server.extraArgs"
    value = "{--insecure}"
  }

  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  set {
    name  = "server.ingress.ingressClassName"
    value = "nginx"
  }

  set {
    name  = "server.ingress.hosts[0]"
    value = "argocd.local"
  }

  set {
    name  = "server.ingress.tls[0].secretName"
    value = "argocd-server-tls"
  }

  set {
    name  = "server.ingress.tls[0].hosts[0]"
    value = "argocd.local"
  }

  set {
    name  = "redis.enabled"
    value = "true"
  }

  set {
    name  = "redis.auth.enabled"
    value = "false"
  }

  depends_on = [kubernetes_namespace.argocd]
}

# Deploy PostgreSQL StatefulSet for Argo CD
resource "helm_release" "postgresql" {
  name       = "postgresql"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = "12.5.8"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  set {
    name  = "auth.postgresPassword"
    value = "argocd123"
  }

  set {
    name  = "auth.database"
    value = "argocd"
  }

  set {
    name  = "primary.persistence.size"
    value = "10Gi"
  }

  set {
    name  = "primary.persistence.storageClass"
    value = "standard"
  }

  set {
    name  = "architecture"
    value = "standalone"
  }

  set {
    name  = "primary.resources.requests.memory"
    value = "256Mi"
  }

  set {
    name  = "primary.resources.requests.cpu"
    value = "250m"
  }

  set {
    name  = "primary.resources.limits.memory"
    value = "512Mi"
  }

  set {
    name  = "primary.resources.limits.cpu"
    value = "500m"
  }

  depends_on = [kubernetes_namespace.argocd]
}

# Create Argo CD Application for sample app
resource "kubernetes_manifest" "argocd_application" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "sample-app"
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/argoproj/argocd-example-apps"
        targetRevision = "HEAD"
        path          = "guestbook"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.applications.metadata[0].name
      }
      syncPolicy = {
        automated = {
          prune      = true
          selfHeal   = true
          allowEmpty = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }

  depends_on = [helm_release.argocd]
} 