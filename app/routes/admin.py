from flask import Blueprint, render_template
from ..auth import login_required
from ..db import query

admin_bp = Blueprint('admin', __name__)


@admin_bp.route('/')
@login_required(roles=['admin'])
def dashboard():
    # 4-table join: INNER JOIN to active businesses with events,
    # LEFT JOIN for certifications/credits they may not yet have.
    report = query("""
        SELECT
            b.business_id,
            b.name          AS business_name,
            b.city,
            b.category,
            COUNT(DISTINCT we.event_id)                             AS total_events,
            COALESCE(SUM(we.tonnage), 0)                            AS total_tonnage_kg,
            ROUND(COALESCE(bm.diversion_ratio, 0) * 100, 1)        AS diversion_pct,
            c.tier                                                  AS cert_tier,
            c.status                                                AS cert_status,
            COALESCE(SUM(tc.amount_pkr), 0)                         AS total_credits_pkr
        FROM businesses b
        INNER JOIN waste_events we   ON we.business_id = b.business_id
        LEFT  JOIN business_metrics  bm ON bm.business_id = b.business_id
        LEFT  JOIN certifications    c  ON c.business_id  = b.business_id AND c.status = 'active'
        LEFT  JOIN tax_credits       tc ON tc.business_id = b.business_id
        GROUP BY b.business_id, b.name, b.city, b.category,
                 bm.diversion_ratio, c.tier, c.status
        ORDER BY total_tonnage_kg DESC
    """, fetchall=True)

    counts = query("""
        SELECT
            (SELECT COUNT(*) FROM businesses)                                  AS businesses,
            (SELECT COUNT(*) FROM waste_events)                                AS waste_events,
            (SELECT COUNT(*) FROM certifications WHERE status = 'active')      AS active_certs,
            (SELECT COUNT(*) FROM certification_queue
             WHERE status = 'eligible_for_review')                             AS pending_reviews,
            (SELECT COALESCE(SUM(amount_pkr),0) FROM tax_credits)              AS total_credits_pkr,
            (SELECT COUNT(*) FROM food_donations)                              AS food_donations,
            (SELECT COUNT(*) FROM marketplace_listings WHERE status = 'active') AS active_listings
    """, fetchone=True)

    queue = query("""
        SELECT cq.queue_id, b.name, cq.tier, cq.status, cq.submitted_at
        FROM certification_queue cq
        JOIN businesses b ON b.business_id = cq.business_id
        WHERE cq.status IN ('eligible_for_review','under_review')
        ORDER BY cq.submitted_at
    """, fetchall=True)

    return render_template('admin/dashboard.html',
                           report=report, counts=counts, queue=queue)
