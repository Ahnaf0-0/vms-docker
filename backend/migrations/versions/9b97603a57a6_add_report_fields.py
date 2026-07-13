"""add_report_fields

Revision ID: 9b97603a57a6
Revises: f7d515a781b4
Create Date: 2026-07-13 22:28:05.724626

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '9b97603a57a6'
down_revision: Union[str, None] = 'f7d515a781b4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add status to officers (Active vs Transferred)
    op.add_column('officers', sa.Column('status', sa.String(), server_default='Active', nullable=True))
    
    # Add entry and exit times to appointments
    op.add_column('appointments', sa.Column('entry_time', sa.DateTime(), nullable=True))
    op.add_column('appointments', sa.Column('exit_time', sa.DateTime(), nullable=True))


def downgrade() -> None:
    op.drop_column('appointments', 'exit_time')
    op.drop_column('appointments', 'entry_time')
    op.drop_column('officers', 'status')
