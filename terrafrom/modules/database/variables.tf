variable "project_name" {
  type        = string
  description = "Project name prefix used for the DynamoDB table."
}

variable "environment" {
  type        = string
  description = "Environment name used in the DynamoDB table name and tags."
}
