# PakRastah - DBMS Course Project

PakRastah is a multi-role waste compliance portal built for a DBMS course project.  
It demonstrates a PostgreSQL-backed workflow for certification, auditing, waste tracking, marketplace listings, and reporting.

## Tech Stack

- PostgreSQL 16 (local)
- Flask 3
- psycopg2-binary
- Jinja2 templates
- HTMX
- Tailwind CSS (CDN)

## Key Constraints

- Raw SQL only (no ORM / no SQLAlchemy)
- Parameterized queries in route handlers
- Session-based authentication with Werkzeug password hashing

## Project Structure

```text
db/          SQL files loaded in numeric order by init_db.sh
scripts/     init_db.sh, reset_demo.sh, backup.sh + PowerShell shims
app/         Flask application
  routes/    One Blueprint per role
  templates/ Jinja2 templates (all extend base.html)
```

## Getting Started

### 1) Configure environment

Copy the example file and fill in secrets locally:

```bash
cp .env.example .env
```

Required: set `DB_PASSWORD` (and update `SECRET_KEY` for non-demo use).

### 2) Install dependencies

```bash
pip install -r requirements.txt
```

### 3) Initialize database (first run per environment)

```bash
bash scripts/init_db.sh
```

This creates schema objects, indexes, triggers, procedures, and seed/demo data.

## Run the App

```bash
python run.py
```

## Reset Demo Data

```bash
bash scripts/reset_demo.sh
```

Warning: this resets demo data.

## Demo Logins

| Role      | Email                       | Password    |
|-----------|-----------------------------|-------------|
| Admin     | admin@pakrastah.gov.pk     | admin123    |
| Business  | karachi@foods.pk           | business456 |
| Auditor   | auditor@pakrastah.gov.pk   | auditor123  |
| Facility  | facility@recyclepak.pk     | facility123 |
| Developer | developer@pakrastah.gov.pk | dev123      |

## DBMS Concepts Implemented

| Concept     | Location |
|-------------|----------|
| Constraints | `db/01_schema.sql` (CHECK, UNIQUE, FK with ON DELETE behavior) |
| Trigger 1   | `trg_waste_events_metrics` + `trg_processing_outputs_metrics` -> `fn_recompute_business_metrics()` |
| Trigger 2   | `trg_business_metrics_certification` -> `fn_check_certification_eligibility()` |
| Trigger 3   | `trg_audit_*` set -> `fn_audit_delete()` -> `audit_log` |
| Cursor      | `apply_monthly_tax_credits()` in `db/04_procedures.sql` |
| Joins       | Multi-table dashboard join in `app/routes/admin.py` |
| Indexes     | `db/02_indexes.sql` with notes in `db/index_justifications.md` |

## Security Notes

- Keep `.env` local and never commit it.
- Commit only `.env.example` with placeholder values.
- Rotate credentials if they are exposed.

## License

This project is for educational/course use.
