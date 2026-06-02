from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from ..auth import login_required
from ..db import query, get_db

stubs_bp = Blueprint('stubs', __name__)


@stubs_bp.route('/food-rescue')
@login_required(roles=['admin', 'auditor', 'charity', 'eatery'])
def food_rescue():
    donations = query("""
        SELECT
            fd.donation_id, fd.food_type, fd.quantity_kg,
            fd.donation_date, fd.status, fd.notes,
            ue.full_name AS eatery_name,
            uc.full_name AS charity_name
        FROM food_donations fd
        JOIN users ue ON ue.user_id = fd.eatery_id
        JOIN users uc ON uc.user_id = fd.charity_id
        ORDER BY fd.donation_date DESC
    """, fetchall=True)

    stats = query("""
        SELECT
            COUNT(*)                                       AS total_donations,
            COALESCE(SUM(quantity_kg), 0)                  AS total_kg,
            COUNT(*) FILTER (WHERE status = 'delivered')   AS delivered
        FROM food_donations
    """, fetchone=True)

    return render_template('stubs/food_rescue.html', donations=donations, stats=stats)


# ---------------------------------------------------------------------------
# WALLET
# ---------------------------------------------------------------------------

@stubs_bp.route('/wallet')
@login_required(roles=['citizen'])
def wallet():
    uid = session['user_id']

    me = query('SELECT wallet_balance, full_name FROM users WHERE user_id = %s',
               (uid,), fetchone=True)

    txns = query("""
        SELECT wt.txn_id, wt.amount, wt.txn_type, wt.description,
               wt.created_at, ml.title AS listing_title
        FROM wallet_transactions wt
        LEFT JOIN marketplace_listings ml ON ml.listing_id = wt.listing_id
        WHERE wt.user_id = %s
        ORDER BY wt.created_at DESC
        LIMIT 50
    """, (uid,), fetchall=True)

    return render_template('stubs/wallet.html', me=me, txns=txns)


@stubs_bp.route('/wallet/topup', methods=['POST'])
@login_required(roles=['citizen'])
def wallet_topup():
    uid = session['user_id']
    amount_str = request.form.get('amount', '').strip()

    try:
        amount = float(amount_str)
        if amount <= 0:
            raise ValueError
    except ValueError:
        flash('Enter a valid positive amount.', 'danger')
        return redirect(url_for('stubs.wallet'))

    db = get_db()
    cur = db.cursor()
    cur.execute(
        'UPDATE users SET wallet_balance = wallet_balance + %s WHERE user_id = %s RETURNING wallet_balance',
        (amount, uid)
    )
    new_balance = cur.fetchone()['wallet_balance']
    cur.execute(
        'INSERT INTO wallet_transactions (user_id, amount, txn_type, description) VALUES (%s, %s, %s, %s)',
        (uid, amount, 'topup', f'Wallet top-up of PKR {amount:,.0f}')
    )
    db.commit()
    cur.close()

    session['wallet_balance'] = float(new_balance)
    flash(f'PKR {amount:,.0f} added. New balance: PKR {new_balance:,.2f}', 'success')
    return redirect(url_for('stubs.wallet'))


# ---------------------------------------------------------------------------
# MARKETPLACE
# ---------------------------------------------------------------------------

@stubs_bp.route('/marketplace')
@login_required(roles=['admin', 'auditor', 'citizen'])
def marketplace():
    uid  = session['user_id']
    role = session['role']

    active_listings = query("""
        SELECT ml.listing_id, ml.title, ml.description, ml.category,
               ml.price_pkr, ml.quantity, ml.status, ml.city, ml.listed_at,
               ml.seller_id, ml.buyer_id,
               u.full_name AS seller_name
        FROM marketplace_listings ml
        JOIN users u ON u.user_id = ml.seller_id
        WHERE ml.status = 'active'
        ORDER BY ml.listed_at DESC
    """, fetchall=True)

    my_listings = []
    my_purchases = []
    wallet_balance = None

    if role == 'citizen':
        my_listings = query("""
            SELECT ml.listing_id, ml.title, ml.description, ml.category,
                   ml.price_pkr, ml.quantity, ml.status, ml.city, ml.listed_at,
                   ml.seller_id, ml.buyer_id,
                   b.full_name AS buyer_name
            FROM marketplace_listings ml
            LEFT JOIN users b ON b.user_id = ml.buyer_id
            WHERE ml.seller_id = %s
            ORDER BY ml.listed_at DESC
        """, (uid,), fetchall=True)

        my_purchases = query("""
            SELECT ml.listing_id, ml.title, ml.description, ml.category,
                   ml.price_pkr, ml.quantity, ml.status, ml.city, ml.listed_at,
                   ml.seller_id, ml.buyer_id,
                   u.full_name AS seller_name,
                   wt.created_at AS bought_at
            FROM marketplace_listings ml
            JOIN users u ON u.user_id = ml.seller_id
            JOIN wallet_transactions wt ON wt.listing_id = ml.listing_id AND wt.user_id = %s
            WHERE ml.buyer_id = %s
            ORDER BY wt.created_at DESC
        """, (uid, uid), fetchall=True)

        row = query('SELECT wallet_balance FROM users WHERE user_id = %s', (uid,), fetchone=True)
        wallet_balance = row['wallet_balance'] if row else 0

    stats = query("""
        SELECT
            COUNT(*) FILTER (WHERE status = 'active') AS active,
            COUNT(*) FILTER (WHERE status = 'sold')   AS sold,
            COALESCE(SUM(price_pkr) FILTER (WHERE status = 'active'), 0) AS active_value_pkr
        FROM marketplace_listings
    """, fetchone=True)

    return render_template('stubs/marketplace.html',
                           active_listings=active_listings,
                           my_listings=my_listings,
                           my_purchases=my_purchases,
                           wallet_balance=wallet_balance,
                           stats=stats,
                           viewer_id=uid, role=role)


