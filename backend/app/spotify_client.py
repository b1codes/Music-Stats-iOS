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


_SPOTIFY_TOKEN_URL = "https://accounts.spotify.com/api/token"
_REQUEST_TIMEOUT = 8  # slightly under the 10s Lambda timeout so we return 502 before API GW 504s


def exchange_code(code: str, redirect_uri: str) -> dict:
    response = requests.post(
        _SPOTIFY_TOKEN_URL,
        headers={
            "Authorization": _auth_header(),
            "Content-Type": "application/x-www-form-urlencoded",
        },
        data={
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirect_uri,
        },
        timeout=_REQUEST_TIMEOUT,
    )
    response.raise_for_status()
    return response.json()


def refresh_access_token(refresh_token: str) -> dict:
    response = requests.post(
        _SPOTIFY_TOKEN_URL,
        headers={
            "Authorization": _auth_header(),
            "Content-Type": "application/x-www-form-urlencoded",
        },
        data={
            "grant_type": "refresh_token",
            "refresh_token": refresh_token,
        },
        timeout=_REQUEST_TIMEOUT,
    )
    response.raise_for_status()
    return response.json()
