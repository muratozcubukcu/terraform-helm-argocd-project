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

variable "argocd_version" {
  description = "ArgoCD version to install"
  type        = string
  default     = "5.51.6"
}

variable "values" {
  description = "Additional Helm values for ArgoCD"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for ArgoCD ingress"
  type        = string
  default     = "example.com"
} 