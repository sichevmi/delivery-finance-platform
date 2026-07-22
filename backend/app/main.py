import logging

from app.modules.analytics.router import router as analytics_router
from app.modules.billing.router import router as billing_router
from app.modules.deliveries.router import router as deliveries_router
from app.modules.finances.router import router as finances_router
from app.modules.notifications.router import router as notifications_router
from app.modules.users.router import router as users_router
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI(title="Delivery & Finance API", version="0.1.0")
Instrumentator().instrument(app).expose(app, endpoint="/metrics")
logging.basicConfig(level=logging.DEBUG)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Подключаем роутеры
app.include_router(users_router, prefix="/api/v1")
app.include_router(finances_router, prefix="/api/v1")
app.include_router(deliveries_router, prefix="/api/v1")
app.include_router(analytics_router, prefix="/api/v1")
app.include_router(notifications_router, prefix="/api/v1")
app.include_router(billing_router, prefix="/api/v1")


@app.get("/")
def root():
    return {"message": "FinFlow API", "docs": "/docs"}
