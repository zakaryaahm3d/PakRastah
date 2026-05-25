-- PakRastah Stored Procedure: apply_monthly_tax_credits()
--
-- Uses an explicit cursor over approved businesses (row-by-row processing).
--
-- Cursor justification:
--   Each iteration performs THREE operations bound to that specific row:
--     1. Reads the business's live diversion_ratio to apply the current tier rate
--        (tier may differ from the cert tier if the ratio has shifted since approval).
--     2. Inserts a tax_credit row with a generated procedure_run_id unique to this run.
--     3. Inserts a per-row narrative audit_log entry that cannot be generated
--        by a set-based UPDATE without a second cursor pass anyway.
--   A single set-based statement cannot atomically write the contextual audit
--   narrative per row — the cursor IS the mechanism, not a workaround.

CREATE OR REPLACE PROCEDURE apply_monthly_tax_credits(
    OUT p_businesses_processed INTEGER,
    OUT p_total_credit_pkr     NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    cur_approved CURSOR FOR
        SELECT
            b.business_id,
            b.name                    AS business_name,
            b.city,
            c.certification_id,
            bm.diversion_ratio,
            bm.diverted_tonnage_30d
        FROM certifications c
        JOIN businesses      b  ON b.business_id  = c.business_id
        JOIN business_metrics bm ON bm.business_id = c.business_id
        JOIN certification_queue cq ON cq.queue_id = c.queue_id
        WHERE c.status   = 'active'
          AND cq.status  = 'approved'
          AND bm.diverted_tonnage_30d > 0
        FOR READ ONLY;

    rec             RECORD;
    v_rate          NUMERIC(10,2);
    v_tier          VARCHAR(10);
    v_credit_amount NUMERIC(14,2);
    v_run_id        VARCHAR(60) := 'RUN-' || TO_CHAR(NOW(), 'YYYYMMDD-HH24MISS');
BEGIN
    p_businesses_processed := 0;
    p_total_credit_pkr     := 0;

    OPEN cur_approved;

    LOOP
        FETCH cur_approved INTO rec;
        EXIT WHEN NOT FOUND;

        -- Apply tiered rate based on live diversion_ratio (not frozen cert tier)
        IF rec.diversion_ratio >= 0.90 THEN
            v_rate := 1200.00;
            v_tier := 'gold';
        ELSIF rec.diversion_ratio >= 0.75 THEN
            v_rate := 800.00;
            v_tier := 'silver';
        ELSE
            v_rate := 500.00;
            v_tier := 'bronze';
        END IF;

        -- tonnage stored in kg; rate is PKR per tonne → divide by 1000
        v_credit_amount := (rec.diverted_tonnage_30d / 1000.0) * v_rate;

        INSERT INTO tax_credits (
            business_id, certification_id, amount_pkr,
            diverted_tonnage, tier, rate_per_tonne_pkr,
            calculation_date, procedure_run_id
        ) VALUES (
            rec.business_id, rec.certification_id, v_credit_amount,
            rec.diverted_tonnage_30d, v_tier, v_rate,
            CURRENT_DATE, v_run_id
        );

        -- Per-row audit entry — this side-effect is the canonical justification for the cursor
        INSERT INTO audit_log
            (table_name, operation, row_id, performed_by, performed_at, old_data, context)
        VALUES (
            'tax_credits',
            'INSERT',
            NULL,
            'system:apply_monthly_tax_credits',
            NOW(),
            NULL,
            FORMAT(
                '[%s] Business "%s" (id=%s, city=%s) | %.3f kg diverted (30d) | %s tier | '
                || 'PKR %.2f/tonne | Credit = PKR %.2f',
                v_run_id,
                rec.business_name, rec.business_id, rec.city,
                rec.diverted_tonnage_30d,
                v_tier, v_rate, v_credit_amount
            )
        );

        p_businesses_processed := p_businesses_processed + 1;
        p_total_credit_pkr     := p_total_credit_pkr + v_credit_amount;
    END LOOP;

    CLOSE cur_approved;
    -- Caller is responsible for COMMIT (Python commits after CALL)
END;
$$;
