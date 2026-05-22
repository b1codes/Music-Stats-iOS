# Backend Spotify Proxy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a stateless AWS Lambda proxy (FastAPI + Mangum + Terraform) that holds the Spotify client secret in Secrets Manager and brokers token exchanges for the iOS app.

**Architecture:** The iOS app POSTs authorization codes and refresh tokens to API Gateway → Lambda. The Lambda reads Spotify credentials from Secrets Manager, exchanges tokens with Spotify, and returns the result. The iOS app continues to call Spotify APIs directly using the access token — only token exchange touches the backend.

**Tech Stack:** Python 3.12, FastAPI 0.115, Mangum 0.17, boto3, requests, pytest, Terraform (AWS provider ~5.0), AWS Lambda + API Gateway HTTP API v2 + Secrets Manager.

---

## File Map

### New files — `backend/`

| File | Responsibility |
|---|---|
| `backend/app/__init__.py` | Makes `app` a Python package |
| `backend/app/routes/__init__.py` | Makes `routes` a Python package |
| `backend/app/spotify_client.py` | Fetches Spotify credentials from Secrets Manager (cached), performs token exchange HTTP calls |
| `backend/app/routes/token.py` | FastAPI route handlers for `POST /token` and `POST /refresh` |
| `backend/app/main.py` | FastAPI app wiring + Mangum Lambda handler |
| `backend/requirements.txt` | Production deps only (bundled into Lambda zip) |
| `backend/requirements-dev.txt` | Test deps (pytest, httpx — never bundled) |
| `backend/tests/__init__.py` | Makes `tests` a package |
| `backend/tests/test_spotify_client.py` | Unit tests for `spotify_client.py` |
| `backend/tests/test_routes.py` | Integration tests for route handlers via FastAPI TestClient |
| `backend/.gitignore` | Excludes `__pycache__/`, `package/`, `*.zip`, `.env` |

### New files — `infra/`

| File | Responsibility |
|---|---|
| `infra/main.tf` | AWS provider config + Terraform version constraints |
| `infra/variables.tf` | `aws_region`, `project_name`, `environment` |
| `infra/outputs.tf` | Emits the API Gateway invoke URL |
| `infra/secrets.tf` | Creates Secrets Manager secret shell (no value in state) |
| `infra/iam.tf` | Lambda execution role + inline policy scoped to that one secret ARN |
| `infra/lambda.tf` | `null_resource` pip-install + `archive_file` zip + `aws_lambda_function` |
| `infra/api_gateway.tf` | HTTP API v2, two routes, `$default` stage, Lambda permission |

### Modified files — `frontend/`

| File | Change |
|---|---|
| `frontend/Music Stats iOS/Sample.xcconfig` | Remove `SPOTIFY_API_CLIENT_SECRET`, add `BACKEND_API_URL` |
| `frontend/Music Stats iOS/Config.xcconfig` | Same removals/additions (your local copy) |
| `frontend/Music-Stats-iOS-Info.plist` | Remove `SPOTIFY_API_CLIENT_SECRET` key, add `BACKEND_API_URL` key |
| `frontend/Music Stats iOS/AuthManager.swift` | Remove `createTokenURLRequest()`, replace with `backendURL(path:)`, update `exchangeCodeForTokens` and `refreshToken` to call the backend |

---

## Task 1: Bootstrap `backend/` directory structure

**Files:**
- Create: `backend/app/__init__.py`
- Create: `backend/app/routes/__init__.py`
- Create: `backend/tests/__init__.py`
- Create: `backend/requirements.txt`
- Create: `backend/requirements-dev.txt`
- Create: `backend/.gitignore`

- [ ] **Step 1: Create directory tree**

```bash
mkdir -p backend/app/routes backend/tests
```

- [ ] **Step 2: Create package init files**

Create `backend/app/__init__.py` — empty file.

Create `backend/app/routes/__init__.py` — empty file.

Create `backend/tests/__init__.py` — empty file.

- [ ] **Step 3: Create `backend/requirements.txt`**

```
fastapi==0.115.0
mangum==0.17.0
boto3==1.35.0
requests==2.32.0
```

- [ ] **Step 4: Create `backend/requirements-dev.txt`**

```
-r requirements.txt
pytest==8.3.0
httpx==0.27.0
pytest-asyncio==0.23.0
```

- [ ] **Step 5: Create `backend/.gitignore`**

