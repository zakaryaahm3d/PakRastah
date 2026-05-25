from datetime import date
from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from ..auth import login_required
from ..db import query, get_db

business_bp = Blueprint('business', __name__)


def _get_business_id():
    row = query(
        'SELECT business_id FROM businesses WHERE user_id = %s',
        (session['user_id'],), fetchone=True
    )
    return row['business_id'] if row else None


@business_bp.route('/')
@login_required(roles=['business'])
def dashboard():
    bid = _get_business_id()
    if not bid:
        flash('No business profile found for this account.', 'danger')
        return redirect(url_for('auth.login'))

    business = query(
        'SELECT * FROM businesses WHERE business_id = %s', (bid,), fetchone=True)

    metrics = query(
        'SELECT * FROM business_metrics WHERE business_id = %s', (bid,), fetchone=True)

    cert = query("""
        SELECT c.*, cq.status AS queue_status, cq.tier AS queue_tier
        FROM certifications c
        JOIN certification_queue cq ON cq.queue_id = c.queue_id
        WHERE c.business_id = %s AND c.status = 'active'
        ORDER BY c.issued_date DESC LIMIT 1
    """, (bid,), fetchone=True)

    queue_entry = query("""
        SELECT * FROM certification_queue
        WHERE business_id = %s AND status IN ('eligible_for_review','under_review')
        ORDER BY submitted_at DESC LIMIT 1
    """, (bid,), fetchone=True)

    tax_credits = query("""
        SELECT tc.*, c.cert_number
        FROM tax_credits tc
        LEFT JOIN certifications c ON c.certification_id = tc.certification_id
        WHERE tc.business_id = %s
        ORDER BY tc.calculation_date DESC
    """, (bid,), fetchall=True)

    events = query("""
        SELECT we.event_id, we.event_date, we.tonnage, we.waste_type, we.status,
               pf.name AS facility_name,
               po.recovered_tonnage, po.output_type
        FROM waste_events we
        LEFT JOIN processing_facilities pf ON pf.facility_id = we.facility_id
        LEFT JOIN processing_outputs    po ON po.event_id    = we.event_id
        WHERE we.business_id = %s
        ORDER BY we.event_date DESC
        LIMIT 20
    """, (bid,), fetchall=True)

    facilities = query(
        'SELECT facility_id, name FROM processing_facilities ORDER BY name',
        fetchall=True)

    return render_template('business/dashboard.html',
                           today=date.today().isoformat(),
                           business=business, metrics=metrics, cert=cert,
                           queue_entry=queue_entry, tax_credits=tax_credits,
                           events=events, facilities=facilities)


@business_bp.route('/waste-events/new', methods=['GET'])
@login_required(roles=['business'])
def new_event_form():
    facilities = query(
        'SELECT facility_id, name, city FROM processing_facilities ORDER BY name',
        fetchall=True)
    return render_template('business/new_event.html',
                           facilities=facilities,
                           today=date.today().isoformat())


@business_bp.route('/waste-events', methods=['POST'])
@login_required(roles=['business'])
def create_event():
    bid = _get_business_id()
    if not bid:
        flash('No business profile.', 'danger')
        return redirect(url_for('business.dashboard'))

    facility_id = request.form.get('facility_id') or None
    event_date  = request.form.get('event_date')
    tonnage     = request.form.get('tonnage')
    waste_type  = request.form.get('waste_type')
    notes       = request.form.get('notes', '').strip() or None

    if not all([event_date, tonnage, waste_type]):
        flash('Date, tonnage, and waste type are required.', 'danger')
        return redirect(url_for('business.new_event_form'))

    try:
        tonnage = float(tonnage)
        if tonnage <= 0:
            raise ValueError
    except ValueError:
        flash('Tonnage must be a positive number.', 'danger')
        return redirect(url_for('business.new_event_form'))

    query("""
        INSERT INTO waste_events (business_id, facility_id, event_date, tonnage, waste_type, status, notes)
        VALUES (%s, %s, %s, %s, %s, 'pending', %s)
    """, (bid, facility_id, event_date, tonnage, waste_type, notes), commit=True)

    flash('Waste pickup event logged successfully.', 'success')
    return redirect(url_for('business.dashboard'))
