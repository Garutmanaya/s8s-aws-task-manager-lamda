output "tasks_table_name" {
  value       = aws_dynamodb_table.tasks.name
  description = "Name of the DynamoDB table that stores tasks."
}

output "tasks_table_arn" {
  value       = aws_dynamodb_table.tasks.arn
  description = "ARN of the DynamoDB table used by the Lambda API."
}
