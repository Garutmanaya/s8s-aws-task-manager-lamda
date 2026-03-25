variable "project_name" {
  type        = string
  description = "Project name prefix used for API and Lambda resources."
}

variable "environment" {
  type        = string
  description = "Environment name used in resource names and API stage naming."
}

variable "tasks_table_name" {
  type        = string
  description = "DynamoDB table name exposed to the Lambda function."
}

variable "tasks_table_arn" {
  type        = string
  description = "DynamoDB table ARN used to scope the Lambda IAM policy."
}

variable "user_pool_arn" {
  type        = string
  description = "Cognito User Pool ARN used by API Gateway for authorization."
}

variable "lambda_source_dir" {
  type        = string
  description = "Path to the directory containing the Python Lambda source files."
}
