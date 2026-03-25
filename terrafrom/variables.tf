variable "project_name" {
  type        = string
  description = "Project name prefix used across all AWS resources."
  default     = "task-manager"
}

variable "environment" {
  type        = string
  description = "Deployment environment name, such as dev, stage, or prod."
  default     = "prod"
}

variable "aws_region" {
  type        = string
  description = "AWS region where the stack will be deployed."
  default     = "us-east-1"
}

variable "frontend_bucket" {
  type        = string
  description = "Globally unique S3 bucket name used to host the frontend."
  default     = "task-manager-frontend-123456"
}
