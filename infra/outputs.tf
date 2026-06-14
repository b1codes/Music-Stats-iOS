output "api_gateway_url" {
  description = "Base URL for the API Gateway. Set this as BACKEND_API_URL in Config.xcconfig."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "spotify_param_name" {
  description = "SSM parameter name holding Spotify credentials. Populate after apply if using a fresh deployment."
  value       = aws_ssm_parameter.spotify_credentials.name
}

output "secret_population_command" {
  description = "Run this command after apply to populate real Spotify credentials."
  value       = <<-EOT
    aws ssm put-parameter \
      --name ${aws_ssm_parameter.spotify_credentials.name} \
      --type SecureString \
      --overwrite \
      --value '{"client_id":"<SPOTIFY_CLIENT_ID>","client_secret":"<SPOTIFY_CLIENT_SECRET>"}'
  EOT
}

output "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms. Subscribe additional endpoints via the AWS console if needed."
  value       = aws_sns_topic.alarms.arn
}
