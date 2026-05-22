output "api_gateway_url" {
  description = "Base URL for the API Gateway. Set this as BACKEND_API_URL in Config.xcconfig."
  value       = aws_apigatewayv2_stage.default.invoke_url
}
