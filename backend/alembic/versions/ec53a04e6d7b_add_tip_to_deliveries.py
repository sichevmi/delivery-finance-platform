"""add_tip_to_deliveries

Revision ID: ec53a04e6d7b
Revises: 123456
Create Date: 2026-08-19 21:03:11.842103

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'ec53a04e6d7b'
down_revision: Union[str, None] = '123456'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Добавляем колонку tip с дефолтным значением 0.0
    op.add_column('deliveries', sa.Column('tip', sa.Float(), nullable=True, server_default='0.0'))
    # Добавляем индекс для быстрого поиска (опционально)
    op.create_index('idx_deliveries_tip', 'deliveries', ['tip'])


def downgrade() -> None:
    # Удаляем индекс
    op.drop_index('idx_deliveries_tip', table_name='deliveries')
    # Удаляем колонку
    op.drop_column('deliveries', 'tip')
