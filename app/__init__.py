from flask import Flask, session
from .config import Config
from .db import close_db, query


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    app.teardown_appcontext(close_db)

    @app.context_processor
    def inject_wallet():
        if session.get('role') == 'citizen' and session.get('user_id'):
            row = query('SELECT wallet_balance FROM users WHERE user_id = %s',
                        (session['user_id'],), fetchone=True)
            return {'nav_wallet_balance': float(row['wallet_balance']) if row else 0.0}
        return {'nav_wallet_balance': None}

    from .auth import auth_bp
    from .routes.admin import admin_bp
    from .routes.business import business_bp
    from .routes.facility import facility_bp
    from .routes.auditor import auditor_bp
    from .routes.stubs import stubs_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(admin_bp, url_prefix='/admin')
    app.register_blueprint(business_bp, url_prefix='/business')
    app.register_blueprint(facility_bp, url_prefix='/facility')
    app.register_blueprint(auditor_bp, url_prefix='/auditor')
    app.register_blueprint(stubs_bp)

    return app
