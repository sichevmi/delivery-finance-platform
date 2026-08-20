"""add_missing_shift_fields

Revision ID: f3e828969fd3
Revises: 4a721d841b35
Create Date: 2026-08-20 11:45:29.115016

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect


# revision identifiers, used by Alembic.
revision: str = 'f3e828969fd3'
down_revision: Union[str, None] = '4a721d841b35'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Получаем информацию о существующих колонках
    conn = op.get_bind()
    inspector = inspect(conn)
    columns = [col['name'] for col in inspector.get_columns('shifts')]
    
    # Добавляем поля только если их нет
    if 'paused_at' not in columns:
        op.add_column('shifts', sa.Column('paused_at', sa.String(), nullable=True))
    
    if 'resumed_at' not in columns:
        op.add_column('shifts', sa.Column('resumed_at', sa.String(), nullable=True))


def downgrade() -> None:
    op.drop_column('shifts', 'resumed_at')
    op.drop_column('shifts', 'paused_at')
