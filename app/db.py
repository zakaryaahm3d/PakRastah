import psycopg2
import psycopg2.extras
from flask import g, current_app


def get_db():
    if 'db' not in g:
        cfg = current_app.config
        g.db = psycopg2.connect(
            host=cfg['DB_HOST'],
            port=cfg['DB_PORT'],
            dbname=cfg['DB_NAME'],
            user=cfg['DB_USER'],
            password=cfg['DB_PASSWORD'],
            cursor_factory=psycopg2.extras.RealDictCursor,
        )
        g.db.autocommit = False
    return g.db


def close_db(e=None):
    db = g.pop('db', None)
    if db is not None:
        db.close()


def query(sql, params=None, fetchone=False, fetchall=False, commit=False):
    db = get_db()
    cur = db.cursor()
    cur.execute(sql, params or ())
    result = None
    if fetchone:
        result = cur.fetchone()
    elif fetchall:
        result = cur.fetchall()
    if commit:
        db.commit()
    cur.close()
    return result


def call_procedure(proc_sql):
    """Execute a stored procedure and return OUT parameter values.
    psycopg2 returns CALL OUT params as a result row on PostgreSQL 14+.
    """
    db = get_db()
    cur = db.cursor()
    cur.execute(proc_sql)
    result = None
    try:
        result = cur.fetchone()
    except Exception:
        pass
    db.commit()
    cur.close()
    return result
