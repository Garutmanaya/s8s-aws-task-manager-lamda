# This module creates the DynamoDB table that stores tasks per user.
resource "aws_dynamodb_table" "tasks" {
  name         = "${var.project_name}-${var.environment}-tasks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "taskId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "taskId"
    type = "S"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
