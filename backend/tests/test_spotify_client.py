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
    with patch("boto3.client", return_value=mock_sm) as mock_boto3, \
         patch("requests.post", return_value=_mock_spotify_response({
             "access_token": "t", "token_type": "Bearer", "expires_in": 3600,
         })):
        sc.exchange_code("code1", "uri")
        sc.exchange_code("code2", "uri")

    assert mock_boto3.call_count == 1
    assert mock_sm.get_secret_value.call_count == 1
