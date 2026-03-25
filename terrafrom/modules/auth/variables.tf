variable "project_name" {
  type        = string
  description = "Project name prefix for Cognito resources"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/prod/stage)"
}
