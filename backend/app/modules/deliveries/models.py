from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from app.core.database import Base


class Shift(Base):
    __tablename__ = "shifts"
    
    id = Column(Integer, primary_key=True, index=True)
    local_id = Column(Integer, nullable=True)  # ID из мобильного приложения
    user_id = Column(Integer, nullable=True)   # ForeignKey("users.id")
    
    start_time = Column(String, nullable=True)
    end_time = Column(String, nullable=True)
    duration_seconds = Column(Integer, default=0)
    total_paid_distance = Column(Float, default=0)
    total_idle_distance = Column(Float, default=0)
    total_order_time_seconds = Column(Integer, default=0)  # Добавляем
    orders_count = Column(Integer, default=0)
    total_income = Column(Float, default=0)
    total_expenses = Column(Float, default=0)
    net_profit = Column(Float, default=0)
    status = Column(String, default="active")
    
    # Поля для синхронизации
    is_synced = Column(Boolean, default=False)
    synced_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Связи
    orders = relationship("Order", back_populates="shift", cascade="all, delete-orphan")


class Order(Base):
    __tablename__ = "orders"
    
    id = Column(Integer, primary_key=True, index=True)
    local_id = Column(Integer, nullable=True)  # ID из мобильного приложения
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
    
    # Поля для синхронизации
    is_synced = Column(Boolean, default=False)
    synced_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Связи
    shift = relationship("Shift", back_populates="orders")
    deliveries = relationship("Delivery", back_populates="order", cascade="all, delete-orphan")


class Delivery(Base):
    __tablename__ = "deliveries"
    
    id = Column(Integer, primary_key=True, index=True)
    local_id = Column(Integer, nullable=True)  # ID из мобильного приложения
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
    
    # Поля для синхронизации
    is_synced = Column(Boolean, default=False)
    synced_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Связи
    order = relationship("Order", back_populates="deliveries")