```
__pycache__/
*.py[cod]
.pytest_cache/
package/
*.zip
.env
```

- [ ] **Step 6: Install dev dependencies locally**

```bash
cd backend && pip install -r requirements-dev.txt
```

Expected: pip installs cleanly with no errors.

- [ ] **Step 7: Commit**

```bash
git add backend/
git commit -m "chore: bootstrap backend/ directory structure"
```

---

## Task 2: Implement `spotify_client.py` (TDD)

**Files:**
- Create: `backend/app/spotify_client.py`
- Create: `backend/tests/test_spotify_client.py`

- [ ] **Step 1: Write failing tests**

Create `backend/tests/test_spotify_client.py`:

```python
import json
import pytest
from unittest.mock import patch, MagicMock
import app.spotify_client as sc


@pytest.fixture(autouse=True)
def reset_credentials():
    sc._credentials = None
    yield
    sc._credentials = None


def _mock_sm():
    mock = MagicMock()
    mock.get_secret_value.return_value = {
        "SecretString": json.dumps({
            "client_id": "test_id",
            "client_secret": "test_secret",
        })
    }
    return mock


def _mock_spotify_response(data: dict):
    mock = MagicMock()
    mock.json.return_value = data
    mock.raise_for_status = MagicMock()
    return mock


def test_exchange_code_posts_to_spotify(monkeypatch):
    monkeypatch.setenv("SPOTIFY_SECRET_ARN", "arn:aws:secretsmanager:us-east-1:123:secret:test")
    with patch("boto3.client", return_value=_mock_sm()), \
         patch("requests.post", return_value=_mock_spotify_response({
             "access_token": "access",
             "token_type": "Bearer",
             "expires_in": 3600,
             "refresh_token": "refresh",
         })) as mock_post:
        result = sc.exchange_code("auth_code", "myapp://callback")

    assert result["access_token"] == "access"
    assert result["refresh_token"] == "refresh"
    call_data = mock_post.call_args[1]["data"]
    assert call_data["grant_type"] == "authorization_code"
    assert call_data["code"] == "auth_code"
    assert call_data["redirect_uri"] == "myapp://callback"


def test_exchange_code_sends_basic_auth(monkeypatch):
    monkeypatch.setenv("SPOTIFY_SECRET_ARN", "arn:aws:secretsmanager:us-east-1:123:secret:test")
    from base64 import b64encode
    expected_auth = "Basic " + b64encode(b"test_id:test_secret").decode()

    with patch("boto3.client", return_value=_mock_sm()), \
         patch("requests.post", return_value=_mock_spotify_response({
             "access_token": "t", "token_type": "Bearer", "expires_in": 3600,
         })) as mock_post:
        sc.exchange_code("code", "myapp://cb")

    headers = mock_post.call_args[1]["headers"]
    assert headers["Authorization"] == expected_auth


def test_refresh_access_token_posts_to_spotify(monkeypatch):
    monkeypatch.setenv("SPOTIFY_SECRET_ARN", "arn:aws:secretsmanager:us-east-1:123:secret:test")
    with patch("boto3.client", return_value=_mock_sm()), \
         patch("requests.post", return_value=_mock_spotify_response({
             "access_token": "new_access",
             "token_type": "Bearer",
             "expires_in": 3600,
         })) as mock_post:
        result = sc.refresh_access_token("old_refresh")

    assert result["access_token"] == "new_access"
    call_data = mock_post.call_args[1]["data"]
    assert call_data["grant_type"] == "refresh_token"
    assert call_data["refresh_token"] == "old_refresh"


def test_credentials_are_cached_across_calls(monkeypatch):
    monkeypatch.setenv("SPOTIFY_SECRET_ARN", "arn:aws:secretsmanager:us-east-1:123:secret:test")
    mock_sm = _mock_sm()
    with patch("boto3.client", return_value=mock_sm), \
         patch("requests.post", return_value=_mock_spotify_response({
             "access_token": "t", "token_type": "Bearer", "expires_in": 3600,
         })):
        sc.exchange_code("code1", "uri")
        sc.exchange_code("code2", "uri")

    assert mock_sm.get_secret_value.call_count == 1
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd backend && python -m pytest tests/test_spotify_client.py -v
```

Expected: `ModuleNotFoundError: No module named 'app.spotify_client'`

- [ ] **Step 3: Implement `backend/app/spotify_client.py`**

