variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
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
