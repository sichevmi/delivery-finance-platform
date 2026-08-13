from sqlalchemy.orm import Session
from sqlalchemy import select
from datetime import datetime
import logging
from typing import List, Dict, Any, Optional

from app.modules.deliveries.models import Shift, Order, Delivery

logger = logging.getLogger(__name__)


class DeliveryService:
    def __init__(self, db: Session):
        self.db = db

    # ===== СИНХРОНИЗАЦИЯ =====

    async def sync_shifts(self, shifts_data: List[Dict], user_id: int) -> List[Dict]:
        """Синхронизация смен с мобильного приложения"""
        result = []
        for shift_data in shifts_data:
            local_id = shift_data.get("localId")
            
            # Ищем существующую смену
            existing = self.db.query(Shift).filter(
                Shift.local_id == local_id,
                Shift.user_id == user_id
            ).first()

            if existing:
                # Обновляем существующую
                existing.start_time = shift_data.get("startTime")
                existing.end_time = shift_data.get("endTime")
                existing.duration_seconds = shift_data.get("durationSeconds", 0)
                existing.total_paid_distance = shift_data.get("totalPaidDistance", 0)
                existing.total_idle_distance = shift_data.get("totalIdleDistance", 0)
                existing.total_order_time_seconds = shift_data.get("totalOrderTimeSeconds", 0)
                existing.orders_count = shift_data.get("ordersCount", 0)
                existing.total_income = shift_data.get("totalIncome", 0)
                existing.total_expenses = shift_data.get("totalExpenses", 0)
                existing.net_profit = shift_data.get("netProfit", 0)
                existing.status = shift_data.get("status", "completed")
                existing.is_synced = True
                existing.synced_at = datetime.utcnow()
                existing.updated_at = datetime.utcnow()
                
                self.db.commit()
                result.append({"localId": local_id, "serverId": existing.id})
                logger.info(f"✅ Смена {local_id} обновлена (serverId={existing.id})")
            else:
                # Создаём новую
                new_shift = Shift(
                    local_id=local_id,
                    user_id=user_id,
                    start_time=shift_data.get("startTime"),
                    end_time=shift_data.get("endTime"),
                    duration_seconds=shift_data.get("durationSeconds", 0),
                    total_paid_distance=shift_data.get("totalPaidDistance", 0),
                    total_idle_distance=shift_data.get("totalIdleDistance", 0),
                    total_order_time_seconds=shift_data.get("totalOrderTimeSeconds", 0),
                    orders_count=shift_data.get("ordersCount", 0),
                    total_income=shift_data.get("totalIncome", 0),
                    total_expenses=shift_data.get("totalExpenses", 0),
                    net_profit=shift_data.get("netProfit", 0),
                    status=shift_data.get("status", "completed"),
                    is_synced=True,
                    synced_at=datetime.utcnow(),
                    created_at=datetime.utcnow(),
                    updated_at=datetime.utcnow()
                )
                self.db.add(new_shift)
                self.db.commit()
                self.db.refresh(new_shift)
                result.append({"localId": local_id, "serverId": new_shift.id})
                logger.info(f"✅ Смена {local_id} создана (serverId={new_shift.id})")

        return result

    async def sync_orders(self, orders_data: List[Dict], user_id: int) -> List[Dict]:
        """Синхронизация заказов с доставками"""
        result = []
        for order_data in orders_data:
            local_id = order_data.get("localId")
            shift_local_id = order_data.get("shiftId")
            
            # Находим смену по local_id
            shift = self.db.query(Shift).filter(
                Shift.local_id == shift_local_id,
                Shift.user_id == user_id
            ).first()
            
            if not shift:
                logger.warning(f"⚠️ Смена {shift_local_id} не найдена для пользователя {user_id}")
                continue

            # Ищем существующий заказ
            existing = self.db.query(Order).filter(
                Order.local_id == local_id,
                Order.user_id == user_id
            ).first()

            if existing:
                # Обновляем заказ
                existing.service_name = order_data.get("serviceName")
                existing.coefficient = order_data.get("coefficient", 1.0)
                existing.delivery_number = order_data.get("deliveryNumber", 1)
                existing.total_paid_distance = order_data.get("totalPaidDistance", 0)
                existing.total_income = order_data.get("totalIncome", 0)
                existing.total_expenses = order_data.get("totalExpenses", 0)
                existing.net_profit = order_data.get("netProfit", 0)
                existing.total_time_seconds = order_data.get("totalTimeSeconds", 0)
                existing.shift_id = shift.id
                existing.is_synced = True
                existing.synced_at = datetime.utcnow()
                existing.updated_at = datetime.utcnow()
                existing.status = "completed"
                
                self.db.commit()
                order_id = existing.id
                logger.info(f"✅ Заказ {local_id} обновлён (serverId={order_id})")
            else:
                # Создаём новый заказ
                new_order = Order(
                    local_id=local_id,
                    user_id=user_id,
                    shift_id=shift.id,
                    service_name=order_data.get("serviceName", "Заказ"),
                    coefficient=order_data.get("coefficient", 1.0),
                    delivery_number=order_data.get("deliveryNumber", 1),
                    total_paid_distance=order_data.get("totalPaidDistance", 0),
                    total_income=order_data.get("totalIncome", 0),
                    total_expenses=order_data.get("totalExpenses", 0),
                    net_profit=order_data.get("netProfit", 0),
                    total_time_seconds=order_data.get("totalTimeSeconds", 0),
                    is_synced=True,
                    synced_at=datetime.utcnow(),
                    created_at=datetime.utcnow(),
                    updated_at=datetime.utcnow(),
                    status="completed"
                )
                self.db.add(new_order)
                self.db.commit()
                self.db.refresh(new_order)
                order_id = new_order.id
                logger.info(f"✅ Заказ {local_id} создан (serverId={order_id})")

            # Синхронизируем доставки
            for delivery_data in order_data.get("deliveries", []):
                await self._sync_delivery(delivery_data, order_id)

            result.append({"localId": local_id, "serverId": order_id})

        return result

    async def _sync_delivery(self, delivery_data: Dict, order_id: int):
        """Синхронизация доставки"""
        local_id = delivery_data.get("localId")
        
        existing = self.db.query(Delivery).filter(
            Delivery.local_id == local_id,
            Delivery.order_id == order_id
        ).first()

        if existing:
            # Обновляем доставку
            existing.number = delivery_data.get("number", 0)
            existing.client_address = delivery_data.get("clientAddress", "")
            existing.apartment = delivery_data.get("apartment", "")
            existing.weight = delivery_data.get("weight", 0)
            existing.time_to_shop = delivery_data.get("timeToShop", 0)
            existing.distance_to_shop = delivery_data.get("distanceToShop", 0)
            existing.time_receiving = delivery_data.get("timeReceiving", 0)
            existing.time_to_client = delivery_data.get("timeToClient", 0)
            existing.distance_to_client = delivery_data.get("distanceToClient", 0)
            existing.time_delivery = delivery_data.get("timeDelivery", 0)
            existing.is_synced = True
            existing.synced_at = datetime.utcnow()
            existing.updated_at = datetime.utcnow()
            
            self.db.commit()
            logger.info(f"✅ Доставка {local_id} обновлена")
        else:
            # Создаём новую доставку
            new_delivery = Delivery(
                local_id=local_id,
                order_id=order_id,
                number=delivery_data.get("number", 0),
                client_address=delivery_data.get("clientAddress", ""),
                apartment=delivery_data.get("apartment", ""),
                weight=delivery_data.get("weight", 0),
                time_to_shop=delivery_data.get("timeToShop", 0),
                distance_to_shop=delivery_data.get("distanceToShop", 0),
                time_receiving=delivery_data.get("timeReceiving", 0),
                time_to_client=delivery_data.get("timeToClient", 0),
                distance_to_client=delivery_data.get("distanceToClient", 0),
                time_delivery=delivery_data.get("timeDelivery", 0),
                is_synced=True,
                synced_at=datetime.utcnow(),
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            self.db.add(new_delivery)
            self.db.commit()
            logger.info(f"✅ Доставка {local_id} создана")

    async def sync_settings(self, settings_data: Dict, user_id: int) -> Dict:
        """Синхронизация настроек"""
        # Здесь логика сохранения настроек
        # Зависит от вашей модели настроек
        return {"status": "success", "version": 1, "synced_at": datetime.utcnow().isoformat()}