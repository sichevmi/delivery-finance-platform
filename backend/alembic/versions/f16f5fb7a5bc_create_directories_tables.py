"""create_directories_tables

Revision ID: xxxx (замените на реальный ID)
Revises: 0001
Create Date: 2026-08-14 07:53:41.798056

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'xxxx'  # ← ЗАМЕНИТЕ НА РЕАЛЬНЫЙ ID
down_revision: Union[str, None] = '0001'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ===== 1. СОЗДАЁМ ТАБЛИЦЫ (ЕСЛИ ИХ НЕТ) =====
    
    # Таблица settings
    op.execute("""
        CREATE TABLE IF NOT EXISTS settings (
            id SERIAL PRIMARY KEY,
            fuel_consumption FLOAT DEFAULT 10.0,
            fuel_price FLOAT DEFAULT 50.0,
            repair_cost FLOAT DEFAULT 2.0,
            additional_costs FLOAT DEFAULT 0.0,
            name VARCHAR DEFAULT 'Стандартные',
            is_active BOOLEAN DEFAULT TRUE,
            is_default BOOLEAN DEFAULT FALSE,
            version INTEGER DEFAULT 1,
            is_synced BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT NOW(),
            updated_at TIMESTAMP
        )
    """)
    
    # Таблица pricing
    op.execute("""
        CREATE TABLE IF NOT EXISTS pricing (
            id SERIAL PRIMARY KEY,
            receiving_fee FLOAT DEFAULT 50.0,
            delivery_fee FLOAT DEFAULT 100.0,
            price_per_kg FLOAT DEFAULT 5.0,
            price_per_km FLOAT DEFAULT 10.0,
            base_coefficient FLOAT DEFAULT 1.0,
            name VARCHAR DEFAULT 'Стандартный',
            is_active BOOLEAN DEFAULT TRUE,
            is_default BOOLEAN DEFAULT FALSE,
            version INTEGER DEFAULT 1,
            is_synced BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT NOW(),
            updated_at TIMESTAMP
        )
    """)
    
    # Таблица x5_settings
    op.execute("""
        CREATE TABLE IF NOT EXISTS x5_settings (
            id SERIAL PRIMARY KEY,
            pickup_price FLOAT DEFAULT 250.0,
            delivery_price FLOAT DEFAULT 150.0,
            per_km_price FLOAT DEFAULT 25.0,
            per_kg_price FLOAT DEFAULT 10.0,
            is_default BOOLEAN DEFAULT TRUE,
            is_active BOOLEAN DEFAULT TRUE,
            is_synced BOOLEAN DEFAULT FALSE,
            version INTEGER DEFAULT 1,
            created_at TIMESTAMP DEFAULT NOW(),
            updated_at TIMESTAMP
        )
    """)
    
    # ===== 2. ДОБАВЛЯЕМ ПОЛЯ (ЕСЛИ ИХ НЕТ) =====
    
    # Добавляем поля в settings (только если их нет)
    op.execute("""
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                           WHERE table_name='settings' AND column_name='version') THEN
                ALTER TABLE settings ADD COLUMN version INTEGER DEFAULT 1;
            END IF;
            
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                           WHERE table_name='settings' AND column_name='is_synced') THEN
                ALTER TABLE settings ADD COLUMN is_synced BOOLEAN DEFAULT FALSE;
            END IF;
        END
        $$;
    """)
    
    # Добавляем поля в pricing (только если их нет)
    op.execute("""
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                           WHERE table_name='pricing' AND column_name='version') THEN
                ALTER TABLE pricing ADD COLUMN version INTEGER DEFAULT 1;
            END IF;
            
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                           WHERE table_name='pricing' AND column_name='is_synced') THEN
                ALTER TABLE pricing ADD COLUMN is_synced BOOLEAN DEFAULT FALSE;
            END IF;
        END
        $$;
    """)
    
    # Добавляем поля в x5_settings (только если их нет)
    op.execute("""
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                           WHERE table_name='x5_settings' AND column_name='version') THEN
                ALTER TABLE x5_settings ADD COLUMN version INTEGER DEFAULT 1;
            END IF;
            
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                           WHERE table_name='x5_settings' AND column_name='is_synced') THEN
                ALTER TABLE x5_settings ADD COLUMN is_synced BOOLEAN DEFAULT FALSE;
            END IF;
        END
        $$;
    """)


def downgrade() -> None:
    # ===== УДАЛЯЕМ ТАБЛИЦЫ =====
    op.execute("DROP TABLE IF EXISTS x5_settings CASCADE")
    op.execute("DROP TABLE IF EXISTS pricing CASCADE")
    op.execute("DROP TABLE IF EXISTS settings CASCADE")