```python
import json
import os
from base64 import b64encode

import boto3
import requests

_credentials = None


def _get_credentials() -> dict:
    global _credentials
    if _credentials is None:
        client = boto3.client("secretsmanager")
        response = client.get_secret_value(SecretId=os.environ["SPOTIFY_SECRET_ARN"])
        _credentials = json.loads(response["SecretString"])
    return _credentials


def _auth_header() -> str:
    creds = _get_credentials()
    combo = f"{creds['client_id']}:{creds['client_secret']}"
    return "Basic " + b64encode(combo.encode()).decode()


def exchange_code(code: str, redirect_uri: str) -> dict:
    response = requests.post(
        "https://accounts.spotify.com/api/token",
        headers={
            "Authorization": _auth_header(),
            "Content-Type": "application/x-www-form-urlencoded",
        },
        data={
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirect_uri,
        },
    )
    response.raise_for_status()
    return response.json()


def refresh_access_token(refresh_token: str) -> dict:
    response = requests.post(
        "https://accounts.spotify.com/api/token",
        headers={
            "Authorization": _auth_header(),
            "Content-Type": "application/x-www-form-urlencoded",
        },
        data={
            "grant_type": "refresh_token",
            "refresh_token": refresh_token,
        },
    )
    response.raise_for_status()
    return response.json()
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
cd backend && python -m pytest tests/test_spotify_client.py -v
```

Expected: 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add backend/app/spotify_client.py backend/tests/test_spotify_client.py
git commit -m "feat: add spotify_client with secret caching and token exchange"
```

---

## Task 3: Implement route handlers (TDD)

**Files:**
- Create: `backend/app/routes/token.py`
- Create: `backend/tests/test_routes.py`

Note: `test_routes.py` imports from `app.main`, which doesn't exist yet. Create a minimal `main.py` stub first so the import resolves during testing.

- [ ] **Step 1: Create minimal `backend/app/main.py` stub**

```python
from fastapi import FastAPI
from mangum import Mangum
from app.routes.token import router

app = FastAPI()
app.include_router(router)
handler = Mangum(app)
```

- [ ] **Step 2: Write failing route tests**

Create `backend/tests/test_routes.py`:

```python
import pytest
from unittest.mock import patch
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_post_token_returns_spotify_response():
    mock_result = {
        "access_token": "access",
        "token_type": "Bearer",
        "expires_in": 3600,
        "refresh_token": "refresh",
    }
    with patch("app.routes.token.exchange_code", return_value=mock_result):
        response = client.post(
            "/token",
            json={"code": "auth_code", "redirect_uri": "myapp://callback"},
        )
    assert response.status_code == 200
    body = response.json()
    assert body["access_token"] == "access"
    assert body["refresh_token"] == "refresh"


def test_post_token_returns_502_when_spotify_fails():
    with patch("app.routes.token.exchange_code", side_effect=Exception("upstream error")):
        response = client.post(
            "/token",
            json={"code": "bad_code", "redirect_uri": "myapp://callback"},
        )
    assert response.status_code == 502


def test_post_token_returns_422_when_body_missing_fields():
    response = client.post("/token", json={"code": "only_code"})
    assert response.status_code == 422


def test_post_refresh_returns_new_access_token():
    mock_result = {
        "access_token": "new_access",
        "token_type": "Bearer",
        "expires_in": 3600,
    }
    with patch("app.routes.token.refresh_access_token", return_value=mock_result):
        response = client.post(
            "/refresh",
            json={"refresh_token": "old_refresh"},
        )
    assert response.status_code == 200
    assert response.json()["access_token"] == "new_access"


def test_post_refresh_returns_502_when_spotify_fails():
    with patch("app.routes.token.refresh_access_token", side_effect=Exception("upstream error")):
        response = client.post("/refresh", json={"refresh_token": "bad_token"})
    assert response.status_code == 502


def test_post_refresh_returns_422_when_body_missing():
    response = client.post("/refresh", json={})
    assert response.status_code == 422
```

- [ ] **Step 3: Run tests to confirm they fail**

```bash
cd backend && python -m pytest tests/test_routes.py -v
```

Expected: `ModuleNotFoundError: No module named 'app.routes.token'`

- [ ] **Step 4: Implement `backend/app/routes/token.py`**

```python
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.spotify_client import exchange_code, refresh_access_token

router = APIRouter()


class TokenRequest(BaseModel):
    code: str
    redirect_uri: str


