output "admin_password" {
  description = "ArgoCD admin password"
  value       = "admin123" # This should be retrieved from the secret in production
  sensitive   = true
}

output "server_url" {
  description = "ArgoCD server URL"
  value       = "https://argocd.${var.domain_name}"
}

output "namespace" {
  description = "ArgoCD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
} 