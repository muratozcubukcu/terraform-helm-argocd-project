variable "namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "simple-app"
}

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "simple-app"
}

variable "postgres_database" {
  description = "PostgreSQL database name"
  type        = string
  default     = "appdb"
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "appuser"
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  default     = "apppassword"
  sensitive   = true
}

variable "app_image" {
  description = "Docker image for the application"
  type        = string
  default     = "nginx:latest"
}

variable "app_replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 2
}