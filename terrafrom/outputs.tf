output "api_gateway_url" {
  value       = module.tasks_api.api_url
  description = "Invoke URL for the deployed Tasks API stage."
}

output "frontend_url" {
  value       = module.frontend.cloudfront_url
  description = "CloudFront URL that serves the frontend application."
}

output "cognito_user_pool_id" {
  value       = module.auth.user_pool_id
  description = "Cognito User Pool ID used for authentication."
}

output "cognito_user_pool_client_id" {
  value       = module.auth.user_pool_client_id
  description = "Cognito App Client ID used by the frontend."
}

output "dynamodb_table_name" {
  value       = module.database.tasks_table_name
  description = "Name of the DynamoDB table that stores tasks."
}