@stubs_bp.route('/search')
@login_required()
def search():
    query_text = request.args.get('q', '').strip()
    results = {
        'businesses': [],
        'users': [],
        'events': [],
        'listings': []
    }

    if query_text:
        search_term = f'%{query_text}%'
        results['businesses'] = query(
            '''SELECT business_id, name, city, category
               FROM businesses
               WHERE name ILIKE %s
               ORDER BY name
               LIMIT 10''',
            (search_term,), fetchall=True
        )
        results['users'] = query(
            '''SELECT user_id, full_name, email, role
               FROM users
               WHERE full_name ILIKE %s OR email ILIKE %s
               ORDER BY full_name
               LIMIT 10''',
            (search_term, search_term), fetchall=True
        )
        results['events'] = query(
            '''SELECT event_id, event_date, status, tonnage, waste_type
               FROM waste_events
               WHERE notes ILIKE %s
               ORDER BY event_date DESC
               LIMIT 10''',
            (search_term,), fetchall=True
        )
        results['listings'] = query(
            '''SELECT listing_id, title, category, price_pkr, status
               FROM marketplace_listings
               WHERE title ILIKE %s OR description ILIKE %s
               ORDER BY listed_at DESC
               LIMIT 10''',
            (search_term, search_term), fetchall=True
        )

    return render_template('stubs/search_results.html', query_text=query_text, results=results)


@stubs_bp.route('/notifications')
@login_required()
def notifications():
    entries = query(
        '''SELECT log_id, table_name, operation, row_id, performed_by, performed_at, context
           FROM audit_log
           ORDER BY performed_at DESC
           LIMIT 30''',
        fetchall=True
    )
    return render_template('stubs/notifications.html', entries=entries)


@stubs_bp.route('/activity')
@login_required()
def activity():
    role = session.get('role')
    if role == 'citizen':
        txns = query(
            '''SELECT wt.txn_id, wt.amount, wt.txn_type, wt.description, wt.created_at,
                      ml.title AS listing_title
               FROM wallet_transactions wt
               LEFT JOIN marketplace_listings ml ON ml.listing_id = wt.listing_id
               WHERE wt.user_id = %s
               ORDER BY wt.created_at DESC
               LIMIT 30''',
            (session['user_id'],), fetchall=True
        )
        return render_template('stubs/activity.html', role=role, txns=txns)

    entries = query(
        '''SELECT log_id, table_name, operation, row_id, performed_by, performed_at, context
           FROM audit_log
           ORDER BY performed_at DESC
           LIMIT 30''',
        fetchall=True
    )
    return render_template('stubs/activity.html', role=role, entries=entries)


@stubs_bp.route('/marketplace/new', methods=['GET'])
@login_required(roles=['citizen'])
def new_listing_form():
    return render_template('stubs/new_listing.html')


@stubs_bp.route('/marketplace/listings', methods=['POST'])
@login_required(roles=['citizen'])
def create_listing():
    title       = request.form.get('title', '').strip()
    description = request.form.get('description', '').strip() or None
    category    = request.form.get('category', '')
    price_str   = request.form.get('price_pkr', '')
    quantity    = request.form.get('quantity', '1')
    city        = request.form.get('city', '').strip() or None

    if not title or not category or not price_str:
        flash('Title, category, and price are required.', 'danger')
        return redirect(url_for('stubs.new_listing_form'))

    try:
        price_pkr = float(price_str)
        quantity  = int(quantity)
        if price_pkr < 0 or quantity < 1:
            raise ValueError
    except ValueError:
        flash('Price must be non-negative and quantity at least 1.', 'danger')
        return redirect(url_for('stubs.new_listing_form'))

    query("""
        INSERT INTO marketplace_listings
            (seller_id, title, description, category, price_pkr, quantity, city, status)
        VALUES (%s, %s, %s, %s, %s, %s, %s, 'active')
    """, (session['user_id'], title, description, category, price_pkr, quantity, city),
         commit=True)

    flash('Listing posted successfully.', 'success')
    return redirect(url_for('stubs.marketplace'))


