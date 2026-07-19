from fastapi import APIRouter

router = APIRouter(prefix="/billing", tags=["billing"])

@router.get("/")
def dummy():
    return {"message": "Billing module (stub)"}