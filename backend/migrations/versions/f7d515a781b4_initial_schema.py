"""initial_schema

Revision ID: f7d515a781b4
Revises: 
Create Date: 2026-07-13

Complete initial schema for VMS (Visitor Management System).
Tables: users, officers, admins, appointments.
Requires: pgvector extension (for face embeddings).
"""
from alembic import op
import sqlalchemy as sa
from pgvector.sqlalchemy import Vector

# Revision identifiers
revision = 'f7d515a781b4'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── Enable pgvector extension ─────────────────────────────────────────────
    # Required for storing 512-dimensional face embeddings
    op.execute("CREATE EXTENSION IF NOT EXISTS vector")

    # ── users (visitors) ──────────────────────────────────────────────────────
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('full_name', sa.String(), nullable=True),
        sa.Column('email', sa.String(), nullable=True),
        sa.Column('hashed_password', sa.String(), nullable=True),
        sa.Column('company', sa.String(), nullable=True),
        sa.Column('designation', sa.String(), nullable=True),
        sa.Column('is_blacklisted', sa.Boolean(), nullable=True),
        sa.Column('encrypted_phone', sa.String(), nullable=True),
        sa.Column('encrypted_nid', sa.String(), nullable=True),
        # 512-dim vectors for insightface embeddings (Front / Left / Right)
        sa.Column('face_embedding_front', Vector(512), nullable=True),
        sa.Column('face_embedding_left', Vector(512), nullable=True),
        sa.Column('face_embedding_right', Vector(512), nullable=True),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_users_id', 'users', ['id'])
    op.create_index('ix_users_email', 'users', ['email'], unique=True)
    op.create_index('ix_users_full_name', 'users', ['full_name'])

    # ── officers ──────────────────────────────────────────────────────────────
    op.create_table(
        'officers',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('full_name', sa.String(), nullable=True),
        sa.Column('department', sa.String(), nullable=True),
        sa.Column('email', sa.String(), nullable=True),
        sa.Column('hashed_password', sa.String(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_officers_id', 'officers', ['id'])
    op.create_index('ix_officers_email', 'officers', ['email'], unique=True)
    op.create_index('ix_officers_full_name', 'officers', ['full_name'])
    op.create_index('ix_officers_department', 'officers', ['department'])

    # ── admins ────────────────────────────────────────────────────────────────
    op.create_table(
        'admins',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('full_name', sa.String(), nullable=True),
        sa.Column('email', sa.String(), nullable=True),
        sa.Column('hashed_password', sa.String(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_admins_id', 'admins', ['id'])
    op.create_index('ix_admins_email', 'admins', ['email'], unique=True)

    # ── appointments ──────────────────────────────────────────────────────────
    op.create_table(
        'appointments',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('visitor_id', sa.Integer(), nullable=True),
        sa.Column('officer_id', sa.Integer(), nullable=True),
        sa.Column('purpose', sa.Text(), nullable=True),
        sa.Column('requested_date', sa.DateTime(), nullable=True),
        sa.Column('status', sa.String(), nullable=True),
        sa.Column('qr_token', sa.String(), nullable=True),
        sa.ForeignKeyConstraint(['officer_id'], ['officers.id']),
        sa.ForeignKeyConstraint(['visitor_id'], ['users.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_appointments_id', 'appointments', ['id'])


def downgrade() -> None:
    """Reverse this migration — drops all tables and the vector extension."""
    op.drop_index('ix_appointments_id', table_name='appointments')
    op.drop_table('appointments')

    op.drop_index('ix_admins_email', table_name='admins')
    op.drop_index('ix_admins_id', table_name='admins')
    op.drop_table('admins')

    op.drop_index('ix_officers_department', table_name='officers')
    op.drop_index('ix_officers_full_name', table_name='officers')
    op.drop_index('ix_officers_email', table_name='officers')
    op.drop_index('ix_officers_id', table_name='officers')
    op.drop_table('officers')

    op.drop_index('ix_users_full_name', table_name='users')
    op.drop_index('ix_users_email', table_name='users')
    op.drop_index('ix_users_id', table_name='users')
    op.drop_table('users')

    op.execute("DROP EXTENSION IF EXISTS vector")
