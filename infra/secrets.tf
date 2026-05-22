resource "aws_secretsmanager_secret" "spotify_credentials" {
  name                    = "${var.project_name}/spotify-credentials"
  description             = "Spotify Web API client_id and client_secret for Music Stats iOS"
  recovery_window_in_days = 0
}
