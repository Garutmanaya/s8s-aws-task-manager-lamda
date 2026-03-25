variable "project_name" {
  type        = string
  description = "Project name prefix used for frontend infrastructure tags."
}

variable "environment" {
  type        = string
  description = "Environment name used for tagging frontend resources."
}

variable "bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name used for website hosting."
}

variable "api_url" {
  type        = string
  description = "Base API URL injected into the frontend at deploy time."
}

variable "cognito_user_pool_id" {
  type        = string
  description = "Cognito User Pool ID injected into the frontend."
}

variable "cognito_client_id" {
  type        = string
  description = "Cognito App Client ID injected into the frontend."
}
