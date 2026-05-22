from typing import Annotated

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from requests.exceptions import ConnectionError as ReqConnectionError, Timeout

from app.spotify_client import exchange_code, refresh_access_token

router = APIRouter()

_NonEmptyStr = Annotated[str, Field(min_length=1)]


class TokenRequest(BaseModel):
    code: _NonEmptyStr
    redirect_uri: _NonEmptyStr


class RefreshRequest(BaseModel):
    refresh_token: _NonEmptyStr


@router.post("/token")
def token(body: TokenRequest):
    try:
        return exchange_code(body.code, body.redirect_uri)
    except (Timeout, ReqConnectionError):
        raise HTTPException(status_code=504, detail="Upstream timeout")
    except Exception:
        raise HTTPException(status_code=502, detail="Upstream error")


@router.post("/refresh")
def refresh(body: RefreshRequest):
    try:
        return refresh_access_token(body.refresh_token)
    except (Timeout, ReqConnectionError):
        raise HTTPException(status_code=504, detail="Upstream timeout")
    except Exception:
        raise HTTPException(status_code=502, detail="Upstream error")
