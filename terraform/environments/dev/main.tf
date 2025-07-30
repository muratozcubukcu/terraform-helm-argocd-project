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
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
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

provider "kubectl" {
  config_path = "~/.kube/config"
}



# Local values
locals {
  namespace = "${var.project_name}-${var.environment}"
  labels = {
    project     = var.project_name
    environment = var.environment
    managed-by  = "terraform"
  }
}

# Create namespace
resource "kubernetes_namespace" "main" {
  metadata {
    name   = local.namespace
    labels = local.labels
  }
}

# ArgoCD installation
# module "argocd" {
#   source = "../../modules/argocd"
#   
#   namespace   = "argocd"
#   labels      = local.labels
#   domain_name = var.domain_name
# }

# Storage classes for stateful applications
resource "kubernetes_storage_class" "fast_ssd" {
  metadata {
    name = "fast-ssd"
    labels = local.labels
  }
  
  storage_provisioner = "kubernetes.io/aws-ebs"  # Adjust based on your cloud provider
  volume_binding_mode = "WaitForFirstConsumer"
  
  parameters = {
    type = "gp3"
    iops = "3000"
    throughput = "125"
  }
}

resource "kubernetes_storage_class" "standard_ssd" {
  metadata {
    name = "standard-ssd"
    labels = local.labels
  }
  
  storage_provisioner = "kubernetes.io/aws-ebs"  # Adjust based on your cloud provider
  volume_binding_mode = "WaitForFirstConsumer"
  
  parameters = {
    type = "gp2"
  }
}

# Outputs
output "namespace" {
  description = "The namespace created for the application"
  value       = kubernetes_namespace.main.metadata[0].name
}

# output "argocd_admin_password" {
#   description = "ArgoCD admin password"
#   value       = module.argocd.admin_password
#   sensitive   = true
# }

# output "argocd_server_url" {
#   description = "ArgoCD server URL"
#   value       = module.argocd.server_url
# } 