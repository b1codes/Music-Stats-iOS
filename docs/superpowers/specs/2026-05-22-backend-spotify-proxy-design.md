# Backend: Spotify Token Proxy — Design Spec

**Date:** 2026-05-22
**Status:** Approved

---

## Problem

The iOS app currently embeds `SPOTIFY_API_CLIENT_SECRET` in the app bundle via `Config.xcconfig` → Info.plist. This secret can be extracted from any distributed IPA, which violates Spotify's developer terms and is a real credential exposure risk.

---

## Solution

Introduce a stateless backend proxy that holds the Spotify client secret in AWS Secrets Manager. The iOS app sends authorization codes and refresh tokens to the proxy; the proxy performs the actual Spotify token exchange and returns the result. Spotify API calls (fetching top tracks, artists, etc.) continue to go directly from the iOS app using the access token.

---

## Architecture

```
iOS App
  → POST /token or /refresh  →  API Gateway (HTTP API v2)
                                  → Lambda (FastAPI + Mangum)
                                      → reads credentials from Secrets Manager
                                      → POST accounts.spotify.com/api/token
                                      ← Spotify returns tokens
                                  ← Lambda returns tokens
  ← iOS app stores refresh token in Keychain
  → iOS app calls Spotify APIs directly with access token
```

The backend is **stateless** — it never stores per-user tokens. Each request is fully self-contained.

---

## Endpoints

### `POST /token`
Exchanges a Spotify authorization code for an access token and refresh token.

**Request body:**
```json
{
  "code": "<authorization_code>",
  "redirect_uri": "<redirect_uri>"
}
```

**Response:**
```json
{
  "access_token": "...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "..."
}
```

### `POST /refresh`
Exchanges a refresh token for a new access token.

**Request body:**
```json
{
  "refresh_token": "<refresh_token>"
}
```

**Response:**
```json
{
  "access_token": "...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "..."
}
```

---

## Directory Structure

```
Music-Stats-iOS/
├── frontend/                   # existing iOS SwiftUI app (unchanged)
├── backend/                    # FastAPI Lambda application
│   ├── app/
│   │   ├── main.py             # FastAPI app entry point + Mangum handler
│   │   ├── routes/
│   │   │   └── token.py        # /token and /refresh route handlers
│   │   └── spotify_client.py   # Spotify token exchange logic
│   ├── requirements.txt        # fastapi, mangum, boto3, requests
│   ├── .gitignore
│   └── README.md
└── infra/                      # Terraform — all AWS infrastructure
    ├── main.tf                 # Provider config, optional S3 backend
    ├── variables.tf            # aws_region, environment, project_name
    ├── outputs.tf              # API Gateway invoke URL
    ├── lambda.tf               # Lambda function + archive_file zip packaging
    ├── api_gateway.tf          # HTTP API v2, routes, default stage, auto-deploy
    ├── iam.tf                  # Lambda execution role + Secrets Manager policy
    └── secrets.tf              # aws_secretsmanager_secret shell (no values in state)
```

---

## Credentials Storage

- **AWS Secrets Manager** holds a single JSON secret: `music-stats/spotify-credentials`
- Secret value shape: `{ "client_id": "...", "client_secret": "..." }`
- The Terraform `secrets.tf` creates the **secret shell only** (no `secret_string` in Terraform state)
- Actual values are populated via AWS CLI after provisioning:
  ```bash
  aws secretsmanager put-secret-value \
    --secret-id music-stats/spotify-credentials \
    --secret-string '{"client_id":"...","client_secret":"..."}'
  ```
- The Lambda IAM role gets a least-privilege policy: `secretsmanager:GetSecretValue` scoped to that one secret ARN only
- The Lambda caches the secret in-process (module-level variable) to avoid fetching it on every cold start

---

## iOS App Changes

`AuthManager.swift` needs two updates:

1. **Remove** `SPOTIFY_API_CLIENT_SECRET` from all xcconfig files and Info.plist (the secret no longer belongs in the app)
2. **Replace** direct calls to `accounts.spotify.com/api/token` in `createTokenURLRequest()` with calls to the API Gateway URL (stored as a new xcconfig value `BACKEND_API_URL`)

The redirect URI, client ID, and all Spotify API calls (top tracks, artists, etc.) remain unchanged in the app.

---

## Infrastructure Details

| Resource | Details |
|---|---|
| Lambda runtime | Python 3.12 |
| Lambda memory | 256 MB |
| Lambda timeout | 10s |
| API Gateway | HTTP API v2 (not REST API) — cheaper, simpler |
| Packaging | `archive_file` data source in `lambda.tf` zips `../backend/app/` + dependencies |
| Secret rotation | Manual for now; Secrets Manager rotation can be added later |
| Terraform state | Local by default; S3 backend recommended for team use |

---

## What Is Explicitly Out of Scope

- DynamoDB / per-user server-side storage (refresh tokens stay in iOS Keychain)
- Caching of Spotify API responses server-side
- Social/multi-user comparison features
- CI/CD pipeline (can be added later with GitHub Actions)
- WAF or API Gateway usage plans / throttling (can be added when traffic warrants)
