from unittest.mock import patch

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_login_returns_user_on_valid_token():
    mock_claims = {"sub": "auth0|abc123", "email": "user@example.com", "name": "Test User"}
    with patch("app.routes.auth.verify_token", return_value=mock_claims), \
         patch("app.routes.auth.upsert_user", return_value={}):
        response = client.post(
            "/auth/login",
            headers={"Authorization": "Bearer valid.jwt.token"},
        )
    assert response.status_code == 200
    body = response.json()
    assert body["user_id"] == "auth0|abc123"
    assert body["email"] == "user@example.com"
    assert body["name"] == "Test User"


def test_login_returns_401_on_invalid_token():
    with patch("app.routes.auth.verify_token", side_effect=ValueError("bad token")):
        response = client.post(
            "/auth/login",
            headers={"Authorization": "Bearer invalid.jwt.token"},
        )
    assert response.status_code == 401


def test_login_returns_500_on_dynamo_error():
    mock_claims = {"sub": "auth0|abc123", "email": "user@example.com", "name": "Test User"}
    with patch("app.routes.auth.verify_token", return_value=mock_claims), \
         patch("app.routes.auth.upsert_user", side_effect=Exception("DynamoDB down")):
        response = client.post(
            "/auth/login",
            headers={"Authorization": "Bearer valid.jwt.token"},
        )
    assert response.status_code == 500


def test_login_returns_403_when_no_auth_header():
    response = client.post("/auth/login")
    assert response.status_code == 403


def test_login_handles_missing_optional_claims():
    mock_claims = {"sub": "auth0|abc123"}
    with patch("app.routes.auth.verify_token", return_value=mock_claims), \
         patch("app.routes.auth.upsert_user", return_value={}):
        response = client.post(
            "/auth/login",
            headers={"Authorization": "Bearer valid.jwt.token"},
        )
    assert response.status_code == 200
    body = response.json()
    assert body["user_id"] == "auth0|abc123"
    assert body["email"] is None
    assert body["name"] is None