class RefreshRequest(BaseModel):
    refresh_token: str


@router.post("/token")
def token(body: TokenRequest):
    try:
        return exchange_code(body.code, body.redirect_uri)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=str(exc))


@router.post("/refresh")
def refresh(body: RefreshRequest):
    try:
        return refresh_access_token(body.refresh_token)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=str(exc))
```

- [ ] **Step 5: Run all tests**

```bash
cd backend && python -m pytest tests/ -v
```

Expected: 10 tests pass.

- [ ] **Step 6: Commit**

```bash
git add backend/app/routes/token.py backend/app/main.py backend/tests/test_routes.py
git commit -m "feat: add /token and /refresh route handlers"
```

---

## Task 4: Finalize `main.py` (already complete from stub)

The stub created in Task 3 is the final version of `main.py`. No changes needed. Skip to Task 5.

---

## Task 5: Bootstrap `infra/` Terraform

**Files:**
- Create: `infra/main.tf`
- Create: `infra/variables.tf`
- Create: `infra/outputs.tf`
- Create: `infra/.gitignore`

- [ ] **Step 1: Create `infra/` directory**

```bash
mkdir -p infra
```

- [ ] **Step 2: Create `infra/.gitignore`**

```
.terraform/
*.tfstate
*.tfstate.backup
lambda.zip
```

Note: commit `.terraform.lock.hcl` — it locks provider versions for reproducibility.

- [ ] **Step 3: Create `infra/main.tf`**

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

- [ ] **Step 4: Create `infra/variables.tf`**

```hcl
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
```

- [ ] **Step 5: Create `infra/outputs.tf`** (placeholder — filled in Task 9)

```hcl
# Populated in Task 9 after api_gateway.tf is written
```

- [ ] **Step 6: Initialize Terraform**

```bash
cd infra && terraform init
```

Expected: "Terraform has been successfully initialized!"

- [ ] **Step 7: Commit**

```bash
git add infra/
git commit -m "chore: bootstrap infra/ Terraform directory"
```

---

## Task 6: Write `infra/secrets.tf`

**Files:**
- Create: `infra/secrets.tf`

- [ ] **Step 1: Create `infra/secrets.tf`**

```hcl
resource "aws_secretsmanager_secret" "spotify_credentials" {
  name        = "${var.project_name}/spotify-credentials"
  description = "Spotify Web API client_id and client_secret for Music Stats iOS"
}
```

The secret **value** is intentionally not set here — Terraform state would expose it. You'll populate it via AWS CLI in Task 10.

- [ ] **Step 2: Validate**

```bash
cd infra && terraform validate
```

Expected: "Success! The configuration is valid."

- [ ] **Step 3: Commit**

```bash
git add infra/secrets.tf
git commit -m "feat(infra): add Secrets Manager secret shell for Spotify credentials"
```

---

## Task 7: Write `infra/iam.tf`

**Files:**
- Create: `infra/iam.tf`

- [ ] **Step 1: Create `infra/iam.tf`**

```hcl
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.project_name}-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "read_spotify_secret" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.spotify_credentials.arn]
  }
}

resource "aws_iam_role_policy" "read_spotify_secret" {
  name   = "read-spotify-credentials"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.read_spotify_secret.json
}
```

- [ ] **Step 2: Validate**

```bash
cd infra && terraform validate
```

Expected: "Success! The configuration is valid."

- [ ] **Step 3: Commit**

```bash
git add infra/iam.tf
git commit -m "feat(infra): add Lambda IAM role with least-privilege Secrets Manager access"
```

---

## Task 8: Write `infra/lambda.tf`

**Files:**
- Create: `infra/lambda.tf`

- [ ] **Step 1: Create `infra/lambda.tf`**

```hcl
locals {
  app_source_hash = sha1(join("", [
    for f in sort(fileset("${path.module}/../backend/app", "**/*.py")) :
    filesha1("${path.module}/../backend/app/${f}")
  ]))
}

