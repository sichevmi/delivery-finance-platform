"""add_pause_fields_to_shifts

Revision ID: bf2f8f925a6f
Revises: ec53a04e6d7b
Create Date: 2026-08-19 22:12:29.839870

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'bf2f8f925a6f'
down_revision: Union[str, None] = 'ec53a04e6d7b'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('shifts', sa.Column('paused_at', sa.String(), nullable=True))
    op.add_column('shifts', sa.Column('resumed_at', sa.String(), nullable=True))
    op.execute("UPDATE shifts SET status = 'paused' WHERE status = 'active' AND end_time IS NULL")


def downgrade() -> None:
    op.drop_column('shifts', 'resumed_at')
    op.drop_column('shifts', 'paused_at')
