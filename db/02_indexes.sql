-- PakRastah Indexes
-- Run EXPLAIN ANALYZE output captured in index_justifications.md

-- Supports role-filtered nav queries and user lookups at login
CREATE INDEX idx_users_role ON users(role);

-- Core query: business dashboard loads all events for one business ordered by date
CREATE INDEX idx_waste_events_business_date ON waste_events(business_id, event_date DESC);

-- Auditor queue page filters by status
CREATE INDEX idx_certifications_status ON certifications(status);

-- Certification queue filtered by status (auditor queue, trigger eligibility check)
CREATE INDEX idx_cert_queue_business_status ON certification_queue(business_id, status);

-- Marketplace stub page filters by category and status
CREATE INDEX idx_marketplace_category_status ON marketplace_listings(category, status);

-- Processing outputs looked up by facility (facility dashboard)
CREATE INDEX idx_processing_outputs_facility ON processing_outputs(facility_id, processed_date DESC);

-- Audit log queried by table and time for developer panel
CREATE INDEX idx_audit_log_table_time ON audit_log(table_name, performed_at DESC);

-- Food rescue stub page filters by charity and date
CREATE INDEX idx_food_donations_charity_date ON food_donations(charity_id, donation_date DESC);

-- Tax credits per business (business dashboard)
CREATE INDEX idx_tax_credits_business ON tax_credits(business_id, calculation_date DESC);

-- Wallet transaction history per user
CREATE INDEX idx_wallet_txns_user ON wallet_transactions(user_id, created_at DESC);
