from datetime import datetime, date, timedelta
from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from ..auth import login_required
from ..db import query, get_db

auditor_bp = Blueprint('auditor', __name__)


@auditor_bp.route('/')
@login_required(roles=['auditor'])
def queue():
    entries = query("""
        SELECT
            cq.queue_id, cq.status, cq.tier, cq.submitted_at, cq.notes,
            b.business_id, b.name AS business_name, b.city, b.category,
            bm.diversion_ratio, bm.total_tonnage_90d, bm.diverted_tonnage_90d,
            bm.last_updated
        FROM certification_queue cq
        JOIN businesses      b  ON b.business_id  = cq.business_id
        LEFT JOIN business_metrics bm ON bm.business_id = cq.business_id
        WHERE cq.status IN ('eligible_for_review','under_review')
        ORDER BY cq.submitted_at ASC
    """, fetchall=True)

    history = query("""
        SELECT
            cq.queue_id, cq.status, cq.tier, cq.reviewed_at,
            b.name AS business_name,
            u.full_name AS reviewer_name,
            c.cert_number
        FROM certification_queue cq
        JOIN businesses b ON b.business_id = cq.business_id
        LEFT JOIN users u ON u.user_id = cq.reviewer_id
        LEFT JOIN certifications c ON c.queue_id = cq.queue_id
        WHERE cq.status IN ('approved','denied')
        ORDER BY cq.reviewed_at DESC
        LIMIT 10
    """, fetchall=True)

    return render_template('auditor/queue.html', entries=entries, history=history)


@auditor_bp.route('/certifications/<int:queue_id>/approve', methods=['POST'])
@login_required(roles=['auditor'])
def approve(queue_id):
    notes = request.form.get('notes', '').strip() or None

    entry = query(
        'SELECT * FROM certification_queue WHERE queue_id = %s AND status IN (%s,%s)',
        (queue_id, 'eligible_for_review', 'under_review'), fetchone=True
    )
    if not entry:
        if request.headers.get('HX-Request'):
            return '<span class="text-red-500 text-sm">Entry not found or already processed.</span>', 404
        flash('Certification entry not found or already processed.', 'danger')
        return redirect(url_for('auditor.queue'))

    db = get_db()
    cur = db.cursor()

    cur.execute("""
        UPDATE certification_queue
           SET status = 'approved', reviewed_at = NOW(), reviewer_id = %s, notes = %s
         WHERE queue_id = %s
    """, (session['user_id'], notes, queue_id))

    tier = entry['tier'] or 'bronze'
    cert_number = f"CERT-PKR-{datetime.now().year}-{queue_id:04d}"
    expiry_date = date.today() + timedelta(days=365)

    cur.execute("""
        INSERT INTO certifications
            (business_id, queue_id, cert_number, tier, issued_date, expiry_date, status)
        VALUES (%s, %s, %s, %s, CURRENT_DATE, %s, 'active')
        RETURNING certification_id
    """, (entry['business_id'], queue_id, cert_number, tier, expiry_date))

    db.commit()
    cur.close()

    if request.headers.get('HX-Request'):
        return render_template('auditor/_approved_row.html',
                               queue_id=queue_id, cert_number=cert_number,
                               tier=tier, business_id=entry['business_id'])

    flash(f'Certification {cert_number} issued.', 'success')
    return redirect(url_for('auditor.queue'))


@auditor_bp.route('/certifications/<int:queue_id>/deny', methods=['POST'])
@login_required(roles=['auditor'])
def deny(queue_id):
    notes = request.form.get('notes', '').strip() or 'Denied by auditor.'

    entry = query(
        'SELECT * FROM certification_queue WHERE queue_id = %s AND status IN (%s,%s)',
        (queue_id, 'eligible_for_review', 'under_review'), fetchone=True
    )
    if not entry:
        flash('Entry not found.', 'danger')
        return redirect(url_for('auditor.queue'))

    query("""
        UPDATE certification_queue
           SET status = 'denied', reviewed_at = NOW(), reviewer_id = %s, notes = %s
         WHERE queue_id = %s
    """, (session['user_id'], notes, queue_id), commit=True)

    if request.headers.get('HX-Request'):
        return render_template('auditor/_denied_row.html', queue_id=queue_id)

    flash('Certification denied.', 'info')
    return redirect(url_for('auditor.queue'))
