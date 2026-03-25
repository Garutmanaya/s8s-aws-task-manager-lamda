# This module provisions the Cognito resources used for application sign-in.
resource "aws_cognito_user_pool" "users" {
  name                     = "${var.project_name}-${var.environment}-users"
  auto_verified_attributes = ["email"]

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# This app client is used directly by the browser-based frontend.
resource "aws_cognito_user_pool_client" "app" {
  name                = "${var.project_name}-${var.environment}-client"
  user_pool_id        = aws_cognito_user_pool.users.id
  generate_secret     = false
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"]

  prevent_user_existence_errors = "ENABLED"
}
