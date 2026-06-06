output "api_gateway_url" {
  description = "Base URL for the API Gateway. Set this as BACKEND_API_URL in Config.xcconfig."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "spotify_secret_name" {
  description = "Name of the Secrets Manager secret that must be populated before Lambda will function."
  value       = aws_secretsmanager_secret.spotify_credentials.name
}

output "secret_population_command" {
  description = "Run this command after apply to populate Spotify credentials. Lambda will fail until this is done."
  value       = <<-EOT
    aws secretsmanager put-secret-value \
      --secret-id ${aws_secretsmanager_secret.spotify_credentials.name} \
      --secret-string '{"client_id":"<SPOTIFY_CLIENT_ID>","client_secret":"<SPOTIFY_CLIENT_SECRET>"}'
  EOT
}

output "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms. Subscribe additional endpoints via the AWS console if needed."
  value       = aws_sns_topic.alarms.arn
}
