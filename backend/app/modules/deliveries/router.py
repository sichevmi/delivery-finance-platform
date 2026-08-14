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


# ===== НОВЫЕ ЭНДПОИНТЫ ДЛЯ СПРАВОЧНИКОВ =====

@router.get("/directories")
async def get_directories(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Получение всех справочников"""
    try:
        from app.modules.deliveries.models import Settings, Pricing, X5Settings
        
        settings = db.query(Settings).filter(
            Settings.is_active == True
        ).order_by(Settings.id.desc()).first()
        
        pricing = db.query(Pricing).filter(
            Pricing.is_active == True
        ).order_by(Pricing.id.desc()).first()
        
        x5_settings = db.query(X5Settings).filter(
            X5Settings.is_active == True
        ).order_by(X5Settings.id.desc()).first()
        
        return {
            "status": "success",
            "settings": {
                "id": settings.id if settings else None,
                "fuelConsumption": settings.fuel_consumption if settings else 10.0,
                "fuelPrice": settings.fuel_price if settings else 50.0,
                "repairCost": settings.repair_cost if settings else 2.0,
                "additionalCosts": settings.additional_costs if settings else 0.0,
                "version": settings.version if settings else 1,
                "updatedAt": settings.updated_at.isoformat() if settings and settings.updated_at else None,
            } if settings else None,
            "pricing": {
                "id": pricing.id if pricing else None,
                "receivingFee": pricing.receiving_fee if pricing else 50.0,
                "deliveryFee": pricing.delivery_fee if pricing else 100.0,
                "pricePerKg": pricing.price_per_kg if pricing else 5.0,
                "pricePerKm": pricing.price_per_km if pricing else 10.0,
                "baseCoefficient": pricing.base_coefficient if pricing else 1.0,
                "version": pricing.version if pricing else 1,
                "updatedAt": pricing.updated_at.isoformat() if pricing and pricing.updated_at else None,
            } if pricing else None,
            "x5Settings": {
                "id": x5_settings.id if x5_settings else None,
                "pickupPrice": x5_settings.pickup_price if x5_settings else 250.0,
                "deliveryPrice": x5_settings.delivery_price if x5_settings else 150.0,
                "perKmPrice": x5_settings.per_km_price if x5_settings else 25.0,
                "perKgPrice": x5_settings.per_kg_price if x5_settings else 10.0,
                "version": x5_settings.version if x5_settings else 1,
                "updatedAt": x5_settings.updated_at.isoformat() if x5_settings and x5_settings.updated_at else None,
            } if x5_settings else None,
        }
    except Exception as e:
        logger.error(f"❌ Ошибка получения справочников: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/directories/settings")
async def update_settings(
    data: Dict[str, Any],
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Обновление настроек"""
    try:
        from app.modules.deliveries.models import Settings
        
        version = data.get("version", 0)
        
        existing = db.query(Settings).filter(
            Settings.is_active == True
        ).order_by(Settings.id.desc()).first()
        
        if existing and existing.version != version:
            return {
                "status": "conflict",
                "message": "Настройки были изменены на сервере",
                "server": {
                    "fuelConsumption": existing.fuel_consumption,
                    "fuelPrice": existing.fuel_price,
                    "repairCost": existing.repair_cost,
                    "additionalCosts": existing.additional_costs,
                    "version": existing.version,
                }
            }
        
        if existing:
            existing.fuel_consumption = data.get("fuelConsumption", 10.0)
            existing.fuel_price = data.get("fuelPrice", 50.0)
            existing.repair_cost = data.get("repairCost", 2.0)
            existing.additional_costs = data.get("additionalCosts", 0.0)
            existing.version = existing.version + 1
            existing.updated_at = datetime.utcnow()
            db.commit()
            db.refresh(existing)
            return {
                "status": "success",
                "settings": {
                    "id": existing.id,
                    "fuelConsumption": existing.fuel_consumption,
                    "fuelPrice": existing.fuel_price,
                    "repairCost": existing.repair_cost,
                    "additionalCosts": existing.additional_costs,
                    "version": existing.version,
                }
            }
        else:
            new_settings = Settings(
                fuel_consumption=data.get("fuelConsumption", 10.0),
                fuel_price=data.get("fuelPrice", 50.0),
                repair_cost=data.get("repairCost", 2.0),
                additional_costs=data.get("additionalCosts", 0.0),
                version=1,
                is_active=True,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
            )
            db.add(new_settings)
            db.commit()
            db.refresh(new_settings)
            return {
                "status": "success",
                "settings": {
                    "id": new_settings.id,
                    "fuelConsumption": new_settings.fuel_consumption,
                    "fuelPrice": new_settings.fuel_price,
                    "repairCost": new_settings.repair_cost,
                    "additionalCosts": new_settings.additional_costs,
                    "version": new_settings.version,
                }
            }
    except Exception as e:
        logger.error(f"❌ Ошибка обновления настроек: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/directories/pricing")
async def update_pricing(
    data: Dict[str, Any],
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Обновление тарифов"""
    try:
        from app.modules.deliveries.models import Pricing
        
        version = data.get("version", 0)
        
        existing = db.query(Pricing).filter(
            Pricing.is_active == True
        ).order_by(Pricing.id.desc()).first()
        
        if existing and existing.version != version:
            return {
                "status": "conflict",
                "message": "Тарифы были изменены на сервере",
                "server": {
                    "receivingFee": existing.receiving_fee,
                    "deliveryFee": existing.delivery_fee,
                    "pricePerKg": existing.price_per_kg,
                    "pricePerKm": existing.price_per_km,
                    "baseCoefficient": existing.base_coefficient,
                    "version": existing.version,
                }
            }
        
        if existing:
            existing.receiving_fee = data.get("receivingFee", 50.0)
            existing.delivery_fee = data.get("deliveryFee", 100.0)
            existing.price_per_kg = data.get("pricePerKg", 5.0)
            existing.price_per_km = data.get("pricePerKm", 10.0)
            existing.base_coefficient = data.get("baseCoefficient", 1.0)
            existing.version = existing.version + 1
            existing.updated_at = datetime.utcnow()
            db.commit()
            db.refresh(existing)
            return {
                "status": "success",
                "pricing": {
                    "id": existing.id,
                    "receivingFee": existing.receiving_fee,
                    "deliveryFee": existing.delivery_fee,
                    "pricePerKg": existing.price_per_kg,
                    "pricePerKm": existing.price_per_km,
                    "baseCoefficient": existing.base_coefficient,
                    "version": existing.version,
                }
            }
        else:
            new_pricing = Pricing(
                receiving_fee=data.get("receivingFee", 50.0),
                delivery_fee=data.get("deliveryFee", 100.0),
                price_per_kg=data.get("pricePerKg", 5.0),
                price_per_km=data.get("pricePerKm", 10.0),
                base_coefficient=data.get("baseCoefficient", 1.0),
                version=1,
                is_active=True,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
            )
            db.add(new_pricing)
            db.commit()
            db.refresh(new_pricing)
            return {
                "status": "success",
                "pricing": {
                    "id": new_pricing.id,
                    "receivingFee": new_pricing.receiving_fee,
                    "deliveryFee": new_pricing.delivery_fee,
                    "pricePerKg": new_pricing.price_per_kg,
                    "pricePerKm": new_pricing.price_per_km,
                    "baseCoefficient": new_pricing.base_coefficient,
                    "version": new_pricing.version,
                }
            }
    except Exception as e:
        logger.error(f"❌ Ошибка обновления тарифов: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/directories/x5")
async def update_x5_settings(
    data: Dict[str, Any],
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Обновление X5 настроек"""
    try:
        from app.modules.deliveries.models import X5Settings
        
        existing = db.query(X5Settings).filter(
            X5Settings.is_active == True
        ).order_by(X5Settings.id.desc()).first()
        
        if existing:
            existing.pickup_price = data.get("pickupPrice", 250.0)
            existing.delivery_price = data.get("deliveryPrice", 150.0)
            existing.per_km_price = data.get("perKmPrice", 25.0)
            existing.per_kg_price = data.get("perKgPrice", 10.0)
            existing.version = existing.version + 1
            existing.updated_at = datetime.utcnow()
            db.commit()
            db.refresh(existing)
            return {
                "status": "success",
                "x5Settings": {
                    "id": existing.id,
                    "pickupPrice": existing.pickup_price,
                    "deliveryPrice": existing.delivery_price,
                    "perKmPrice": existing.per_km_price,
                    "perKgPrice": existing.per_kg_price,
                    "version": existing.version,
                }
            }
        else:
            new_x5 = X5Settings(
                pickup_price=data.get("pickupPrice", 250.0),
                delivery_price=data.get("deliveryPrice", 150.0),
                per_km_price=data.get("perKmPrice", 25.0),
                per_kg_price=data.get("perKgPrice", 10.0),
                version=1,
                is_active=True,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
            )
            db.add(new_x5)
            db.commit()
            db.refresh(new_x5)
            return {
                "status": "success",
                "x5Settings": {
                    "id": new_x5.id,
                    "pickupPrice": new_x5.pickup_price,
                    "deliveryPrice": new_x5.delivery_price,
                    "perKmPrice": new_x5.per_km_price,
                    "perKgPrice": new_x5.per_kg_price,
                    "version": new_x5.version,
                }
            }
    except Exception as e:
        logger.error(f"❌ Ошибка обновления X5 настроек: {e}")
        raise HTTPException(status_code=500, detail=str(e))