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
