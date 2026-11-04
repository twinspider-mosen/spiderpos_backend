CREATE TABLE IF NOT EXISTS invoice_reports (
    id VARCHAR(64) PRIMARY KEY,
    store_id VARCHAR(64) NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    till_id VARCHAR(64),
    report_date DATE,
    total NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    total_cash NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    total_credit NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    type VARCHAR(50),
    summary JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS salaries (
    id VARCHAR(64) PRIMARY KEY,
    store_id VARCHAR(64) NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    month VARCHAR(50) NOT NULL,
    month_id VARCHAR(20) NOT NULL,
    total_gross_salary NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    total_commissions NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    total_advances NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    employees JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS app_configs (
    id VARCHAR(64) PRIMARY KEY,
    app_type JSONB DEFAULT '[]',
    app_features JSONB DEFAULT '{}',
    debug JSONB DEFAULT '{}',
    release JSONB DEFAULT '{}',
    config_data JSONB DEFAULT '{}',
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
