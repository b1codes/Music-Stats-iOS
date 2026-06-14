variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Prefix applied to all resource names"
  type        = string
  default     = "music-stats"
}

variable "environment" {
  description = "Deployment environment tag"
  type        = string
  default     = "prod"
}

variable "cors_allowed_origins" {
  description = "Origins permitted to call the API (browser CORS). Use [\"*\"] for open access or lock down to specific domains."
  type        = list(string)
  default     = ["*"]
}

variable "alarm_email" {
  description = "Email address to receive CloudWatch alarm notifications (optional)"
  type        = string
  default     = ""
}

variable "auth0_domain" {
  description = "Auth0 tenant domain (e.g. your-tenant.us.auth0.com)"
  type        = string
  default     = ""
}

variable "auth0_audience" {
  description = "Auth0 API audience identifier (the API identifier set in the Auth0 dashboard)"
  type        = string
  default     = ""
}
