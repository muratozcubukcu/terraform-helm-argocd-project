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

# Create namespace for the application
resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
      "argocd.argoproj.io/managed-by" = "argocd"
    }
  }
}

# Deploy PostgreSQL using Bitnami Helm chart
resource "helm_release" "postgresql" {
  name       = "postgresql"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = "12.12.10"
  namespace  = kubernetes_namespace.app_namespace.metadata[0].name

  values = [
    file("${path.module}/values/postgresql-values.yaml")
  ]

  depends_on = [kubernetes_namespace.app_namespace]
}

# Deploy application using local Helm chart
resource "helm_release" "app" {
  name      = var.app_name
  chart     = "${path.module}/../helm-chart"
  namespace = kubernetes_namespace.app_namespace.metadata[0].name

  values = [
    file("${path.module}/values/app-values.yaml")
  ]

  depends_on = [
    kubernetes_namespace.app_namespace,
    helm_release.postgresql
  ]
}

# Create secret for PostgreSQL connection
resource "kubernetes_secret" "db_secret" {
  metadata {
    name      = "${var.app_name}-db-secret"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  data = {
    POSTGRES_HOST     = "postgresql.${kubernetes_namespace.app_namespace.metadata[0].name}.svc.cluster.local"
    POSTGRES_PORT     = "5432"
    POSTGRES_DB       = var.postgres_database
    POSTGRES_USER     = var.postgres_user
    POSTGRES_PASSWORD = var.postgres_password
  }

  type = "Opaque"
}