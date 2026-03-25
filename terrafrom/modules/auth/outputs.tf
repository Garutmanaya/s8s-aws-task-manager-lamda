output "user_pool_id" {
  value       = aws_cognito_user_pool.users.id
  description = "Cognito User Pool ID for application users."
}

output "user_pool_client_id" {
  value       = aws_cognito_user_pool_client.app.id
  description = "Cognito app client ID used by the frontend."
}

output "user_pool_arn" {
  value       = aws_cognito_user_pool.users.arn
  description = "Cognito User Pool ARN used by API Gateway authorizers."
}
