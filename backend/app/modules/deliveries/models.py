from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from app.core.database import Base


class Shift(Base):
    __tablename__ = "shifts"
    
    id = Column(Integer, primary_key=True, index=True)
    local_id = Column(Integer, nullable=True)
    user_id = Column(Integer, nullable=True)
    
    start_time = Column(String, nullable=True)
    end_time = Column(String, nullable=True)
    duration_seconds = Column(Integer, default=0)
    total_paid_distance = Column(Float, default=0)
    total_idle_distance = Column(Float, default=0)
    total_order_time_seconds = Column(Integer, default=0)
    orders_count = Column(Integer, default=0)
    total_income = Column(Float, default=0)
    total_expenses = Column(Float, default=0)
    net_profit = Column(Float, default=0)
    status = Column(String, default="active")
    
    is_synced = Column(Boolean, default=False)
    synced_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    orders = relationship("Order", back_populates="shift", cascade="all, delete-orphan")


class Order(Base):
    __tablename__ = "orders"
    
    id = Column(Integer, primary_key=True, index=True)
    local_id = Column(Integer, nullable=True)
    user_id = Column(Integer, nullable=True)
    shift_id = Column(Integer, ForeignKey("shifts.id"), nullable=True)
    
    service_name = Column(String, nullable=True)
    coefficient = Column(Float, default=1.0)
    delivery_number = Column(Integer, default=1)
    total_paid_distance = Column(Float, default=0)
    total_income = Column(Float, default=0)
    total_expenses = Column(Float, default=0)
    net_profit = Column(Float, default=0)
    total_time_seconds = Column(Integer, default=0)
    status = Column(String, default="active")
    
    is_synced = Column(Boolean, default=False)
    synced_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    shift = relationship("Shift", back_populates="orders")
    deliveries = relationship("Delivery", back_populates="order", cascade="all, delete-orphan")


class Delivery(Base):
    __tablename__ = "deliveries"
    
    id = Column(Integer, primary_key=True, index=True)
    local_id = Column(Integer, nullable=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=True)
    
    number = Column(Integer, default=0)
    client_address = Column(String, nullable=True)
    apartment = Column(String, nullable=True)
    weight = Column(Float, default=0)
    time_to_shop = Column(Integer, default=0)
    distance_to_shop = Column(Float, default=0)
    time_receiving = Column(Integer, default=0)
    time_to_client = Column(Integer, default=0)
    distance_to_client = Column(Float, default=0)
    time_delivery = Column(Integer, default=0)
    status = Column(String, default="active")
    
    is_synced = Column(Boolean, default=False)
    synced_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    order = relationship("Order", back_populates="deliveries")


# ============================================================
# НОВЫЕ МОДЕЛИ ДЛЯ СПРАВОЧНИКОВ
# ============================================================

class Settings(Base):
    __tablename__ = "settings"
    
    id = Column(Integer, primary_key=True, index=True)
    fuel_consumption = Column(Float, default=10.0)
    fuel_price = Column(Float, default=50.0)
    repair_cost = Column(Float, default=2.0)
    additional_costs = Column(Float, default=0.0)
    version = Column(Integer, default=1)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Pricing(Base):
    __tablename__ = "pricing"
    
    id = Column(Integer, primary_key=True, index=True)
    receiving_fee = Column(Float, default=50.0)
    delivery_fee = Column(Float, default=100.0)
    price_per_kg = Column(Float, default=5.0)
    price_per_km = Column(Float, default=10.0)
    base_coefficient = Column(Float, default=1.0)
    version = Column(Integer, default=1)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class X5Settings(Base):
    __tablename__ = "x5_settings"
    
    id = Column(Integer, primary_key=True, index=True)
    pickup_price = Column(Float, default=250.0)
    delivery_price = Column(Float, default=150.0)
    per_km_price = Column(Float, default=25.0)
    per_kg_price = Column(Float, default=10.0)
    version = Column(Integer, default=1)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)