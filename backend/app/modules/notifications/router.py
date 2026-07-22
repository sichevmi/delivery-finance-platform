from fastapi import APIRouter

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("/")
def dummy():
    return {"message": "Notifications module (stub)"}
