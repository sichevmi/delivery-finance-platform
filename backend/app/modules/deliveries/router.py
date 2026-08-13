from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Dict, List, Any
from datetime import date, datetime
import logging

from app.core.database import get_db
from app.modules.users.dependencies import get_current_user
from app.modules.deliveries.services import DeliveryService
from app.modules.deliveries.models import Shift, Order, Delivery
from sqlalchemy import func

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


# ===== НОВЫЕ ЭНДПОИНТЫ ДЛЯ ЗАГРУЗКИ ДАННЫХ =====

@router.get("/sync/today")
async def get_today_data(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Получение данных за сегодня"""
    try:
        today = date.today()
        
        # Смены за сегодня
        shifts = db.query(Shift).filter(
            Shift.user_id == current_user.id,
            func.date(Shift.created_at) == today
        ).order_by(Shift.created_at.desc()).all()
        
        # Заказы за сегодня
        orders = db.query(Order).filter(
            Order.user_id == current_user.id,
            func.date(Order.created_at) == today
        ).order_by(Order.created_at.desc()).all()
        
        # Для каждого заказа получаем доставки
        orders_data = []
        for order in orders:
            deliveries = db.query(Delivery).filter(
                Delivery.order_id == order.id
            ).all()
            orders_data.append({
                "id": order.id,
                "localId": order.local_id,
                "shiftId": order.shift_id,
                "serviceName": order.service_name,
                "coefficient": order.coefficient,
                "deliveryNumber": order.delivery_number,
                "totalPaidDistance": order.total_paid_distance,
                "totalIncome": order.total_income,
                "totalExpenses": order.total_expenses,
                "netProfit": order.net_profit,
                "totalTimeSeconds": order.total_time_seconds,
                "status": order.status,
                "isSynced": order.is_synced,
                "createdAt": order.created_at.isoformat() if order.created_at else None,
                "deliveries": [
                    {
                        "id": d.id,
                        "localId": d.local_id,
                        "number": d.number,
                        "clientAddress": d.client_address,
                        "apartment": d.apartment,
                        "weight": d.weight,
                        "timeToShop": d.time_to_shop,
                        "distanceToShop": d.distance_to_shop,
                        "timeReceiving": d.time_receiving,
                        "timeToClient": d.time_to_client,
                        "distanceToClient": d.distance_to_client,
                        "timeDelivery": d.time_delivery,
                        "status": d.status,
                        "isSynced": d.is_synced,
                    }
                    for d in deliveries
                ]
            })
        
        return {
            "status": "success",
            "date": today.isoformat(),
            "shifts": [
                {
                    "id": s.id,
                    "localId": s.local_id,
                    "startTime": s.start_time,
                    "endTime": s.end_time,
                    "durationSeconds": s.duration_seconds,
                    "totalPaidDistance": s.total_paid_distance,
                    "totalIdleDistance": s.total_idle_distance,
                    "ordersCount": s.orders_count,
                    "totalIncome": s.total_income,
                    "totalExpenses": s.total_expenses,
                    "netProfit": s.net_profit,
                    "status": s.status,
                    "isSynced": s.is_synced,
                    "createdAt": s.created_at.isoformat() if s.created_at else None,
                }
                for s in shifts
            ],
            "orders": orders_data,
        }
    except Exception as e:
        logger.error(f"❌ Ошибка получения данных за сегодня: {e}")
        raise HTTPException(status_code=500, detail=str(e))