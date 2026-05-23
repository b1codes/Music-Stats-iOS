import logging
from typing import Annotated

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from requests.exceptions import ConnectionError as ReqConnectionError, HTTPError, Timeout

from app.spotify_client import exchange_code, refresh_access_token

logger = logging.getLogger(__name__)
router = APIRouter()

_NonEmptyStr = Annotated[str, Field(min_length=1)]


class TokenRequest(BaseModel):
    code: _NonEmptyStr
    redirect_uri: _NonEmptyStr


class RefreshRequest(BaseModel):
    refresh_token: _NonEmptyStr


def _handle_spotify_error(exc: Exception) -> HTTPException:
    if isinstance(exc, (Timeout, ReqConnectionError)):
        logger.warning("Spotify request timed out or connection failed: %r", exc)
        return HTTPException(status_code=504, detail="Upstream timeout")
    if isinstance(exc, HTTPError):
        status = exc.response.status_code if exc.response is not None else 502
        body = exc.response.text if exc.response is not None else ""
        logger.warning("Spotify returned %d: %s", status, body)
        if 400 <= status < 500:
            return HTTPException(status_code=status, detail="Upstream auth error")
        return HTTPException(status_code=502, detail="Upstream error")
    logger.error("Unexpected error calling Spotify: %r", exc)
    return HTTPException(status_code=502, detail="Upstream error")


@router.post("/token")
def token(body: TokenRequest):
    try:
        return exchange_code(body.code, body.redirect_uri)
    except Exception as exc:
        raise _handle_spotify_error(exc)


@router.post("/refresh")
def refresh(body: RefreshRequest):
    try:
        return refresh_access_token(body.refresh_token)
    except Exception as exc:
        raise _handle_spotify_error(exc)
