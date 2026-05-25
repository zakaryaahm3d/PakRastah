-- PakRastah Trigger Definitions
--
-- Execution chain (cascades top→down on each waste event lifecycle step):
--
--   INSERT on waste_events
--       → trg_waste_events_metrics (AFTER INSERT)
--           → fn_recompute_business_metrics()
--               → UPSERT into business_metrics
--                   → trg_business_metrics_certification (AFTER INSERT OR UPDATE)
--                       → fn_check_certification_eligibility()
--
--   INSERT on processing_outputs
--       → trg_processing_outputs_metrics (AFTER INSERT)
--           → fn_recompute_business_metrics()      [same function, same chain]
--
--   DELETE on waste_events | businesses | certifications | tax_credits | processing_outputs
--       → trg_audit_* (AFTER DELETE)
--           → fn_audit_delete()
--               → INSERT into audit_log            [terminal; never fires further triggers]

-- ============================================================
-- TRIGGER FUNCTION 1
-- Recomputes rolling 90-day diversion ratio for a business.
-- Fired by: trg_waste_events_metrics, trg_processing_outputs_metrics
-- Direction: event/output data → aggregate business_metrics
-- ============================================================
CREATE OR REPLACE FUNCTION fn_recompute_business_metrics()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_business_id     INTEGER;
    v_total_90d       NUMERIC;
    v_diverted_90d    NUMERIC;
    v_diverted_30d    NUMERIC;
    v_ratio           NUMERIC;
    v_cutoff_90       DATE := CURRENT_DATE - INTERVAL '90 days';
    v_cutoff_30       DATE := CURRENT_DATE - INTERVAL '30 days';
BEGIN
    IF TG_TABLE_NAME = 'waste_events' THEN
        v_business_id := NEW.business_id;
    ELSE
        -- processing_outputs → resolve business via the parent waste_event
        SELECT we.business_id INTO v_business_id
        FROM waste_events we
        WHERE we.event_id = NEW.event_id;
    END IF;

    -- Total waste tonnage in trailing 90 days
    SELECT COALESCE(SUM(we.tonnage), 0) INTO v_total_90d
    FROM waste_events we
    WHERE we.business_id = v_business_id
      AND we.event_date  >= v_cutoff_90;

    -- Diverted tonnage from processing outputs in trailing 90 days
    SELECT COALESCE(SUM(po.recovered_tonnage), 0) INTO v_diverted_90d
    FROM processing_outputs po
    JOIN waste_events we ON we.event_id = po.event_id
    WHERE we.business_id = v_business_id
      AND we.event_date  >= v_cutoff_90;

    -- Diverted tonnage in trailing 30 days (used by tax credit cursor)
    SELECT COALESCE(SUM(po.recovered_tonnage), 0) INTO v_diverted_30d
    FROM processing_outputs po
    JOIN waste_events we ON we.event_id = po.event_id
    WHERE we.business_id = v_business_id
      AND we.event_date  >= v_cutoff_30;

    IF v_total_90d > 0 THEN
        v_ratio := LEAST(v_diverted_90d / v_total_90d, 1.0);
    ELSE
        v_ratio := 0;
    END IF;

    INSERT INTO business_metrics
        (business_id, diversion_ratio, total_tonnage_90d,
         diverted_tonnage_90d, diverted_tonnage_30d, last_updated)
    VALUES
        (v_business_id, v_ratio, v_total_90d,
         v_diverted_90d, v_diverted_30d, NOW())
    ON CONFLICT (business_id) DO UPDATE
        SET diversion_ratio      = EXCLUDED.diversion_ratio,
            total_tonnage_90d    = EXCLUDED.total_tonnage_90d,
            diverted_tonnage_90d = EXCLUDED.diverted_tonnage_90d,
            diverted_tonnage_30d = EXCLUDED.diverted_tonnage_30d,
            last_updated         = NOW();

    RETURN NEW;
END;
$$;

-- Attach to waste_events (INSERT) — fires when business logs a pickup
CREATE TRIGGER trg_waste_events_metrics
AFTER INSERT ON waste_events
FOR EACH ROW EXECUTE FUNCTION fn_recompute_business_metrics();

-- Attach to processing_outputs (INSERT) — fires when facility logs processed output
CREATE TRIGGER trg_processing_outputs_metrics
AFTER INSERT ON processing_outputs
FOR EACH ROW EXECUTE FUNCTION fn_recompute_business_metrics();


-- ============================================================
-- TRIGGER FUNCTION 2
-- Manages certification queue based on diversion ratio threshold.
-- Fired by: trg_business_metrics_certification
-- Direction: business_metrics change → certification_queue action
-- ============================================================
CREATE OR REPLACE FUNCTION fn_check_certification_eligibility()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_tier              VARCHAR(10);
    v_has_active_queue  BOOLEAN;
    v_has_active_cert   BOOLEAN;
    v_active_cert_id    INTEGER;
