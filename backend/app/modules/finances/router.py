from fastapi import APIRouter

router = APIRouter(prefix="/finances", tags=["finances"])

@router.get("/")
def dummy():
    return {"message": "Finances module (stub)"}