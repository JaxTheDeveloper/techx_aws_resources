"""FastAPI app for DocHub. Tenant header is required on every request."""
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, File, Form, Header, HTTPException, UploadFile, Request
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from mangum import Mangum

from src.config import config
from src.adapters import factory
from src import handlers


app = FastAPI(title="DocHub — W7 Capstone Starter")


# CORS — allow frontend to live on a different origin (CloudFront / Amplify / separate ALB).
# CORS_ORIGINS env var controls this; default '*' is permissive for hackathon.
_allowed = ["*"] if config.cors_origins == "*" else [o.strip() for o in config.cors_origins.split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_allowed,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

ai_client = factory.make_ai()
storage = factory.make_storage()
userstore = factory.make_userstore()
vector_store = factory.make_vector()


def _resolve_identity(request: Request, x_user_id: Optional[str], x_tenant_id: Optional[str]) -> tuple:
    """Resolve user and tenant from Cognito JWT groups or header fallback.

    When a JWT is present, `cognito:groups` (comma-separated from the
    Pre Token Generation Lambda) defines the user's allowed tenants.
    The `X-Tenant-Id` header carries the user's dropdown selection,
    which is validated against the allowed list.
    """
    user_id = None
    allowed_tenants = None

    aws_event = request.scope.get("aws.event")
    if aws_event and "requestContext" in aws_event:
        authorizer = aws_event["requestContext"].get("authorizer", {})
        claims = authorizer.get("jwt", {}).get("claims", authorizer.get("claims", {}))
        user_id = claims.get("sub") or claims.get("username")
        raw_groups = claims.get("cognito:groups", [])
        if isinstance(raw_groups, list):
            allowed_tenants = [g.strip() for g in raw_groups if g and isinstance(g, str)]
        elif isinstance(raw_groups, str) and raw_groups:
            cleaned = raw_groups.strip("[]")
            allowed_tenants = [g.strip() for g in cleaned.replace(",", " ").split() if g.strip()]

    if not user_id:
        user_id = x_user_id
    user_id = user_id or config.default_user_id

    # Tenant from header (user's dropdown selection)
    tenant_id = x_tenant_id

    if allowed_tenants:
        if tenant_id and tenant_id not in allowed_tenants:
            raise HTTPException(
                status_code=403,
                detail=f"Tenant '{tenant_id}' not in user's allowed tenants (raw={raw_groups!r}, parsed={allowed_tenants})",
            )
        if not tenant_id:
            tenant_id = allowed_tenants[0]
    elif not tenant_id:
        tenant_id = config.default_tenant_id

    return user_id, tenant_id


class QueryRequest(BaseModel):
    question: str


@app.get("/health")
def health() -> dict:
    return {
        "status": "ok",
        "backends": {
            "ai": config.ai_backend,
            "storage": config.storage_backend,
            "userstore": config.userstore_backend,
            "vector": config.vector_backend,
        },
    }


@app.post("/upload")
async def upload(
    request: Request,
    file: UploadFile = File(...),
    doc_type: str = Form(default="general"),
    x_user_id: Optional[str] = Header(default=None),
    x_tenant_id: Optional[str] = Header(default=None),
) -> dict:
    user_id, tenant_id = _resolve_identity(request, x_user_id, x_tenant_id)
    data = await file.read()
    if not data:
        raise HTTPException(status_code=400, detail="Empty file")
    return handlers.handle_upload(
        tenant_id=tenant_id,
        user_id=user_id,
        filename=file.filename or "untitled",
        doc_type=doc_type,
        data=data,
        storage=storage,
        userstore=userstore,
        vector_store=vector_store,
    )


@app.post("/query")
def query(
    request: Request,
    req: QueryRequest,
    x_user_id: Optional[str] = Header(default=None),
    x_tenant_id: Optional[str] = Header(default=None),
) -> dict:
    _, tenant_id = _resolve_identity(request, x_user_id, x_tenant_id)
    if not req.question.strip():
        raise HTTPException(status_code=400, detail="Empty question")
    return handlers.handle_query(
        tenant_id=tenant_id,
        question=req.question,
        ai_client=ai_client,
        vector_store=vector_store,
        vector_backend=config.vector_backend,
        bedrock_kb_id=config.vector_bedrock_kb_id,
    )


@app.get("/docs/list")
def list_docs(
    request: Request,
    doc_type: Optional[str] = None,
    x_user_id: Optional[str] = Header(default=None),
    x_tenant_id: Optional[str] = Header(default=None),
) -> dict:
    _, tenant_id = _resolve_identity(request, x_user_id, x_tenant_id)
    return handlers.handle_list_docs(tenant_id, doc_type, userstore)


# Entry point for AWS Lambda
handler = Mangum(app)


# ---- Static frontend ----
FRONTEND_DIR = Path(__file__).resolve().parent.parent / "frontend"


if config.serve_frontend:
    @app.get("/")
    def index() -> FileResponse:
        """Convenience: serves frontend/index.html at /. Set SERVE_FRONTEND=false
        if you deploy the frontend separately (CloudFront+S3, Amplify, ALB)."""
        return FileResponse(FRONTEND_DIR / "index.html")
