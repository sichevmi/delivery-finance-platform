from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session  # ← ДОБАВЛЯЕМ ИМПОРТ
from typing import Dict, List, Any
import logging

from app.core.database import get_db
from app.modules.users.dependencies import get_current_user  # ← ПРАВИЛЬНЫЙ ИМПОРТ
from app.modules.deliveries.services import DeliveryService
from app.modules.deliveries.models import Shift, Order, Delivery

logger = logging.getLogger(__name__)
router = APIRouter()


# ===== НОВЫЕ ЭНДПОИНТЫ ДЛЯ СИНХРОНИЗАЦИИ =====

@router.post("/sync/shifts")
async def sync_shifts(
    data: Dict[str, List[Dict[str, Any]]],
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Синхронизация смен с мобильного приложения"""
    try:
        service = DeliveryService(db)
        shifts_data = data.get("shifts", [])
        if not shifts_data:
            return {"synced": [], "total": 0, "message": "Нет данных для синхронизации"}
        
        result = await service.sync_shifts(shifts_data, current_user.id)
        return {
            "synced": result,
            "total": len(shifts_data),
            "status": "success"
        }
    except Exception as e:
        logger.error(f"❌ Ошибка синхронизации смен: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/sync/orders")
async def sync_orders(
    data: Dict[str, List[Dict[str, Any]]],
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Синхронизация заказов с мобильного приложения"""
    try:
        service = DeliveryService(db)
        orders_data = data.get("orders", [])
        if not orders_data:
            return {"synced": [], "total": 0, "message": "Нет данных для синхронизации"}
        
        result = await service.sync_orders(orders_data, current_user.id)
        return {
            "synced": result,
            "total": len(orders_data),
            "status": "success"
        }
    except Exception as e:
        logger.error(f"❌ Ошибка синхронизации заказов: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/sync/settings")
async def sync_settings(
    data: Dict[str, Any],
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Синхронизация настроек"""
    try:
        service = DeliveryService(db)
        result = await service.sync_settings(data, current_user.id)
        return result
    except Exception as e:
        logger.error(f"❌ Ошибка синхронизации настроек: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/sync/status")
async def get_sync_status(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Проверка статуса синхронизации"""
    try:
        # Подсчёт несинхронизированных записей
        unsynced_shifts = db.query(Shift).filter(
            Shift.user_id == current_user.id,
            Shift.is_synced == False
        ).count()
        
        unsynced_orders = db.query(Order).filter(
            Order.user_id == current_user.id,
            Order.is_synced == False
        ).count()
        
        unsynced_deliveries = db.query(Delivery).filter(
            Delivery.order_id.in_(
                db.query(Order.id).filter(Order.user_id == current_user.id)
            ),
            Delivery.is_synced == False
        ).count()
        
        return {
            "shifts_unsynced": unsynced_shifts,
            "orders_unsynced": unsynced_orders,
            "deliveries_unsynced": unsynced_deliveries,
            "status": "ok"
        }
    except Exception as e:
        logger.error(f"❌ Ошибка получения статуса: {e}")
        raise HTTPException(status_code=500, detail=str(e))