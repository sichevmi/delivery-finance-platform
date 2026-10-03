from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional
import calendar
import logging

from app.core.database import get_db
from app.modules.users.dependencies import get_current_user
from app.modules.deliveries.models import Order, Shift, Delivery

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/analytics", tags=["analytics"])

MONTH_SHORT = ["Янв", "Фев", "Мар", "Апр", "Май", "Июн",
               "Июл", "Авг", "Сен", "Окт", "Ноя", "Дек"]


def _month_bounds(year: int, month: int):
    start = datetime(year, month, 1)
    end = datetime(year + 1, 1, 1) if month == 12 else datetime(year, month + 1, 1)
    return start, end


def _day_bounds(year: int, month: int, day: int):
    start = datetime(year, month, day)
    days_in_month = calendar.monthrange(year, month)[1]
    if day < days_in_month:
        end = datetime(year, month, day + 1)
    else:
        end = datetime(year + 1, 1, 1) if month == 12 else datetime(year, month + 1, 1)
    return start, end


def _summary_from_shifts(shifts) -> dict:
    """Сводка по сменам: только total_income и оба пробега."""
    total_income = sum((s.total_income or 0.0) for s in shifts)
    total_paid = sum((s.total_paid_distance or 0.0) for s in shifts)
    total_idle = sum((s.total_idle_distance or 0.0) for s in shifts)
    total_distance = total_paid + total_idle
    total_orders = sum((s.orders_count or 0) for s in shifts)
    total_time = sum((s.duration_seconds or 0) for s in shifts)

    return {
        "totalIncome": round(total_income, 2),
        "totalDistance": round(total_distance, 2),
        "totalOrders": total_orders,
        "totalTimeSeconds": total_time,
    }


@router.get("")
async def get_analytics(
    year: int = Query(...),
    month: Optional[int] = Query(None),
    day: Optional[int] = Query(None),
    period: str = Query("year"),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    try:
        if period == "year":
            return _year_data(db, current_user.id, year)
        if period == "month":
            if month is None:
                raise HTTPException(400, "month is required")
            return _month_data(db, current_user.id, year, month)
        if period == "day":
            if month is None or day is None:
                raise HTTPException(400, "month and day are required")
            return _day_data(db, current_user.id, year, month, day)
        raise HTTPException(400, f"Unknown period: {period}")
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("Analytics error")
        raise HTTPException(500, str(e))


# ============================================================
# YEAR
# ============================================================

def _year_data(db: Session, user_id: int, year: int) -> dict:
    start = datetime(year, 1, 1)
    end = datetime(year + 1, 1, 1)

    shifts = (
        db.query(Shift)
        .filter(
            Shift.user_id == user_id,
            Shift.created_at >= start,
            Shift.created_at < end,
        )
        .all()
    )

    # Итоговая сводка по всем сменам за год
    summary = _summary_from_shifts(shifts)

    # График и плашки — по месяцам
    month_buckets = {m: {"income": 0.0, "orders": 0} for m in range(1, 13)}
    for s in shifts:
        if not s.created_at:
            continue
        m = s.created_at.month
        month_buckets[m]["income"] += (s.total_income or 0.0)
        month_buckets[m]["orders"] += (s.orders_count or 0)

    chart_points = []
    period_tiles = []
    for m in range(1, 13):
        b = month_buckets[m]
        chart_points.append({
            "label": MONTH_SHORT[m - 1],
            "value": round(b["income"], 2),
            "ordersCount": b["orders"],
        })
        period_tiles.append({
            "title": MONTH_SHORT[m - 1],
            "profit": round(b["income"], 2),
            "ordersCount": b["orders"],
            "startDate": datetime(year, m, 1).isoformat(),
            "endDate": (
                datetime(year + 1, 1, 1) if m == 12 else datetime(year, m + 1, 1)
            ).isoformat(),
        })

    return {
        "summary": summary,
        "chartPoints": chart_points,
        "periodTiles": period_tiles,
    }


# ============================================================
# MONTH
# ============================================================

def _month_data(db: Session, user_id: int, year: int, month: int) -> dict:
    start, end = _month_bounds(year, month)

    shifts = (
        db.query(Shift)
        .filter(
            Shift.user_id == user_id,
            Shift.created_at >= start,
            Shift.created_at < end,
        )
        .all()
    )

    summary = _summary_from_shifts(shifts)

    days_in_month = calendar.monthrange(year, month)[1]
    day_buckets = {d: {"income": 0.0, "orders": 0} for d in range(1, days_in_month + 1)}
    for s in shifts:
        if not s.created_at:
            continue
        d = s.created_at.day
        if d in day_buckets:
            day_buckets[d]["income"] += (s.total_income or 0.0)
            day_buckets[d]["orders"] += (s.orders_count or 0)

    chart_points = []
    period_tiles = []
    for d in range(1, days_in_month + 1):
        b = day_buckets[d]
        chart_points.append({
            "label": str(d),
            "value": round(b["income"], 2),
            "ordersCount": b["orders"],
        })
        period_tiles.append({
            "title": f"{d} {MONTH_SHORT[month - 1]}",
            "profit": round(b["income"], 2),
            "ordersCount": b["orders"],
            "startDate": datetime(year, month, d).isoformat(),
            "endDate": (
                datetime(year, month, d + 1) if d < days_in_month
                else end
            ).isoformat(),
        })

    return {
        "summary": summary,
        "chartPoints": chart_points,
        "periodTiles": period_tiles,
    }


# ============================================================
# DAY
# ============================================================

def _day_data(db: Session, user_id: int, year: int, month: int, day: int) -> dict:
    start, end = _day_bounds(year, month, day)

    # Сводка за день — по сменам
    shifts = (
        db.query(Shift)
        .filter(
            Shift.user_id == user_id,
            Shift.created_at >= start,
            Shift.created_at < end,
        )
        .all()
    )
    summary = _summary_from_shifts(shifts)

    # Плашки — по заказам за день
    orders = (
        db.query(Order)
        .filter(
            Order.user_id == user_id,
            Order.created_at >= start,
            Order.created_at < end,
        )
        .order_by(Order.created_at.desc())
        .all()
    )

    period_tiles = []
    for o in orders:
        # Кол-во доставок
        deliveries_count = (
            db.query(Delivery).filter(Delivery.order_id == o.id).count()
        )

        period_tiles.append({
            "orderId": o.id,
            "serviceName": o.service_name or "Заказ",
            "profit": round(o.total_income or 0.0, 2),
            "deliveriesCount": deliveries_count,
            "startDate": o.created_at.isoformat() if o.created_at else None,
            "endDate": o.created_at.isoformat() if o.created_at else None,
        })

    return {
        "summary": summary,
        "chartPoints": [],  # за день график не показываем
        "periodTiles": period_tiles,
    }


# ============================================================
# ORDER DETAILS
# ============================================================

@router.get("/order/{order_id}")
async def get_order_details(
    order_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """Полная информация о заказе для страницы деталей."""
    order = (
        db.query(Order)
        .filter(Order.id == order_id, Order.user_id == current_user.id)
        .first()
    )
    if not order:
        raise HTTPException(404, "Заказ не найден")

    deliveries = (
        db.query(Delivery).filter(Delivery.order_id == order.id).all()
    )

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
        "createdAt": order.created_at.isoformat() if order.created_at else None,
        "deliveries": [
            {
                "id": d.id,
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
                "tip": d.tip,
                "status": d.status,
            }
            for d in deliveries
        ],
    }