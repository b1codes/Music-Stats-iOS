resource "aws_ssm_parameter" "spotify_credentials" {
  name        = "/${var.project_name}/spotify-credentials"
  type        = "SecureString"
  value       = jsonencode({ client_id = "PLACEHOLDER", client_secret = "PLACEHOLDER" })
  description = "Spotify Web API client_id and client_secret for Music Stats iOS"

  lifecycle {
    ignore_changes = [value]
  }
}
