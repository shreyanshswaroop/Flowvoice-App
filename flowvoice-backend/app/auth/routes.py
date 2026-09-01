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