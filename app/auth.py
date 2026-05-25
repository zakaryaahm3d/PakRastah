from functools import wraps
from flask import (Blueprint, render_template, request, redirect,
                   url_for, session, flash, g)
from werkzeug.security import check_password_hash
from .db import query

auth_bp = Blueprint('auth', __name__)

ROLE_HOME = {
    'admin':    'admin.dashboard',
    'business': 'business.dashboard',
    'facility': 'facility.dashboard',
    'auditor':  'auditor.queue',
    'citizen':  'stubs.marketplace',
}


def login_required(roles=None):
    def decorator(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            if 'user_id' not in session:
                flash('Please log in to continue.', 'warning')
                return redirect(url_for('auth.login'))
            if roles and session.get('role') not in roles:
                flash('Access denied.', 'danger')
                return redirect(url_for('auth.login'))
            return f(*args, **kwargs)
        return decorated
    return decorator


@auth_bp.route('/')
def index():
    if 'role' in session:
        return redirect(url_for(ROLE_HOME.get(session['role'], 'auth.login')))
    return redirect(url_for('auth.login'))


@auth_bp.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email    = request.form.get('email', '').strip().lower()
        password = request.form.get('password', '')

        user = query(
            'SELECT user_id, email, password_hash, role, full_name FROM users WHERE email = %s',
            (email,), fetchone=True
        )

        if user and check_password_hash(user['password_hash'], password):
            session.clear()
            session['user_id']   = user['user_id']
            session['email']     = user['email']
            session['role']      = user['role']
            session['full_name'] = user['full_name']
            home = ROLE_HOME.get(user['role'], 'auth.login')
            return redirect(url_for(home))

        flash('Invalid email or password.', 'danger')

    return render_template('login.html')


@auth_bp.route('/logout', methods=['POST'])
def logout():
    session.clear()
    flash('You have been logged out.', 'info')
    return redirect(url_for('auth.login'))
