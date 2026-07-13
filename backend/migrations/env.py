"""
Alembic Environment Configuration for VMS.

This file is executed whenever Alembic runs a command.
It is configured to:
- Use async SQLAlchemy (asyncpg driver) at runtime
- Read DB credentials from environment variables (same as the app)
- Auto-detect model changes via `target_metadata`
"""
import asyncio
import os
import sys
from logging.config import fileConfig

from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

from alembic import context

# ── Make backend/ importable ──────────────────────────────────────────────────
# Ensures `import models` and `import database` resolve correctly
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# ── Import your models so Alembic can detect schema changes ──────────────────
from database import Base  # noqa: E402
import models  # noqa: E402, F401  ← This import MUST stay: it registers all tables

# ── Alembic Config ────────────────────────────────────────────────────────────
config = context.config

# Interpret the config file for Python logging
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# The metadata Alembic uses to detect schema changes (autogenerate)
target_metadata = Base.metadata


# ── Build the async database URL from environment variables ──────────────────
def get_url() -> str:
    user = os.getenv("POSTGRES_USER", "postgres")
    password = os.getenv("POSTGRES_PASSWORD", "postgres")
    db = os.getenv("POSTGRES_DB", "vms")
    host = os.getenv("POSTGRES_HOST", "localhost")
    port = os.getenv("POSTGRES_PORT", "5432")
    # Use asyncpg for async-compatible migrations
    return f"postgresql+asyncpg://{user}:{password}@{host}:{port}/{db}"


# ── Offline mode: generate SQL scripts without connecting ─────────────────────
def run_migrations_offline() -> None:
    """Run migrations without a live DB connection. Produces .sql output."""
    url = get_url()
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
    )
    with context.begin_transaction():
        context.run_migrations()


# ── Online async mode: connect and apply migrations ───────────────────────────
def do_run_migrations(connection: Connection) -> None:
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        compare_type=True,  # Detect column type changes
    )
    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    """Create async engine and run migrations."""
    configuration = config.get_section(config.config_ini_section, {})
    configuration["sqlalchemy.url"] = get_url()

    connectable = async_engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,  # No connection pool for migrations
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()


def run_migrations_online() -> None:
    """Entry point for online migrations."""
    asyncio.run(run_async_migrations())


# ── Main ──────────────────────────────────────────────────────────────────────
if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
