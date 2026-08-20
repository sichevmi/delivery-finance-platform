# app/modules/deliveries/models.py

from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, ForeignKey, Text, Numeric
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
    total_paid_distance = Column(Numeric(10, 2), default=0.0)  # 2 знака
    total_idle_distance = Column(Numeric(10, 2), default=0.0)  # 2 знака
    total_order_time_seconds = Column(Integer, default=0)
    orders_count = Column(Integer, default=0)
    total_income = Column(Numeric(10, 2), default=0.0)         # 2 знака
    total_expenses = Column(Numeric(10, 2), default=0.0)       # 2 знака
    net_profit = Column(Numeric(10, 2), default=0.0)           # 2 знака
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
    coefficient = Column(Numeric(5, 2), default=1.0)           # 2 знака
    delivery_number = Column(Integer, default=1)
    total_paid_distance = Column(Numeric(10, 2), default=0.0)  # 2 знака
    total_income = Column(Numeric(10, 2), default=0.0)         # 2 знака
    total_expenses = Column(Numeric(10, 2), default=0.0)       # 2 знака
    net_profit = Column(Numeric(10, 2), default=0.0)           # 2 знака
    total_time_seconds = Column(Integer, default=0)
    shop_address = Column(String(500), nullable=True)
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
    weight = Column(Numeric(8, 2), default=0.0)                # 2 знака
    time_to_shop = Column(Integer, default=0)
    distance_to_shop = Column(Numeric(8, 2), default=0.0)      # 2 знака
    time_receiving = Column(Integer, default=0)
    time_to_client = Column(Integer, default=0)
    distance_to_client = Column(Numeric(8, 2), default=0.0)    # 2 знака
    time_delivery = Column(Integer, default=0)
    tip = Column(Numeric(8, 2), default=0.0)                  # 2 знака
    status = Column(String, default="active")
    
    is_synced = Column(Boolean, default=False)
    synced_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    order = relationship("Order", back_populates="deliveries")


# ============================================================
# СПРАВОЧНИКИ
# ============================================================

class Settings(Base):
    __tablename__ = "settings"
    
    id = Column(Integer, primary_key=True, index=True)
    fuel_consumption = Column(Numeric(6, 2), default=10.0)     # 2 знака
    fuel_price = Column(Numeric(10, 2), default=50.0)         # 2 знака
    repair_cost = Column(Numeric(8, 2), default=2.0)          # 2 знака
    additional_costs = Column(Numeric(10, 2), default=0.0)    # 2 знака
    version = Column(Integer, default=1)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Pricing(Base):
    __tablename__ = "pricing"
    
    id = Column(Integer, primary_key=True, index=True)
    receiving_fee = Column(Numeric(10, 2), default=50.0)      # 2 знака
    delivery_fee = Column(Numeric(10, 2), default=100.0)      # 2 знака
    price_per_kg = Column(Numeric(8, 2), default=5.0)         # 2 знака
    price_per_km = Column(Numeric(8, 2), default=10.0)        # 2 знака
    base_coefficient = Column(Numeric(5, 2), default=1.0)     # 2 знака
    version = Column(Integer, default=1)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class X5Settings(Base):
    __tablename__ = "x5_settings"
    
    id = Column(Integer, primary_key=True, index=True)
    pickup_price = Column(Numeric(10, 2), default=250.0)      # 2 знака
    delivery_price = Column(Numeric(10, 2), default=150.0)    # 2 знака
    per_km_price = Column(Numeric(8, 2), default=25.0)        # 2 знака
    per_kg_price = Column(Numeric(8, 2), default=10.0)        # 2 знака
    version = Column(Integer, default=1)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)