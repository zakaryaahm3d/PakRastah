# PakRastah — DBMS Course Project

## Stack
- PostgreSQL 16 (local) + psycopg2-binary + Flask 3 + Jinja2 + HTMX + Tailwind CDN
- Raw SQL only — no ORM, no SQLAlchemy, no migrations
- Session-based auth (werkzeug password hashing)

## Project layout
```
db/          SQL files loaded in numeric order by init_db.sh
scripts/     init_db.sh, reset_demo.sh, backup.sh + .ps1 shims
app/         Flask application
  routes/    One Blueprint per role
  templates/ Jinja2; every template extends base.html
```

## DB init (run once per environment)
```bash
cp .env.example .env   # fill in DB_PASSWORD
pip install -r requirements.txt
bash scripts/init_db.sh
```
Creates pakrastah database tables, indexes, triggers, procedures, and seed data.

## Demo reset (destroys all data)
```bash
bash scripts/reset_demo.sh
```

## Run
```bash
python run.py
```

## Demo logins
| Role      | Email                          | Password    |
|-----------|-------------------------------|-------------|
| Admin     | admin@pakrastah.gov.pk        | admin123    |
| Business  | karachi@foods.pk              | business456 |
| Auditor   | auditor@pakrastah.gov.pk      | auditor123  |
| Facility  | facility@recyclepak.pk        | facility123 |
| Developer | developer@pakrastah.gov.pk    | dev123      |

## DBMS concepts implemented
| Concept    | Location                                            |
|------------|-----------------------------------------------------|
| Constraints| `db/01_schema.sql` — CHECK, UNIQUE, FK ON DELETE    |
| Trigger 1  | `trg_waste_events_metrics` / `trg_processing_outputs_metrics` → `fn_recompute_business_metrics()` |
| Trigger 2  | `trg_business_metrics_certification` → `fn_check_certification_eligibility()` |
| Trigger 3  | 5× `trg_audit_*` → `fn_audit_delete()` → `audit_log` |
| Cursor     | `apply_monthly_tax_credits()` in `db/04_procedures.sql` |
| Joins      | 4-table join in `app/routes/admin.py` dashboard query |
| Indexes    | `db/02_indexes.sql` — justifications in `db/index_justifications.md` |

## Coding rules
- All SQL in db/ files or inline in route handlers via parameterized queries
- No string concatenation into SQL
- No ORM
