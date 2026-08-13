"""add_name_field_to_user

Revision ID: xxxx
Revises: 0001
Create Date: 2026-08-13 13:21:23.645206

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'xxxx'
down_revision: Union[str, None] = '0001'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Добавляем поле name в таблицу users
    op.add_column('users', sa.Column('name', sa.String(), nullable=True))


def downgrade() -> None:
    # Удаляем поле name из таблицы users
    op.drop_column('users', 'name')