import logging

from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.auth0_client import verify_token
from app.dynamo import upsert_user

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/auth")
_security = HTTPBearer()


@router.post("/login")
def login(credentials: HTTPAuthorizationCredentials = Depends(_security)):
    try:
        claims = verify_token(credentials.credentials)
    except Exception as exc:
        logger.warning("Auth0 token verification failed: %r", exc)
        raise HTTPException(status_code=401, detail="Invalid token")

    user_id: str = claims["sub"]
    email: str | None = claims.get("email")
    name: str | None = claims.get("name")

    try:
        upsert_user(user_id, email, name)
    except Exception as exc:
        logger.error("Failed to upsert user %s: %r", user_id, exc)
        raise HTTPException(status_code=500, detail="Internal error")

    return {"user_id": user_id, "email": email, "name": name}
