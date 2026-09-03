import os

from google.auth.transport import requests as google_requests
from google.oauth2 import id_token

from datetime import datetime, timezone

from bson import ObjectId

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status,
)

from fastapi.security import (
    HTTPAuthorizationCredentials,
    HTTPBearer,
)

from app.auth.models import (
    GoogleLoginRequest,
    LoginRequest,
    SignUpRequest,
    UserResponse,
)


from app.auth.security import (
    create_access_token,
    decode_access_token,
    hash_password,
    verify_password,
)

from app.database import users_collection


router = APIRouter(
    prefix="/auth",
    tags=["auth"],
)

security = HTTPBearer()

@router.post(
    "/signup",
    status_code=status.HTTP_201_CREATED,
)
async def signup(
    payload: SignUpRequest,
):
    normalized_email = (
        payload.email
        .strip()
        .lower()
    )

    existing_user = users_collection.find_one(
        {
            "email": normalized_email
        }
    )

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists.",
        )

    user_document = {
        "name": payload.name.strip(),
        "email": normalized_email,
        "password_hash": hash_password(
            payload.password
        ),
        "provider": "email",
        "created_at": datetime.now(
            timezone.utc
        ),
        "last_login": None,
    }

    result = users_collection.insert_one(
        user_document
    )

    user_id = str(
        result.inserted_id
    )

    access_token = create_access_token(
        user_id=user_id,
        email=normalized_email,
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": UserResponse(
            id=user_id,
            name=user_document["name"],
            email=user_document["email"],
            provider=user_document["provider"],
        ),
    }


@router.post("/login")
async def login(
    payload: LoginRequest,
):
    normalized_email = (
        payload.email
        .strip()
        .lower()
    )

    user = users_collection.find_one(
        {
            "email": normalized_email
        }
    )

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
        )

    password_hash = user.get(
        "password_hash"
    )

    if not password_hash:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="This account does not support password login.",
        )

    if not verify_password(
        payload.password,
        password_hash,
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
        )

    users_collection.update_one(
        {
            "_id": user["_id"]
        },
        {
            "$set": {
                "last_login": datetime.now(
                    timezone.utc
                )
            }
        }
    )

    access_token = create_access_token(
        user_id=str(user["_id"]),
        email=user["email"],
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": UserResponse(
            id=str(user["_id"]),
            name=user["name"],
            email=user["email"],
            provider=user.get(
                "provider",
                "email",
            ),
        ),
    }

@router.post("/google")
async def google_login(
    payload: GoogleLoginRequest,
):
    google_client_id = os.getenv(
        "GOOGLE_CLIENT_ID"
    )

    if not google_client_id:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Google authentication is not configured.",
        )

    try:
        google_user = id_token.verify_oauth2_token(
            payload.id_token,
            google_requests.Request(),
            google_client_id,
        )

    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Google authentication token.",
        )

    email = google_user.get("email")

    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Google account does not provide an email address.",
        )

    email_verified = google_user.get(
        "email_verified"
    )

    if not email_verified:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Google email address is not verified.",
        )

    normalized_email = (
        email
        .strip()
        .lower()
    )

    name = (
        google_user.get("name")
        or google_user.get("given_name")
        or normalized_email.split("@")[0]
    )

    google_subject = google_user.get("sub")

    user = users_collection.find_one(
        {
            "email": normalized_email
        }
    )

    # MARK: Existing User

    if user:

        update_data = {
            "last_login": datetime.now(
                timezone.utc
            )
        }

        # Attach Google identity if this
        # account existed through email login.
        if not user.get("google_sub"):
            update_data["google_sub"] = (
                google_subject
            )

        users_collection.update_one(
            {
                "_id": user["_id"]
            },
            {
                "$set": update_data
            }
        )

        user_id = str(
            user["_id"]
        )

        provider = user.get(
            "provider",
            "email",
        )

    # MARK: New User

    else:

        user_document = {
            "name": name,
            "email": normalized_email,
            "password_hash": None,
            "provider": "google",
            "google_sub": google_subject,
            "created_at": datetime.now(
                timezone.utc
            ),
            "last_login": datetime.now(
                timezone.utc
            ),
        }

        result = users_collection.insert_one(
            user_document
        )

        user_id = str(
            result.inserted_id
        )

        provider = "google"

    access_token = create_access_token(
        user_id=user_id,
        email=normalized_email,
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": UserResponse(
            id=user_id,
            name=name,
            email=normalized_email,
            provider=provider,
        ),
    }

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
):
    token = credentials.credentials

    payload = decode_access_token(token)

    user_id = payload.get("sub")

    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token.",
        )

    try:
        object_id = ObjectId(user_id)

    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token.",
        )

    user = users_collection.find_one(
        {
            "_id": object_id
        }
    )

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User no longer exists.",
        )

    return user

@router.get("/me")
async def me(
    user=Depends(get_current_user),
):
    return {
        "id": str(user["_id"]),
        "name": user["name"],
        "email": user["email"],
        "provider": user.get(
            "provider",
            "email",
        ),
    }