resource "null_resource" "package_lambda" {
  triggers = {
    requirements = filemd5("${path.module}/../backend/requirements.txt")
    app_source   = local.app_source_hash
  }

  provisioner "local-exec" {
    command = <<-EOT
      rm -rf ${path.module}/../backend/package
      pip install -r ${path.module}/../backend/requirements.txt \
        -t ${path.module}/../backend/package \
        --quiet \
        --platform manylinux2014_x86_64 \
        --only-binary=:all:
      cp -r ${path.module}/../backend/app/. ${path.module}/../backend/package/
    EOT
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/package"
  output_path = "${path.module}/lambda.zip"
  depends_on  = [null_resource.package_lambda]
}

resource "aws_lambda_function" "api" {
  function_name    = "${var.project_name}-api"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "main.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 10
  memory_size      = 256

  environment {
    variables = {
      SPOTIFY_SECRET_ARN = aws_secretsmanager_secret.spotify_credentials.arn
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_basic_execution]
}
```

Note on `--platform manylinux2014_x86_64 --only-binary=:all:`: this installs Linux-compatible wheels even when running `terraform apply` from a Mac, which is required for Lambda's x86_64 Linux environment.

- [ ] **Step 2: Validate**

```bash
cd infra && terraform validate
```

Expected: "Success! The configuration is valid."

- [ ] **Step 3: Commit**

```bash
git add infra/lambda.tf
git commit -m "feat(infra): add Lambda function with auto-packaging from backend/app"
```

---

## Task 9: Write `infra/api_gateway.tf` and finalize `outputs.tf`

**Files:**
- Create: `infra/api_gateway.tf`
- Modify: `infra/outputs.tf`

- [ ] **Step 1: Create `infra/api_gateway.tf`**

```hcl
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "token" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /token"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "refresh" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /refresh"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
```

- [ ] **Step 2: Replace `infra/outputs.tf` content**

```hcl
output "api_gateway_url" {
  description = "Base URL for the API Gateway. Set this as BACKEND_API_URL in Config.xcconfig."
  value       = aws_apigatewayv2_stage.default.invoke_url
}
```

- [ ] **Step 3: Validate**

```bash
cd infra && terraform validate
```

Expected: "Success! The configuration is valid."

- [ ] **Step 4: Commit**

```bash
git add infra/api_gateway.tf infra/outputs.tf
git commit -m "feat(infra): add API Gateway HTTP API v2 with /token and /refresh routes"
```

---

## Task 10: Deploy and populate the secret

Prerequisites: AWS credentials configured locally (`aws configure` or env vars). Your IAM user/role needs permissions to create Lambda, API Gateway, IAM roles, and Secrets Manager resources.

- [ ] **Step 1: Review the plan**

```bash
cd infra && terraform plan
```

Review the output. You should see ~10 resources to create: 1 secret, 1 IAM role, 2 IAM policies, 1 Lambda function, 1 API, 1 integration, 2 routes, 1 stage, 1 Lambda permission.

- [ ] **Step 2: Apply**

```bash
cd infra && terraform apply
```

Type `yes` when prompted. Expected output at the end:

```
Outputs:
api_gateway_url = "https://<id>.execute-api.us-east-1.amazonaws.com"
```

Copy that URL — you'll need it in Task 11.

- [ ] **Step 3: Populate the Spotify credentials in Secrets Manager**

```bash
aws secretsmanager put-secret-value \
  --secret-id music-stats/spotify-credentials \
  --secret-string '{"client_id":"YOUR_SPOTIFY_CLIENT_ID","client_secret":"YOUR_SPOTIFY_CLIENT_SECRET"}'
```

Replace `YOUR_SPOTIFY_CLIENT_ID` and `YOUR_SPOTIFY_CLIENT_SECRET` with your actual Spotify Developer Dashboard values.

- [ ] **Step 4: Smoke test the deployed endpoint**

```bash
# This should return a Spotify error (invalid code), not a 500 — that confirms the Lambda
# reached Secrets Manager successfully and forwarded the request to Spotify.
curl -s -X POST https://<YOUR_API_GATEWAY_URL>/token \
  -H "Content-Type: application/json" \
  -d '{"code":"test","redirect_uri":"test://callback"}' | python3 -m json.tool
```

Expected: A 502 response with a Spotify error message (e.g., `"Invalid authorization code"`), NOT a Lambda internal error. A 502 with a Spotify message means the secret was fetched successfully and the request reached Spotify.

---

## Task 11: Update `AuthManager.swift`

**Files:**
- Modify: `frontend/Music Stats iOS/AuthManager.swift`

- [ ] **Step 1: Replace `createTokenURLRequest()` and update callers**

Open `frontend/Music Stats iOS/AuthManager.swift`. Make the following changes:

**Remove** the entire `createTokenURLRequest()` method (lines 98–117 in the original file).

**Replace** `refreshToken()` with:

```swift
func refreshToken() async {
    guard let refreshToken = keychain.get("refreshToken") else {
        isAuthenticated = false
        isLoading = false
        return
    }

    guard let url = backendURL(path: "/refresh") else {
        isAuthenticated = false
        isLoading = false
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONEncoder().encode(["refresh_token": refreshToken])
    await performTokenRequest(request)
}
```

**Replace** `exchangeCodeForTokens(code:)` with:

```swift
private func exchangeCodeForTokens(code: String) async {
    let redirectURIHost = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_HOST") as? String
    let redirectURIScheme = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_SCHEME") as? String
    let redirectURI = "\(redirectURIScheme ?? "")://\(redirectURIHost ?? "")"

    guard let url = backendURL(path: "/token") else {
        isAuthenticated = false
        isLoading = false
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONEncoder().encode([
        "code": code,
        "redirect_uri": redirectURI,
    ])
    await performTokenRequest(request)
}
```

**Add** this new private helper anywhere in the class:

```swift
private func backendURL(path: String) -> URL? {
    let base = Bundle.main.object(forInfoDictionaryKey: "BACKEND_API_URL") as? String ?? ""
    return URL(string: "\(base)\(path)")
}
```

- [ ] **Step 2: Build and verify no compiler errors**

Open the project in Xcode and build (`Cmd+B`). Fix any remaining references to `createTokenURLRequest` or `SPOTIFY_API_CLIENT_SECRET` if they appear.

- [ ] **Step 3: Commit**

```bash
git add "frontend/Music Stats iOS/AuthManager.swift"
git commit -m "feat: update AuthManager to call backend proxy instead of Spotify directly"
```

---

## Task 12: Update xcconfig files and Info.plist

**Files:**
- Modify: `frontend/Music Stats iOS/Sample.xcconfig`
- Modify: `frontend/Music Stats iOS/Config.xcconfig`
- Modify: `frontend/Music-Stats-iOS-Info.plist`

- [ ] **Step 1: Update `Sample.xcconfig`**

Replace its contents with:

```
// Configuration settings file format documentation can be found at:
// https://help.apple.com/xcode/#/dev745c5c974
SPOTIFY_API_CLIENT_ID =
REDIRECT_URI_SCHEME =
REDIRECT_URI_HOST =
BACKEND_API_URL =
```

(`SPOTIFY_API_CLIENT_SECRET` is removed — the secret now lives in AWS Secrets Manager.)

- [ ] **Step 2: Update your local `Config.xcconfig`**

Make the same change: remove `SPOTIFY_API_CLIENT_SECRET` and add `BACKEND_API_URL`. Set `BACKEND_API_URL` to the API Gateway URL from Task 10, Step 2.

```
SPOTIFY_API_CLIENT_ID = your_spotify_client_id
REDIRECT_URI_SCHEME = your_app_redirect_scheme
REDIRECT_URI_HOST = your_app_redirect_host
BACKEND_API_URL = https://<YOUR_API_GATEWAY_URL>
```

- [ ] **Step 3: Update `frontend/Music-Stats-iOS-Info.plist`**

Replace the plist contents with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>REDIRECT_URI_HOST</key>
	<string>$(REDIRECT_URI_HOST)</string>
	<key>REDIRECT_URI_SCHEME</key>
	<string>$(REDIRECT_URI_SCHEME)</string>
	<key>SPOTIFY_API_CLIENT_ID</key>
	<string>$(SPOTIFY_API_CLIENT_ID)</string>
	<key>BACKEND_API_URL</key>
	<string>$(BACKEND_API_URL)</string>
</dict>
</plist>
```

- [ ] **Step 4: Build the app in Xcode**

`Cmd+B` in Xcode. Expected: build succeeds with no errors.

- [ ] **Step 5: End-to-end test on simulator**

Run the app on a simulator. Tap "Authorize", complete the Spotify login flow, and verify:
- You are redirected back to the app
- Your top songs/albums/artists load correctly

If they load, the full round-trip is working: iOS → your API Gateway → Lambda → Secrets Manager → Spotify → back to iOS.

- [ ] **Step 6: Commit**

```bash
git add "frontend/Music Stats iOS/Sample.xcconfig" frontend/Music-Stats-iOS-Info.plist
git commit -m "feat: remove client secret from app bundle, add BACKEND_API_URL"
```

Note: `Config.xcconfig` should be in `.gitignore` — do not commit it.
