variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "my-project"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "example.com"
}

variable "kubernetes_config_path" {
  description = "Path to Kubernetes config file"
  type        = string
  default     = "~/.kube/config"
}

variable "argocd_version" {
  description = "ArgoCD version to install"
  type        = string
  default     = "5.51.6"
}

variable "enable_monitoring" {
  description = "Enable monitoring stack (Prometheus, Grafana)"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable logging stack (ELK or similar)"
  type        = bool
  default     = true
}

variable "storage_class" {
  description = "Default storage class for persistent volumes"
  type        = string
  default     = "fast-ssd"
}

variable "node_selector" {
  description = "Node selector for pod placement"
  type        = map(string)
  default = {
    "node-role.kubernetes.io/worker" = "true"
  }
}

variable "tolerations" {
  description = "Tolerations for pod scheduling"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
} 