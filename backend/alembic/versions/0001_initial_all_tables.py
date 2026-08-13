"""initial_all_tables

Revision ID: 0001
Revises: 
Create Date: 2026-08-13 07:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '0001'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Таблица users
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('email', sa.String(), nullable=False),
        sa.Column('hashed_password', sa.String(), nullable=False),
        sa.Column('name', sa.String(), nullable=True),
        sa.Column('is_active', sa.Boolean(), server_default='true', nullable=True),
        sa.Column('role', sa.String(), server_default='user', nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.func.now(), onupdate=sa.func.now(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_users_id', 'users', ['id'])
    op.create_index('ix_users_email', 'users', ['email'], unique=True)

    # Таблица refresh_tokens
    op.create_table(
        'refresh_tokens',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('token', sa.String(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('expires_at', sa.DateTime(), nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now(), nullable=True),
        sa.Column('revoked', sa.Boolean(), server_default='false', nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE')
    )
    op.create_index('ix_refresh_tokens_id', 'refresh_tokens', ['id'])
    op.create_index('ix_refresh_tokens_token', 'refresh_tokens', ['token'], unique=True)

    # Таблица shifts
    op.create_table(
        'shifts',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('local_id', sa.Integer(), nullable=True),
        sa.Column('user_id', sa.Integer(), nullable=True),
        sa.Column('start_time', sa.String(length=100), nullable=True),
        sa.Column('end_time', sa.String(length=100), nullable=True),
        sa.Column('duration_seconds', sa.Integer(), server_default='0', nullable=True),
        sa.Column('total_paid_distance', sa.Float(), server_default='0', nullable=True),
        sa.Column('total_idle_distance', sa.Float(), server_default='0', nullable=True),
        sa.Column('total_order_time_seconds', sa.Integer(), server_default='0', nullable=True),
        sa.Column('orders_count', sa.Integer(), server_default='0', nullable=True),
        sa.Column('total_income', sa.Float(), server_default='0', nullable=True),
        sa.Column('total_expenses', sa.Float(), server_default='0', nullable=True),
        sa.Column('net_profit', sa.Float(), server_default='0', nullable=True),
        sa.Column('status', sa.String(length=50), server_default='active', nullable=True),
        sa.Column('is_synced', sa.Boolean(), server_default='false', nullable=True),
        sa.Column('synced_at', sa.DateTime(), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.func.now(), onupdate=sa.func.now(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_shifts_id', 'shifts', ['id'])
    op.create_index('ix_shifts_user_id', 'shifts', ['user_id'])
    op.create_index('ix_shifts_is_synced', 'shifts', ['is_synced'])

    # Таблица orders
    op.create_table(
        'orders',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('local_id', sa.Integer(), nullable=True),
        sa.Column('user_id', sa.Integer(), nullable=True),
        sa.Column('shift_id', sa.Integer(), nullable=True),
        sa.Column('service_name', sa.String(length=255), nullable=True),
        sa.Column('coefficient', sa.Float(), server_default='1.0', nullable=True),
        sa.Column('delivery_number', sa.Integer(), server_default='1', nullable=True),
        sa.Column('total_paid_distance', sa.Float(), server_default='0', nullable=True),
        sa.Column('total_income', sa.Float(), server_default='0', nullable=True),
        sa.Column('total_expenses', sa.Float(), server_default='0', nullable=True),
        sa.Column('net_profit', sa.Float(), server_default='0', nullable=True),
        sa.Column('total_time_seconds', sa.Integer(), server_default='0', nullable=True),
        sa.Column('status', sa.String(length=50), server_default='active', nullable=True),
        sa.Column('is_synced', sa.Boolean(), server_default='false', nullable=True),
        sa.Column('synced_at', sa.DateTime(), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.func.now(), onupdate=sa.func.now(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['shift_id'], ['shifts.id'], ondelete='SET NULL')
    )
    op.create_index('ix_orders_id', 'orders', ['id'])
    op.create_index('ix_orders_user_id', 'orders', ['user_id'])
    op.create_index('ix_orders_shift_id', 'orders', ['shift_id'])
    op.create_index('ix_orders_is_synced', 'orders', ['is_synced'])

    # Таблица deliveries
    op.create_table(
        'deliveries',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('local_id', sa.Integer(), nullable=True),
        sa.Column('order_id', sa.Integer(), nullable=True),
        sa.Column('number', sa.Integer(), server_default='0', nullable=True),
        sa.Column('client_address', sa.String(length=500), nullable=True),
        sa.Column('apartment', sa.String(length=50), nullable=True),
        sa.Column('weight', sa.Float(), server_default='0', nullable=True),
        sa.Column('time_to_shop', sa.Integer(), server_default='0', nullable=True),
        sa.Column('distance_to_shop', sa.Float(), server_default='0', nullable=True),
        sa.Column('time_receiving', sa.Integer(), server_default='0', nullable=True),
        sa.Column('time_to_client', sa.Integer(), server_default='0', nullable=True),
        sa.Column('distance_to_client', sa.Float(), server_default='0', nullable=True),
        sa.Column('time_delivery', sa.Integer(), server_default='0', nullable=True),
        sa.Column('status', sa.String(length=50), server_default='active', nullable=True),
        sa.Column('is_synced', sa.Boolean(), server_default='false', nullable=True),
        sa.Column('synced_at', sa.DateTime(), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.func.now(), onupdate=sa.func.now(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['order_id'], ['orders.id'], ondelete='CASCADE')
    )
    op.create_index('ix_deliveries_id', 'deliveries', ['id'])
    op.create_index('ix_deliveries_order_id', 'deliveries', ['order_id'])
    op.create_index('ix_deliveries_is_synced', 'deliveries', ['is_synced'])


def downgrade() -> None:
    op.drop_index('ix_deliveries_is_synced', table_name='deliveries')
    op.drop_index('ix_deliveries_order_id', table_name='deliveries')
    op.drop_index('ix_deliveries_id', table_name='deliveries')
    op.drop_table('deliveries')
    
    op.drop_index('ix_orders_is_synced', table_name='orders')
    op.drop_index('ix_orders_shift_id', table_name='orders')
    op.drop_index('ix_orders_user_id', table_name='orders')
    op.drop_index('ix_orders_id', table_name='orders')
    op.drop_table('orders')
    
    op.drop_index('ix_shifts_is_synced', table_name='shifts')
    op.drop_index('ix_shifts_user_id', table_name='shifts')
    op.drop_index('ix_shifts_id', table_name='shifts')
    op.drop_table('shifts')
    
    op.drop_index('ix_refresh_tokens_token', table_name='refresh_tokens')
    op.drop_index('ix_refresh_tokens_id', table_name='refresh_tokens')
    op.drop_table('refresh_tokens')
    
    op.drop_index('ix_users_email', table_name='users')
    op.drop_index('ix_users_id', table_name='users')
    op.drop_table('users')
