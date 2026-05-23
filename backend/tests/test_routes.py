import pytest
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient
from requests.exceptions import HTTPError as ReqHTTPError, Timeout
from app.main import app

client = TestClient(app)


def _make_http_error(status_code: int) -> ReqHTTPError:
    mock_resp = MagicMock()
    mock_resp.status_code = status_code
    mock_resp.text = '{"error": "invalid_grant"}'
    return ReqHTTPError(response=mock_resp)


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


def test_post_token_forwards_4xx_from_spotify():
    with patch("app.routes.token.exchange_code", side_effect=_make_http_error(400)):
        response = client.post(
            "/token",
            json={"code": "bad_code", "redirect_uri": "myapp://callback"},
        )
    assert response.status_code == 400


def test_post_token_returns_504_on_timeout():
    with patch("app.routes.token.exchange_code", side_effect=Timeout()):
        response = client.post(
            "/token",
            json={"code": "auth_code", "redirect_uri": "myapp://callback"},
        )
    assert response.status_code == 504


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


def test_post_refresh_forwards_4xx_from_spotify():
    with patch("app.routes.token.refresh_access_token", side_effect=_make_http_error(401)):
        response = client.post("/refresh", json={"refresh_token": "expired"})
    assert response.status_code == 401


def test_post_refresh_returns_422_when_body_missing():
    response = client.post("/refresh", json={})
    assert response.status_code == 422
