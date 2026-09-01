import os

from dotenv import load_dotenv
from fastapi import (
    FastAPI,
    Response,
    status,
)
from fastapi.middleware.cors import (
    CORSMiddleware,
)

from app.auth.routes import (
    router as auth_router,
)

from app.database import (
    check_database_connection,
)

from app.dictations.routes import (
    router as dictations_router,
)

from app.websocket import (
    router as websocket_router,
)

from app.notes.routes import (
    router as notes_router,
)

from app.insights.routes import (
    router as insights_router,
)

from app.analytics.routes import (
    router as analytics_router,
)
from app.dictionary.routes import (
    router as dictionary_router,
)


load_dotenv()


app = FastAPI(
    title="FlowVoice API",
    version="0.1.0",
)


allowed_origins = [
    origin.strip()
    for origin in os.getenv(
        "CORS_ORIGINS",
        "http://localhost:3000,http://localhost:3001",
    ).split(",")
    if origin.strip()
]


app.add_middleware(
    CORSMiddleware,
    allow_origins=
        allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup_event():

    check_database_connection()


app.include_router(
    websocket_router
)

app.include_router(
    auth_router
)

app.include_router(
    dictations_router
)

app.include_router(
    notes_router
)

app.include_router(
    insights_router
)

app.include_router(
    analytics_router
)

app.include_router(
    dictionary_router
)

@app.get("/")
async def root():

    return {
        "name":
            "FlowVoice API",
        "status":
            "running",
    }


@app.get("/health")
async def health():

    return {
        "status":
            "healthy",
    }


@app.get("/health/db")
async def database_health(
    response: Response,
):

    if check_database_connection():

        return {
            "status":
                "healthy",
        }

    response.status_code = (
        status
        .HTTP_503_SERVICE_UNAVAILABLE
    )

    return {
        "status":
            "unhealthy",
    }