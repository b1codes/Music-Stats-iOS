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
