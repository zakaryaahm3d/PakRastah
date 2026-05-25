#!/usr/bin/env bash
# reset_demo.sh — Drops all tables and reinitialises from scratch.
# USE ONLY FOR DEMO RESETS. Destroys all data.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ -f "$PROJECT_DIR/.env" ]; then
  set -a; source "$PROJECT_DIR/.env"; set +a
fi

export PGPASSWORD="$DB_PASSWORD"
PSQL="psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME --set ON_ERROR_STOP=1"

echo "==> Resetting PakRastah demo database..."

$PSQL <<'SQL'
DROP TABLE IF EXISTS
  marketplace_listings, food_donations,
  audit_log, tax_credits, certifications,
  certification_queue, business_metrics,
  processing_outputs, waste_events,
  processing_facilities, businesses, users
CASCADE;
SQL

echo "Tables dropped. Reinitialising..."
bash "$SCRIPT_DIR/init_db.sh"
