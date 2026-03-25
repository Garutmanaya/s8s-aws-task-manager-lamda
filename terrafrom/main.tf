# Root Terraform configuration for the serverless task manager stack.
# This file wires the modules together, while variables and outputs live
# in dedicated files to keep the root module easier to navigate.
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.5"
    }
  }
}

# Configure the AWS provider once for the entire stack.
provider "aws" {
  region = var.aws_region
}

# Provision the DynamoDB table that stores tasks per user.
module "database" {
  source       = "./modules/database"
  project_name = var.project_name
  environment  = var.environment
}

# Provision Cognito resources used by the browser app and API authorizer.
module "auth" {
  source       = "./modules/auth"
  project_name = var.project_name
  environment  = var.environment
}

# Provision the Lambda-backed API with Cognito-protected routes.
module "tasks_api" {
  source            = "./modules/tasks_api"
  project_name      = var.project_name
  environment       = var.environment
  tasks_table_name  = module.database.tasks_table_name
  tasks_table_arn   = module.database.tasks_table_arn
  user_pool_arn     = module.auth.user_pool_arn
  lambda_source_dir = "${path.root}/../lamda"
}

# Provision the static frontend and inject runtime configuration values.
module "frontend" {
  source               = "./modules/frontend"
  project_name         = var.project_name
  environment          = var.environment
  bucket_name          = var.frontend_bucket
  api_url              = module.tasks_api.api_url
  cognito_user_pool_id = module.auth.user_pool_id
  cognito_client_id    = module.auth.user_pool_client_id
}
