output "namespace" {
  description = "Kubernetes namespace where the application is deployed"
  value       = kubernetes_namespace.app_namespace.metadata[0].name
}

output "postgresql_service" {
  description = "PostgreSQL service name"
  value       = "${helm_release.postgresql.name}.${kubernetes_namespace.app_namespace.metadata[0].name}.svc.cluster.local"
}

output "app_name" {
  description = "Application name"
  value       = helm_release.app.name
}

output "database_secret_name" {
  description = "Name of the database connection secret"
  value       = kubernetes_secret.db_secret.metadata[0].name
}