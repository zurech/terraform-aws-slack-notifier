output "lambda_arn" {
  description = "The Amazon Resource Name (ARN) identifying your Lambda Function."
  value       = aws_lambda_function.slack_notifier.arn
}

output "lambda_name" {
  description = "Lambda Function unique name."
  value       = aws_lambda_function.slack_notifier.function_name
}

output "lambda_log_group_arn" {
  description = "The Amazon Resource Name (ARN) specifying the log group."
  value       = aws_cloudwatch_log_group.lambda.arn
}
