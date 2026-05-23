output "api_gateway_url" {
  description = "Base URL for the API Gateway. Set this as BACKEND_API_URL in Config.xcconfig."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "spotify_secret_name" {
  description = <<-EOT
    Name of the Secrets Manager secret to populate after first apply:
      aws secretsmanager put-secret-value \
        --secret-id <value> \
        --secret-string '{"client_id":"<id>","client_secret":"<secret>"}'
    The Lambda will fail with InvalidRequestException until this is done.
  EOT
  value = aws_secretsmanager_secret.spotify_credentials.name
}
