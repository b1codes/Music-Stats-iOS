import json
import logging
import os

import requests
from jwt import PyJWTError, decode, get_unverified_header
from jwt.algorithms import RSAAlgorithm

logger = logging.getLogger(__name__)

_jwks_cache: dict | None = None


def _get_auth0_config() -> tuple[str, str]:
    domain = os.environ.get("AUTH0_DOMAIN", "")
    audience = os.environ.get("AUTH0_AUDIENCE", "")
    if not domain or not audience:
        raise RuntimeError("AUTH0_DOMAIN and AUTH0_AUDIENCE must be set")
    return domain, audience


def _get_jwks(domain: str) -> dict:
    global _jwks_cache
    if _jwks_cache is None:
        url = f"https://{domain}/.well-known/jwks.json"
        response = requests.get(url, timeout=5)
        response.raise_for_status()
        _jwks_cache = response.json()
    return _jwks_cache


def verify_token(token: str) -> dict:
    domain, audience = _get_auth0_config()
    jwks = _get_jwks(domain)

    header = get_unverified_header(token)
    kid = header.get("kid")
    key_data = next((k for k in jwks["keys"] if k["kid"] == kid), None)
    if key_data is None:
        raise ValueError(f"No matching key in JWKS for kid={kid!r}")

    public_key = RSAAlgorithm.from_jwk(json.dumps(key_data))

    try:
        payload = decode(
            token,
            public_key,
            algorithms=["RS256"],
            audience=audience,
            issuer=f"https://{domain}/",
        )
    except PyJWTError as exc:
        logger.warning("JWT verification failed: %r", exc)
        raise

    return payload