BEGIN
    -- Derive expected tier from new ratio
    IF    NEW.diversion_ratio >= 0.90 THEN v_tier := 'gold';
    ELSIF NEW.diversion_ratio >= 0.75 THEN v_tier := 'silver';
    ELSIF NEW.diversion_ratio >= 0.60 THEN v_tier := 'bronze';
    ELSE                                    v_tier := NULL;
    END IF;

    IF NEW.diversion_ratio >= 0.60 THEN
        -- Check for any in-flight queue entry (avoids duplicate submissions)
        SELECT EXISTS (
            SELECT 1 FROM certification_queue
            WHERE business_id = NEW.business_id
              AND status IN ('eligible_for_review', 'under_review')
        ) INTO v_has_active_queue;

        -- Check for existing active approved certification
        SELECT EXISTS (
            SELECT 1
            FROM certifications c
            JOIN certification_queue cq ON cq.queue_id = c.queue_id
            WHERE c.business_id = NEW.business_id
              AND c.status      = 'active'
              AND cq.status     = 'approved'
        ) INTO v_has_active_cert;

        IF NOT v_has_active_queue AND NOT v_has_active_cert THEN
            INSERT INTO certification_queue (business_id, status, tier, submitted_at)
            VALUES (NEW.business_id, 'eligible_for_review', v_tier, NOW());
        END IF;

    ELSIF NEW.diversion_ratio < 0.60
      AND OLD.diversion_ratio >= 0.60 THEN
        -- Ratio dropped below threshold — revoke active cert and re-queue (option b)
        SELECT c.certification_id INTO v_active_cert_id
        FROM certifications c
        WHERE c.business_id = NEW.business_id
          AND c.status       = 'active'
        LIMIT 1;

        IF v_active_cert_id IS NOT NULL THEN
            UPDATE certifications
               SET status = 'revoked'
             WHERE certification_id = v_active_cert_id;

            INSERT INTO certification_queue
                (business_id, status, tier, submitted_at, notes)
            VALUES
                (NEW.business_id, 'under_review', NULL, NOW(),
                 'Diversion ratio dropped below 0.60 — automatic re-review triggered');
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

-- Fires after Trigger 1 upserts into business_metrics
CREATE TRIGGER trg_business_metrics_certification
AFTER INSERT OR UPDATE ON business_metrics
FOR EACH ROW EXECUTE FUNCTION fn_check_certification_eligibility();


-- ============================================================
-- TRIGGER FUNCTION 3
-- Audit log on DELETE across key tables.
-- Fired by: five trg_audit_* triggers below
-- Direction: terminal — writes to audit_log only, never modifies source tables
-- ============================================================
CREATE OR REPLACE FUNCTION fn_audit_delete()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_row_id INTEGER;
BEGIN
    CASE TG_TABLE_NAME
        WHEN 'waste_events'       THEN v_row_id := OLD.event_id;
        WHEN 'businesses'         THEN v_row_id := OLD.business_id;
        WHEN 'certifications'     THEN v_row_id := OLD.certification_id;
        WHEN 'tax_credits'        THEN v_row_id := OLD.credit_id;
        WHEN 'processing_outputs' THEN v_row_id := OLD.output_id;
        ELSE                           v_row_id := NULL;
    END CASE;

    INSERT INTO audit_log
        (table_name, operation, row_id, performed_by, performed_at, old_data, context)
    VALUES (
        TG_TABLE_NAME,
        'DELETE',
        v_row_id,
        current_user,
        NOW(),
        to_jsonb(OLD),
        'Row deleted from ' || TG_TABLE_NAME || ' (id=' || COALESCE(v_row_id::TEXT,'?') || ')'
    );

    RETURN OLD;
END;
$$;

CREATE TRIGGER trg_audit_waste_events
AFTER DELETE ON waste_events
FOR EACH ROW EXECUTE FUNCTION fn_audit_delete();

CREATE TRIGGER trg_audit_businesses
AFTER DELETE ON businesses
FOR EACH ROW EXECUTE FUNCTION fn_audit_delete();

CREATE TRIGGER trg_audit_certifications
AFTER DELETE ON certifications
FOR EACH ROW EXECUTE FUNCTION fn_audit_delete();

CREATE TRIGGER trg_audit_tax_credits
AFTER DELETE ON tax_credits
FOR EACH ROW EXECUTE FUNCTION fn_audit_delete();

CREATE TRIGGER trg_audit_processing_outputs
AFTER DELETE ON processing_outputs
FOR EACH ROW EXECUTE FUNCTION fn_audit_delete();
