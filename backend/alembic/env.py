import sys
from pathlib import Path

# Добавляем путь к проекту
sys.path.append(str(Path(__file__).parent.parent))

import os
from dotenv import load_dotenv

# Загружаем .env файл
def load_env():
    docker_env = Path("/app/infrastructure/.env.dev")
    if docker_env.exists():
        load_dotenv(docker_env)
        return
    local_env = Path(__file__).parent.parent.parent / "infrastructure" / ".env.dev"
    if local_env.exists():
        load_dotenv(local_env)
        return
    backend_env = Path(__file__).parent.parent / ".env"
    if backend_env.exists():
        load_dotenv(backend_env)
        return
    load_dotenv()

load_env()

from app.core.database import Base
from app.core.config import settings

from alembic import context
from sqlalchemy import engine_from_config, pool
from logging.config import fileConfig

config = context.config

config.set_main_option('sqlalchemy.url', settings.DATABASE_URL)

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Импортируем модели
from app.modules.deliveries.models import Shift, Order, Delivery
from app.modules.users.models import User, RefreshToken

# Список таблиц, которые НЕ нужно трогать (PostGIS и т.д.)
EXCLUDE_TABLES = [
    'spatial_ref_sys',
    'geography_columns',
    'geometry_columns',
    'topology',
    'layer',
    'topology_id_seq',
    'loader_platform',
    'loader_variables',
    'loader_lookuptables',
    'geocode_settings',
    'geocode_settings_default',
    'pagc_lex',
    'pagc_gaz',
    'pagc_rules',
    'zip_lookup',
    'zip_lookup_base',
    'zip_lookup_all',
    'zip_state',
    'zip_state_loc',
    'state_lookup',
    'county_lookup',
    'countysub_lookup',
    'place_lookup',
    'direction_lookup',
    'street_type_lookup',
    'secondary_unit_lookup',
    'addr',
    'addrfeat',
    'edges',
    'faces',
    'featnames',
    'place',
    'county',
    'state',
    'cousub',
    'tabblock',
    'tabblock20',
    'bg',
    'tract',
    'zcta5',
    'shifts_temp',  # если есть временные таблицы
]

def include_object(object, name, type_, reflected, compare_to):
    """Исключаем PostGIS таблицы из миграций"""
    if type_ == "table" and name in EXCLUDE_TABLES:
        return False
    # Исключаем PostGIS индексы и последовательности
    if type_ == "index" and name.startswith('idx_tiger_'):
        return False
    if type_ == "index" and name.startswith('tiger_'):
        return False
    return True

target_metadata = Base.metadata

def run_migrations_offline():
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        include_object=include_object,
    )
    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online():
    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            include_object=include_object,
        )
        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()