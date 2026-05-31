import logging
import os
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)

_TABLE_NAME = os.environ.get("USERS_TABLE_NAME", "music-stats-users")


def _get_table():
    dynamodb = boto3.resource("dynamodb")
    return dynamodb.Table(_TABLE_NAME)


def upsert_user(user_id: str, email: str | None, name: str | None) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    table = _get_table()

    try:
        response = table.update_item(
            Key={"user_id": user_id},
            UpdateExpression=(
                "SET email = :email, #n = :name, updated_at = :now,"
                " created_at = if_not_exists(created_at, :now)"
            ),
            ExpressionAttributeNames={"#n": "name"},
            ExpressionAttributeValues={
                ":email": email or "",
                ":name": name or "",
                ":now": now,
            },
            ReturnValues="ALL_NEW",
        )
        return response.get("Attributes", {})
    except ClientError as exc:
        logger.error("DynamoDB upsert failed for user %s: %r", user_id, exc)
        raise
