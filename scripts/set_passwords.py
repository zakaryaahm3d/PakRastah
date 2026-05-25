#!/usr/bin/env python3
"""Called by init_db.sh after SQL files are loaded. Sets werkzeug-hashed passwords.
Relies on DB_* env vars already exported by init_db.sh (which sources .env).
"""
import os
import sys

import psycopg2
from werkzeug.security import generate_password_hash

DEMO_PASSWORDS = {
    'admin@pakrastah.gov.pk':     'admin123',
    'lahore@textiles.pk':         'business123',
    'karachi@foods.pk':           'business456',
    'islamabad@energy.pk':        'business789',
    'facility@recyclepak.pk':     'facility123',
    'auditor@pakrastah.gov.pk':   'auditor123',
    'developer@pakrastah.gov.pk': 'dev123',
    'citizen1@gmail.com':         'citizen1',
    'citizen2@gmail.com':         'citizen2',
    'citizen3@gmail.com':         'citizen3',
    'citizen4@gmail.com':         'citizen4',
    'citizen5@gmail.com':         'citizen5',
}

conn = psycopg2.connect(
    host=os.environ['DB_HOST'],
    port=int(os.environ['DB_PORT']),
    dbname=os.environ['DB_NAME'],
    user=os.environ['DB_USER'],
    password=os.environ['DB_PASSWORD'],
)
cur = conn.cursor()

for email, password in DEMO_PASSWORDS.items():
    hashed = generate_password_hash(password)
    cur.execute('UPDATE users SET password_hash = %s WHERE email = %s', (hashed, email))
    if cur.rowcount == 0:
        print(f'  WARNING: no user found for {email}')
    else:
        print(f'  OK {email}')

conn.commit()
cur.close()
conn.close()
print('Passwords set successfully.')