@stubs_bp.route('/marketplace/listings/<int:listing_id>/buy', methods=['POST'])
@login_required(roles=['citizen'])
def buy_listing(listing_id):
    uid = session['user_id']

    listing = query(
        '''SELECT ml.*, u.full_name AS seller_name
           FROM marketplace_listings ml
           JOIN users u ON u.user_id = ml.seller_id
           WHERE ml.listing_id = %s''',
        (listing_id,), fetchone=True
    )

    if not listing:
        return _htmx_or_flash(404, 'Listing not found.', 'danger')

    if listing['seller_id'] == uid:
        return _htmx_or_flash(400, 'You cannot buy your own listing.', 'danger')

    if listing['status'] != 'active':
        return _htmx_or_flash(409, 'This item is no longer available.', 'warning')

    price = listing['price_pkr']

    db  = get_db()
    cur = db.cursor()

    # Atomic deduct — returns nothing if balance insufficient (CHECK constraint prevents negative)
    cur.execute("""
        UPDATE users SET wallet_balance = wallet_balance - %s
        WHERE user_id = %s AND wallet_balance >= %s
        RETURNING wallet_balance
    """, (price, uid, price))
    buyer_row = cur.fetchone()

    if not buyer_row:
        db.rollback()
        cur.close()
        return _htmx_or_flash(402, 'Insufficient wallet balance. Top up your wallet first.', 'danger')

    new_buyer_balance = buyer_row['wallet_balance']

    # Credit seller
    cur.execute(
        'UPDATE users SET wallet_balance = wallet_balance + %s WHERE user_id = %s',
        (price, listing['seller_id'])
    )

    # Debit transaction for buyer
    cur.execute("""
        INSERT INTO wallet_transactions (user_id, amount, txn_type, listing_id, description)
        VALUES (%s, %s, 'purchase', %s, %s)
    """, (uid, -price, listing_id, f'Purchased: {listing["title"]}'))

    # Credit transaction for seller
    cur.execute("""
        INSERT INTO wallet_transactions (user_id, amount, txn_type, listing_id, description)
        VALUES (%s, %s, 'sale', %s, %s)
    """, (listing['seller_id'], price, listing_id, f'Sold: {listing["title"]}'))

    # Mark sold
    cur.execute("""
        UPDATE marketplace_listings SET status = 'sold', buyer_id = %s
        WHERE listing_id = %s AND status = 'active'
    """, (uid, listing_id))

    db.commit()
    cur.close()

    session['wallet_balance'] = float(new_buyer_balance)

    if request.headers.get('HX-Request'):
        return render_template('stubs/_listing_bought.html',
                               listing=listing,
                               buyer_name=session['full_name'],
                               new_balance=new_buyer_balance)

    flash(f'Purchased "{listing["title"]}"! PKR {price:,.0f} deducted.', 'success')
    return redirect(url_for('stubs.marketplace'))


@stubs_bp.route('/marketplace/listings/<int:listing_id>/remove', methods=['POST'])
@login_required(roles=['citizen'])
def remove_listing(listing_id):
    uid = session['user_id']

    listing = query(
        'SELECT * FROM marketplace_listings WHERE listing_id = %s AND seller_id = %s',
        (listing_id, uid), fetchone=True
    )

    if not listing or listing['status'] != 'active':
        flash('Listing not found or already inactive.', 'danger')
        return redirect(url_for('stubs.marketplace'))

    query('UPDATE marketplace_listings SET status = %s WHERE listing_id = %s',
          ('removed', listing_id), commit=True)

    if request.headers.get('HX-Request'):
        return render_template('stubs/_listing_removed.html', listing=listing)

    flash('Listing removed.', 'info')
    return redirect(url_for('stubs.marketplace'))


def _htmx_or_flash(status, message, category):
    if request.headers.get('HX-Request'):
        colour = 'red' if category == 'danger' else ('yellow' if category == 'warning' else 'blue')
        # Return 200 so HTMX actually swaps the error into the target element;
        # non-2xx responses are silently ignored by HTMX 1.x by default.
        return (f'<div class="col-span-3 p-4 rounded-lg bg-{colour}-50 border border-{colour}-200 '
                f'text-{colour}-700 text-sm">{message}</div>'), 200
    flash(message, category)
    return redirect(url_for('stubs.marketplace'))
