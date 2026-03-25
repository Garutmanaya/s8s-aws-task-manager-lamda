output "api_url" {
  value       = "https://${aws_api_gateway_rest_api.tasks_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_stage.tasks_api.stage_name}"
  description = "Invoke URL for the deployed API Gateway stage."
}

output "lambda_function_name" {
  value       = aws_lambda_function.tasks.function_name
  description = "Name of the router Lambda that backs the tasks API."
}
