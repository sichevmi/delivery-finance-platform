from fastapi import APIRouter

router = APIRouter(prefix="/delivery", tags=["delivery"])

@router.get("/")
def dummy():
    return {"message": "Delivery module (stub)"}