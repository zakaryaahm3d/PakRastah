from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from ..auth import login_required
from ..db import query

facility_bp = Blueprint('facility', __name__)


def _get_facility_id():
    row = query(
        'SELECT facility_id FROM processing_facilities WHERE user_id = %s',
        (session['user_id'],), fetchone=True
    )
    return row['facility_id'] if row else None


@facility_bp.route('/')
@login_required(roles=['facility'])
def dashboard():
    fid = _get_facility_id()
    if not fid:
        flash('No facility profile found.', 'danger')
        return redirect(url_for('auth.login'))

    facility = query(
        'SELECT * FROM processing_facilities WHERE facility_id = %s', (fid,), fetchone=True)

    pending_events = query("""
        SELECT we.event_id, we.event_date, we.tonnage, we.waste_type, we.status,
               b.name AS business_name, b.city AS business_city
        FROM waste_events we
        JOIN businesses b ON b.business_id = we.business_id
        WHERE we.facility_id = %s AND we.status != 'processed'
        ORDER BY we.event_date DESC
    """, (fid,), fetchall=True)

    recent_outputs = query("""
        SELECT po.output_id, po.recovered_tonnage, po.output_type, po.processed_date,
               we.tonnage AS input_tonnage, we.waste_type,
               b.name AS business_name
        FROM processing_outputs po
        JOIN waste_events we ON we.event_id   = po.event_id
        JOIN businesses   b  ON b.business_id = we.business_id
        WHERE po.facility_id = %s
        ORDER BY po.processed_date DESC
        LIMIT 15
    """, (fid,), fetchall=True)

    stats = query("""
        SELECT
            COUNT(DISTINCT po.output_id)           AS total_outputs,
            COALESCE(SUM(po.recovered_tonnage), 0) AS total_recovered_kg,
            COALESCE(SUM(we.tonnage), 0)           AS total_received_kg
        FROM processing_outputs po
        JOIN waste_events we ON we.event_id = po.event_id
        WHERE po.facility_id = %s
          AND po.processed_date >= CURRENT_DATE - INTERVAL '30 days'
    """, (fid,), fetchone=True)

    return render_template('facility/dashboard.html',
                           facility=facility, pending_events=pending_events,
                           recent_outputs=recent_outputs, stats=stats)


@facility_bp.route('/process', methods=['GET'])
@login_required(roles=['facility'])
def process_form():
    fid = _get_facility_id()
    unprocessed = query("""
        SELECT we.event_id, we.event_date, we.tonnage, we.waste_type,
               b.name AS business_name
        FROM waste_events we
        JOIN businesses b ON b.business_id = we.business_id
        WHERE we.facility_id = %s
          AND we.status IN ('pending','received')
          AND we.event_id NOT IN (SELECT event_id FROM processing_outputs)
        ORDER BY we.event_date DESC
    """, (fid,), fetchall=True)
    return render_template('facility/process.html', unprocessed=unprocessed, facility_id=fid)


@facility_bp.route('/process', methods=['POST'])
@login_required(roles=['facility'])
def create_output():
    fid = _get_facility_id()
    if not fid:
        flash('No facility profile.', 'danger')
        return redirect(url_for('facility.dashboard'))

    event_id          = request.form.get('event_id')
    recovered_tonnage = request.form.get('recovered_tonnage')
    output_type       = request.form.get('output_type')
    processed_date    = request.form.get('processed_date')
    notes             = request.form.get('notes', '').strip() or None

    if not all([event_id, recovered_tonnage, output_type, processed_date]):
        flash('All fields are required.', 'danger')
        return redirect(url_for('facility.process_form'))

    try:
        recovered_tonnage = float(recovered_tonnage)
        if recovered_tonnage <= 0:
            raise ValueError
    except ValueError:
        flash('Recovered tonnage must be positive.', 'danger')
        return redirect(url_for('facility.process_form'))

    # Validate event belongs to this facility
    event = query(
        'SELECT event_id, tonnage FROM waste_events WHERE event_id = %s AND facility_id = %s',
        (event_id, fid), fetchone=True
    )
    if not event:
        flash('Event not found or does not belong to this facility.', 'danger')
        return redirect(url_for('facility.process_form'))

    if recovered_tonnage > event['tonnage']:
        flash('Recovered tonnage cannot exceed input tonnage.', 'danger')
        return redirect(url_for('facility.process_form'))

    query("""
        INSERT INTO processing_outputs
            (event_id, facility_id, recovered_tonnage, output_type, processed_date, notes)
        VALUES (%s, %s, %s, %s, %s, %s)
    """, (event_id, fid, recovered_tonnage, output_type, processed_date, notes), commit=True)

    query("""
        UPDATE waste_events SET status = 'processed' WHERE event_id = %s
    """, (event_id,), commit=True)

    flash('Processing output logged. Business diversion metrics updated.', 'success')
    return redirect(url_for('facility.dashboard'))
