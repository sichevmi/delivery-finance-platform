"""change_decimal_precision_to_2

Revision ID: 4a721d841b35
Revises: bf2f8f925a6f
Create Date: 2026-08-20 07:58:32.684270

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import NUMERIC  # <-- ДОБАВЛЯЕМ ЭТОТ ИМПОРТ


# revision identifiers, used by Alembic.
revision: str = '4a721d841b35'
down_revision: Union[str, None] = 'bf2f8f925a6f'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ===== SHIFTS =====
    op.alter_column('shifts', 'total_paid_distance',
                    type_=NUMERIC(10, 2),
                    existing_nullable=True)
    op.alter_column('shifts', 'total_idle_distance',
                    type_=NUMERIC(10, 2),
                    existing_nullable=True)
    op.alter_column('shifts', 'total_income',
                    type_=NUMERIC(10, 2),
                    existing_nullable=True)
    op.alter_column('shifts', 'total_expenses',
                    type_=NUMERIC(10, 2),
                    existing_nullable=True)
    op.alter_column('shifts', 'net_profit',
                    type_=NUMERIC(10, 2),
                    existing_nullable=True)

    # ===== ORDERS =====
    op.alter_column('orders', 'coefficient',
                    type_=NUMERIC(5, 2),
                    existing_nullable=True)
    op.alter_column('orders', 'total_paid_distance',
                    type_=NUMERIC(10, 2),
                    existing_nullable=True)
    op.alter_column('orders', 'total_income',
                    type_=NUMERIC(10, 2),
                    existing_nullable=True)
    op.alter_column('orders', 'total_expenses',
                    type_=NUMERIC(10, 2),
                    existing_nullable=True)
    op.alter_column('orders', 'net_profit',
                    type_=NUMERIC(10, 2),
                    existing_nullable=True)

    # ===== DELIVERIES =====
    op.alter_column('deliveries', 'weight',
                    type_=NUMERIC(8, 2),
                    existing_nullable=True)
    op.alter_column('deliveries', 'distance_to_shop',
                    type_=NUMERIC(8, 2),
                    existing_nullable=True)
    op.alter_column('deliveries', 'distance_to_client',
                    type_=NUMERIC(8, 2),
                    existing_nullable=True)
    op.alter_column('deliveries', 'tip',
                    type_=NUMERIC(8, 2),
                    existing_nullable=True)

    # ===== SETTINGS =====
    op.alter_column('settings', 'fuel_consumption',
                    type_=NUMERIC(6, 2),
                    existing_nullable=True)
    op.alter_column('settings', 'fuel_price',
                    type_=NUMERIC(10, 2),
                    existing_nullable=True)
    op.alter_column('settings', 'repair_cost',
                    type_=NUMERIC(8, 2),
                    existing_nullable=True)
    op.alter_column('settings', 'additional_costs',
                    type_=NUMERIC(10, 2),
                    existing_nullable=True)

    # ===== PRICING =====
    op.alter_column('pricing', 'receiving_fee',
                    type_=NUMERIC(10, 2),
                    existing_nullable=True)
    op.alter_column('pricing', 'delivery_fee',
                    type_=NUMERIC(10, 2),
                    existing_nullable=True)
    op.alter_column('pricing', 'price_per_kg',
                    type_=NUMERIC(8, 2),
                    existing_nullable=True)
    op.alter_column('pricing', 'price_per_km',
                    type_=NUMERIC(8, 2),
                    existing_nullable=True)
    op.alter_column('pricing', 'base_coefficient',
                    type_=NUMERIC(5, 2),
                    existing_nullable=True)

    # ===== X5_SETTINGS =====
    op.alter_column('x5_settings', 'pickup_price',
                    type_=NUMERIC(10, 2),
                    existing_nullable=True)
    op.alter_column('x5_settings', 'delivery_price',
                    type_=NUMERIC(10, 2),
                    existing_nullable=True)
    op.alter_column('x5_settings', 'per_km_price',
                    type_=NUMERIC(8, 2),
                    existing_nullable=True)
    op.alter_column('x5_settings', 'per_kg_price',
                    type_=NUMERIC(8, 2),
                    existing_nullable=True)


def downgrade() -> None:
    # Возвращаем обратно к DOUBLE PRECISION
    # ===== SHIFTS =====
    op.alter_column('shifts', 'total_paid_distance',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('shifts', 'total_idle_distance',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('shifts', 'total_income',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('shifts', 'total_expenses',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('shifts', 'net_profit',
                    type_=sa.Float(),
                    existing_nullable=True)

    # ===== ORDERS =====
    op.alter_column('orders', 'coefficient',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('orders', 'total_paid_distance',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('orders', 'total_income',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('orders', 'total_expenses',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('orders', 'net_profit',
                    type_=sa.Float(),
                    existing_nullable=True)

    # ===== DELIVERIES =====
    op.alter_column('deliveries', 'weight',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('deliveries', 'distance_to_shop',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('deliveries', 'distance_to_client',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('deliveries', 'tip',
                    type_=sa.Float(),
                    existing_nullable=True)

    # ===== SETTINGS =====
    op.alter_column('settings', 'fuel_consumption',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('settings', 'fuel_price',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('settings', 'repair_cost',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('settings', 'additional_costs',
                    type_=sa.Float(),
                    existing_nullable=True)

    # ===== PRICING =====
    op.alter_column('pricing', 'receiving_fee',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('pricing', 'delivery_fee',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('pricing', 'price_per_kg',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('pricing', 'price_per_km',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('pricing', 'base_coefficient',
                    type_=sa.Float(),
                    existing_nullable=True)

    # ===== X5_SETTINGS =====
    op.alter_column('x5_settings', 'pickup_price',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('x5_settings', 'delivery_price',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('x5_settings', 'per_km_price',
                    type_=sa.Float(),
                    existing_nullable=True)
    op.alter_column('x5_settings', 'per_kg_price',
                    type_=sa.Float(),
                    existing_nullable=True)
