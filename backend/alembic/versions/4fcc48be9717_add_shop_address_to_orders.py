"""add_shop_address_to_orders

Revision ID: 123456
Revises: xxxx
Create Date: 2026-08-19 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '123456'
down_revision: Union[str, None] = 'xxxx'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Добавляем колонку shop_address
    op.add_column('orders', sa.Column('shop_address', sa.String(length=500), nullable=True))
    # Добавляем индекс для быстрого поиска
    op.create_index('idx_orders_shop_address', 'orders', ['shop_address'])


def downgrade() -> None:
    # Удаляем индекс
    op.drop_index('idx_orders_shop_address', table_name='orders')
    # Удаляем колонку
    op.drop_column('orders', 'shop_address')