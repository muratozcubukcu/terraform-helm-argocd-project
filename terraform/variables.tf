variable "argocd_namespace" {
  description = "Namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "applications_namespace" {
  description = "Namespace for applications"
  type        = string
  default     = "applications"
}

variable "argocd_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "5.51.6"
}

variable "postgresql_version" {
  description = "PostgreSQL Helm chart version"
  type        = string
  default     = "12.5.8"
}

variable "postgresql_password" {
  description = "PostgreSQL password"
  type        = string
  default     = "argocd123"
  sensitive   = true
}

variable "postgresql_database" {
  description = "PostgreSQL database name"
  type        = string
  default     = "argocd"
}

variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "standard"
}

variable "postgresql_storage_size" {
  description = "PostgreSQL storage size"
  type        = string
  default     = "10Gi"
}

variable "argocd_host" {
  description = "Argo CD ingress host"
  type        = string
  default     = "argocd.local"
}

variable "ingress_class" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
} 