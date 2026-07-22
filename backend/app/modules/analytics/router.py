from fastapi import APIRouter

router = APIRouter(prefix="/anaytics", tags=["anaytics"])


@router.get("/")
def dummy():
    return {"message": "Analytics module (stub)"}
