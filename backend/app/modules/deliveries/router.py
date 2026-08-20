from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Dict, List, Any
from datetime import date, datetime, timezone
import logging

from app.core.database import get_db
from app.modules.users.dependencies import get_current_user
from app.modules.deliveries.models import Shift, Order, Delivery
from sqlalchemy import func

logger = logging.getLogger(__name__)
router = APIRouter()


# ============================================================
# ЭНДПОИНТЫ ДЛЯ ЗАГРУЗКИ ДАННЫХ
# ============================================================

@router.get("/sync/today")
async def get_today_data(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Получение данных за сегодня"""
    try:
        today = date.today()
        
        shifts = db.query(Shift).filter(
            Shift.user_id == current_user.id,
            func.date(Shift.created_at) == today
        ).order_by(Shift.created_at.desc()).all()
        
        orders = db.query(Order).filter(
            Order.user_id == current_user.id,
            func.date(Order.created_at) == today
        ).order_by(Order.created_at.desc()).all()
        
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
                "shopAddress": order.shop_address,
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
                        "tip": d.tip or 0.0,
                        "status": d.status,
                        "isSynced": d.is_synced,
                    }
                    for d in deliveries
                ]
            })
        
        # ===== ВЫЧИСЛЯЕМ ВРЕМЯ ПРОСТОЯ ДЛЯ КАЖДОЙ СМЕНЫ =====
        shifts_data = []
        for s in shifts:
            duration = s.duration_seconds or 0
            order_time = s.total_order_time_seconds or 0
            
            # Если total_order_time не сохранён, вычисляем из доставок
            if order_time == 0 and s.id:
                shift_orders = db.query(Order).filter(Order.shift_id == s.id).all()
                for o in shift_orders:
                    deliveries = db.query(Delivery).filter(Delivery.order_id == o.id).all()
                    if deliveries:
                        first = deliveries[0]
                        order_time += first.time_to_shop + first.time_receiving
                        for d in deliveries:
                            order_time += d.time_to_client + d.time_delivery
            
            # Время простоя = длительность - время на заказах
            idle_time = max(0, duration - order_time)
            
            shifts_data.append({
                "id": s.id,
                "localId": s.local_id,
                "startTime": s.start_time,
                "endTime": s.end_time,
                "durationSeconds": duration,
                "totalPaidDistance": s.total_paid_distance or 0.0,
                "totalIdleDistance": s.total_idle_distance or 0.0,
                "totalOrderTimeSeconds": order_time,
                "ordersCount": s.orders_count or 0,
                "totalIncome": s.total_income or 0.0,
                "totalExpenses": s.total_expenses or 0.0,
                "netProfit": s.net_profit or 0.0,
                "status": s.status,
                "isSynced": s.is_synced,
                "createdAt": s.created_at.isoformat() if s.created_at else None,
                "totalIdleTimeSeconds": idle_time,
                "pausedAt": s.paused_at,
                "resumedAt": s.resumed_at,
            })
        
        return {
            "status": "success",
            "date": today.isoformat(),
            "shifts": shifts_data,
            "orders": orders_data,
        }
    except Exception as e:
        logger.error(f"❌ Ошибка получения данных за сегодня: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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


# ============================================================
# ЭНДПОИНТЫ ДЛЯ УПРАВЛЕНИЯ СМЕНАМИ
# ============================================================

@router.post("/shifts/start")
async def start_shift(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Создать новую приостановленную смену"""
    try:
        existing = db.query(Shift).filter(
            Shift.user_id == current_user.id,
            Shift.status.in_(['active', 'paused'])
        ).first()
        
        if existing:
            return {
                "id": existing.id,
                "startTime": existing.start_time,
                "status": existing.status,
                "totalPaidDistance": existing.total_paid_distance,
                "totalIdleDistance": existing.total_idle_distance,
                "ordersCount": existing.orders_count,
            }

        now = datetime.now(timezone.utc)
        
        shift = Shift(
            user_id=current_user.id,
            start_time=now.isoformat(),
            status='paused',
            total_paid_distance=0.0,
            total_idle_distance=0.0,
            orders_count=0,
            total_income=0.0,
            total_expenses=0.0,
            net_profit=0.0,
            is_synced=True,
            synced_at=now,
            created_at=now,
            updated_at=now
        )
        db.add(shift)
        db.commit()
        db.refresh(shift)
        
        logger.info(f"📅 Создана новая смена id={shift.id}, status={shift.status}")
        
        return {
            "id": shift.id,
            "startTime": shift.start_time,
            "status": shift.status,
            "totalPaidDistance": shift.total_paid_distance,
            "totalIdleDistance": shift.total_idle_distance,
            "ordersCount": shift.orders_count,
        }
    except Exception as e:
        logger.error(f"❌ Ошибка создания смены: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.patch("/shifts/{shift_id}/state")
async def update_shift_state(
    shift_id: int,
    request_data: Dict[str, Any],
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Обновить состояние смены (промежуточное сохранение)"""
    try:
        shift = db.query(Shift).filter(
            Shift.id == shift_id,
            Shift.user_id == current_user.id
        ).first()
        
        if not shift:
            raise HTTPException(status_code=404, detail="Смена не найдена")
        
        now = datetime.now(timezone.utc)
        
        # Обновляем только переданные поля
        if 'totalPaidDistance' in request_data:
            shift.total_paid_distance = request_data['totalPaidDistance']
        if 'totalIdleDistance' in request_data:
            shift.total_idle_distance = request_data['totalIdleDistance']
        if 'totalOrderTimeSeconds' in request_data:
            shift.total_order_time_seconds = request_data['totalOrderTimeSeconds']
        if 'ordersCount' in request_data:
            shift.orders_count = request_data['ordersCount']
        if 'totalIncome' in request_data:
            shift.total_income = request_data['totalIncome']
        if 'totalExpenses' in request_data:
            shift.total_expenses = request_data['totalExpenses']
        if 'netProfit' in request_data:
            shift.net_profit = request_data['netProfit']
        
        # Пересчитываем длительность
        if shift.start_time:
            try:
                start_str = shift.start_time
                if start_str.endswith('Z'):
                    start_str = start_str[:-1] + '+00:00'
                start = datetime.fromisoformat(start_str)
                if start.tzinfo is None:
                    start = start.replace(tzinfo=timezone.utc)
                shift.duration_seconds = int((now - start).total_seconds())
                logger.info(f"📊 Обновлена длительность: {shift.duration_seconds} сек")
            except Exception as e:
                logger.warning(f"⚠️ Ошибка расчёта длительности: {e}")
        
        shift.updated_at = now
        db.commit()
        
        logger.info(f"🔄 Обновлено состояние смены {shift_id}: duration={shift.duration_seconds} сек")
        
        return {"status": "ok", "shift": {"id": shift.id, "durationSeconds": shift.duration_seconds}}
    except Exception as e:
        logger.error(f"❌ Ошибка обновления состояния смены: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/shifts/{shift_id}/pause")
async def pause_shift(
    shift_id: int,
    request_data: Dict[str, Any],
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Приостановить работу"""
    shift = db.query(Shift).filter(
        Shift.id == shift_id,
        Shift.user_id == current_user.id
    ).first()
    
    if not shift:
        raise HTTPException(status_code=404, detail="Смена не найдена")
    
    if shift.status != 'active':
        raise HTTPException(status_code=400, detail="Смена не активна")
    
    now = datetime.now(timezone.utc)
    
    shift.total_paid_distance = request_data.get('totalPaidDistance', 0.0)
    shift.total_idle_distance = request_data.get('totalIdleDistance', 0.0)
    shift.total_order_time_seconds = request_data.get('totalOrderTimeSeconds', 0)
    shift.orders_count = request_data.get('ordersCount', 0)
    shift.total_income = request_data.get('totalIncome', 0.0)
    shift.total_expenses = request_data.get('totalExpenses', 0.0)
    shift.net_profit = request_data.get('netProfit', 0.0)
    
    shift.status = 'paused'
    shift.paused_at = now.isoformat()
    shift.resumed_at = None
    shift.updated_at = now
    
    if shift.start_time:
        try:
            start_str = shift.start_time
            if start_str.endswith('Z'):
                start_str = start_str[:-1] + '+00:00'
            start = datetime.fromisoformat(start_str)
            if start.tzinfo is None:
                start = start.replace(tzinfo=timezone.utc)
            shift.duration_seconds = int((now - start).total_seconds())
        except Exception as e:
            logger.warning(f"⚠️ Ошибка расчёта длительности: {e}")
    
    db.commit()
    
    logger.info(f"⏸️ Смена {shift_id} приостановлена, duration={shift.duration_seconds} сек")
    
    return {"status": "ok", "shift": {"id": shift.id, "status": "paused"}}


@router.post("/shifts/{shift_id}/resume")
async def resume_shift(
    shift_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Возобновить работу"""
    shift = db.query(Shift).filter(
        Shift.id == shift_id,
        Shift.user_id == current_user.id
    ).first()
    
    if not shift:
        raise HTTPException(status_code=404, detail="Смена не найдена")
    
    if shift.status != 'paused':
        raise HTTPException(status_code=400, detail="Смена не приостановлена")
    
    now = datetime.now(timezone.utc)
    
    shift.status = 'active'
    shift.resumed_at = now.isoformat()
    shift.paused_at = None
    shift.updated_at = now
    
    if shift.start_time:
        try:
            start_str = shift.start_time
            if start_str.endswith('Z'):
                start_str = start_str[:-1] + '+00:00'
            start = datetime.fromisoformat(start_str)
            if start.tzinfo is None:
                start = start.replace(tzinfo=timezone.utc)
            shift.duration_seconds = int((now - start).total_seconds())
        except Exception as e:
            logger.warning(f"⚠️ Ошибка расчёта длительности: {e}")
    
    db.commit()
    
    logger.info(f"▶️ Смена {shift_id} возобновлена, duration={shift.duration_seconds} сек")
    
    return {"status": "ok", "shift": {"id": shift.id, "status": "active"}}


@router.post("/shifts/{shift_id}/complete")
async def complete_shift(
    shift_id: int,
    request_data: Dict[str, Any],
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Завершить смену с сохранением статистики"""
    try:
        shift = db.query(Shift).filter(
            Shift.id == shift_id,
            Shift.user_id == current_user.id
        ).first()
        if not shift:
            raise HTTPException(status_code=404, detail="Смена не найдена")
        if shift.status == 'completed':
            raise HTTPException(status_code=400, detail="Смена уже завершена")

        now = datetime.now(timezone.utc)
        
        shift.status = 'completed'
        shift.end_time = now.isoformat()
        shift.paused_at = None
        shift.resumed_at = None
        
        if shift.start_time:
            try:
                start_str = shift.start_time
                if start_str.endswith('Z'):
                    start_str = start_str[:-1] + '+00:00'
                start = datetime.fromisoformat(start_str)
                if start.tzinfo is None:
                    start = start.replace(tzinfo=timezone.utc)
                shift.duration_seconds = int((now - start).total_seconds())
                logger.info(f"📊 Длительность смены: {shift.duration_seconds} сек")
            except Exception as e:
                logger.warning(f"⚠️ Ошибка расчёта длительности: {e}")
                shift.duration_seconds = 0
        
        # ===== ВЫЧИСЛЯЕМ ВРЕМЯ НА ЗАКАЗАХ ИЗ ДОСТАВОК =====
        orders = db.query(Order).filter(
            Order.shift_id == shift_id,
            Order.user_id == current_user.id
        ).all()
        
        total_order_time = 0
        for order in orders:
            deliveries = db.query(Delivery).filter(
                Delivery.order_id == order.id
            ).all()
            
            if deliveries:
                first_delivery = deliveries[0]
                order_time = first_delivery.time_to_shop + first_delivery.time_receiving
                for d in deliveries:
                    order_time += d.time_to_client + d.time_delivery
                total_order_time += order_time
        
        logger.info(f"📊 Время на заказах: {total_order_time} сек")
        
        shift.total_paid_distance = request_data.get('totalPaidDistance', shift.total_paid_distance or 0.0)
        shift.total_idle_distance = request_data.get('totalIdleDistance', shift.total_idle_distance or 0.0)
        shift.total_order_time_seconds = total_order_time
        shift.orders_count = request_data.get('ordersCount', shift.orders_count or 0)
        shift.total_income = request_data.get('totalIncome', shift.total_income or 0.0)
        shift.total_expenses = request_data.get('totalExpenses', shift.total_expenses or 0.0)
        shift.net_profit = request_data.get('netProfit', shift.net_profit or 0.0)
        
        shift.updated_at = now
        db.commit()
        db.refresh(shift)
        
        logger.info(f"✅ Смена завершена: id={shift_id}")
        logger.info(f"📊 duration={shift.duration_seconds} сек, заказов={shift.orders_count}, доход={shift.total_income}, холостой пробег={shift.total_idle_distance}")
        
        return {
            "status": "ok",
            "shift": {
                "id": shift.id,
                "status": "completed",
                "durationSeconds": shift.duration_seconds,
                "totalPaidDistance": shift.total_paid_distance,
                "totalIdleDistance": shift.total_idle_distance,
                "totalOrderTimeSeconds": shift.total_order_time_seconds,
                "ordersCount": shift.orders_count,
                "totalIncome": shift.total_income,
                "totalExpenses": shift.total_expenses,
                "netProfit": shift.net_profit,
                "pausedAt": shift.paused_at,
                "resumedAt": shift.resumed_at,
            }
        }
    except Exception as e:
        logger.error(f"❌ Ошибка завершения смены: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# ЭНДПОИНТЫ ДЛЯ ЗАКАЗОВ С ДОСТАВКАМИ
# ============================================================

@router.post("/orders")
async def create_order(
    data: Dict[str, Any],
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Создать новый заказ с доставками"""
    try:
        shift = db.query(Shift).filter(
            Shift.user_id == current_user.id,
            Shift.status == 'active'
        ).first()
        if not shift:
            raise HTTPException(status_code=400, detail="Нет активной смены")

        now = datetime.now(timezone.utc)
        
        order = Order(
            user_id=current_user.id,
            shift_id=shift.id,
            service_name=data.get("serviceName", "Заказ"),
            coefficient=data.get("coefficient", 1.0),
            delivery_number=data.get("deliveryNumber", 1),
            total_paid_distance=data.get("totalPaidDistance", 0.0),
            total_income=data.get("totalIncome", 0.0),
            total_expenses=data.get("totalExpenses", 0.0),
            net_profit=data.get("netProfit", 0.0),
            total_time_seconds=data.get("totalTimeSeconds", 0),
            shop_address=data.get("shopAddress", ""),
            status='active',
            is_synced=True,
            synced_at=now,
            created_at=now,
            updated_at=now
        )
        db.add(order)
        db.commit()
        db.refresh(order)

        deliveries_data = data.get("deliveries", [])
        for d_data in deliveries_data:
            delivery = Delivery(
                order_id=order.id,
                number=d_data.get("number", 0),
                client_address=d_data.get("clientAddress", ""),
                apartment=d_data.get("apartment", ""),
                weight=d_data.get("weight", 0.0),
                time_to_shop=d_data.get("timeToShop", 0),
                distance_to_shop=d_data.get("distanceToShop", 0.0),
                time_receiving=d_data.get("timeReceiving", 0),
                time_to_client=d_data.get("timeToClient", 0),
                distance_to_client=d_data.get("distanceToClient", 0.0),
                time_delivery=d_data.get("timeDelivery", 0),
                tip=d_data.get("tip", 0.0),
                status='completed',
                is_synced=True,
                synced_at=now,
                created_at=now,
                updated_at=now
            )
            db.add(delivery)
        
        shift.orders_count += 1
        shift.total_income += order.total_income
        shift.total_expenses += order.total_expenses
        shift.net_profit += order.net_profit
        shift.total_paid_distance += order.total_paid_distance
        shift.updated_at = now
        db.commit()

        logger.info(f"✅ Заказ создан: id={order.id}, доставок={len(deliveries_data)}, shopAddress={order.shop_address}")

        return {
            "id": order.id,
            "shiftId": order.shift_id,
            "serviceName": order.service_name,
            "coefficient": order.coefficient,
            "deliveryNumber": order.delivery_number,
            "totalPaidDistance": order.total_paid_distance,
            "totalIncome": order.total_income,
            "totalExpenses": order.total_expenses,
            "netProfit": order.net_profit,
            "totalTimeSeconds": order.total_time_seconds,
            "shopAddress": order.shop_address,
            "status": order.status,
        }
    except Exception as e:
        logger.error(f"❌ Ошибка создания заказа: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/orders/{order_id}/complete")
async def complete_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Завершить заказ"""
    try:
        order = db.query(Order).filter(
            Order.id == order_id,
            Order.user_id == current_user.id
        ).first()
        if not order:
            raise HTTPException(status_code=404, detail="Заказ не найден")
        if order.status == 'completed':
            raise HTTPException(status_code=400, detail="Заказ уже завершён")

        now = datetime.now(timezone.utc)
        order.status = 'completed'
        order.updated_at = now
        db.commit()
        db.refresh(order)

        shift = db.query(Shift).filter(Shift.id == order.shift_id).first()
        if shift:
            shift.updated_at = now
            db.commit()

        return {"status": "ok", "order": {"id": order.id, "status": "completed"}}
    except Exception as e:
        logger.error(f"❌ Ошибка завершения заказа: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# ЭНДПОИНТЫ ДЛЯ СПРАВОЧНИКОВ
# ============================================================

@router.post("/directories/settings")
async def update_settings(
    data: Dict[str, Any],
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Обновление настроек"""
    try:
        from app.modules.deliveries.models import Settings
        
        now = datetime.now(timezone.utc)
        existing = db.query(Settings).filter(
            Settings.is_active == True
        ).order_by(Settings.id.desc()).first()
        
        if existing:
            existing.fuel_consumption = data.get("fuelConsumption", 10.0)
            existing.fuel_price = data.get("fuelPrice", 50.0)
            existing.repair_cost = data.get("repairCost", 2.0)
            existing.additional_costs = data.get("additionalCosts", 0.0)
            existing.version = existing.version + 1
            existing.updated_at = now
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
                created_at=now,
                updated_at=now,
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
        
        now = datetime.now(timezone.utc)
        existing = db.query(Pricing).filter(
            Pricing.is_active == True
        ).order_by(Pricing.id.desc()).first()
        
        if existing:
            existing.receiving_fee = data.get("receivingFee", 50.0)
            existing.delivery_fee = data.get("deliveryFee", 100.0)
            existing.price_per_kg = data.get("pricePerKg", 5.0)
            existing.price_per_km = data.get("pricePerKm", 10.0)
            existing.base_coefficient = data.get("baseCoefficient", 1.0)
            existing.version = existing.version + 1
            existing.updated_at = now
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
                created_at=now,
                updated_at=now,
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
        
        now = datetime.now(timezone.utc)
        existing = db.query(X5Settings).filter(
            X5Settings.is_active == True
        ).order_by(X5Settings.id.desc()).first()
        
        if existing:
            existing.pickup_price = data.get("pickupPrice", 250.0)
            existing.delivery_price = data.get("deliveryPrice", 150.0)
            existing.per_km_price = data.get("perKmPrice", 25.0)
            existing.per_kg_price = data.get("perKgPrice", 10.0)
            existing.version = existing.version + 1
            existing.updated_at = now
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
                created_at=now,
                updated_at=now,
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