output "argocd_namespace" {
  description = "Argo CD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "applications_namespace" {
  description = "Applications namespace"
  value       = kubernetes_namespace.applications.metadata[0].name
}

output "argocd_server_url" {
  description = "Argo CD server URL"
  value       = "https://${var.argocd_host}"
}

output "postgresql_service_name" {
  description = "PostgreSQL service name"
  value       = "postgresql.${var.argocd_namespace}.svc.cluster.local"
}

output "postgresql_port" {
  description = "PostgreSQL port"
  value       = "5432"
}

output "get_argocd_admin_password" {
  description = "Command to get Argo CD admin password"
  value       = "kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
}

output "port_forward_argocd" {
  description = "Command to port forward Argo CD server"
  value       = "kubectl port-forward svc/argocd-server -n ${var.argocd_namespace} 8080:443"
} 