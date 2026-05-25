#!/usr/bin/env bash
# init_db.sh — Creates schema, indexes, triggers, procedures, and seed data.
# Requires: .env in project root, psql on PATH, Python venv activated.
# Usage: bash scripts/init_db.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env
if [ -f "$PROJECT_DIR/.env" ]; then
  set -a; source "$PROJECT_DIR/.env"; set +a
else
  echo "ERROR: .env not found at $PROJECT_DIR/.env"
  echo "Copy .env.example to .env and fill in your credentials."
  exit 1
fi

export PGPASSWORD="$DB_PASSWORD"
PSQL="psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME --set ON_ERROR_STOP=1"

echo "==> PakRastah DB Init"
echo "    Host  : $DB_HOST:$DB_PORT"
echo "    DB    : $DB_NAME"
echo "    User  : $DB_USER"
echo ""

echo "[1/5] Schema..."
$PSQL -f "$PROJECT_DIR/db/01_schema.sql"

echo "[2/5] Indexes..."
$PSQL -f "$PROJECT_DIR/db/02_indexes.sql"

echo "[3/5] Triggers..."
$PSQL -f "$PROJECT_DIR/db/03_triggers.sql"

echo "[4/5] Procedures..."
$PSQL -f "$PROJECT_DIR/db/04_procedures.sql"

echo "[5/5] Seed data..."
$PSQL -f "$PROJECT_DIR/db/05_seed.sql"

echo ""
echo "Setting demo passwords..."
python "$PROJECT_DIR/scripts/set_passwords.py"

echo ""
echo "Done. DB is ready."
echo ""
echo "Demo logins:"
echo "  admin    → admin@pakrastah.gov.pk    / admin123"
echo "  business → karachi@foods.pk          / business456"
echo "  auditor  → auditor@pakrastah.gov.pk  / auditor123"
echo ""
echo "Start app: python run.py"
