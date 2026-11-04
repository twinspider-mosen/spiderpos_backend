CREATE TABLE IF NOT EXISTS products (
    id VARCHAR(64) PRIMARY KEY,
    store_id VARCHAR(64) REFERENCES stores(id) ON DELETE CASCADE,
    category_id VARCHAR(64) REFERENCES categories(id) ON DELETE SET NULL,
    product_name VARCHAR(255) NOT NULL,
    product_code VARCHAR(50),
    bar_code VARCHAR(50),
    product_category VARCHAR(100),
    category_code VARCHAR(50),
    product_type VARCHAR(50) DEFAULT 'finished',
    product_price NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    purchase_price NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    unit_price NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    discount_percentage NUMERIC(6, 2) DEFAULT 0.00,
    tax_rate NUMERIC(6, 2),
    further_tax NUMERIC(6, 2),
    pct_code VARCHAR(50),
    unit_multiple INT DEFAULT 1,
    min_quantity NUMERIC(12, 3) DEFAULT 0.000,
    is_active BOOLEAN DEFAULT TRUE,
    serial_enabled BOOLEAN DEFAULT FALSE,
    product_description TEXT,
    product_image TEXT,
    composition JSONB DEFAULT '[]',
    serial_no JSONB DEFAULT '[]',
    daily_closing JSONB DEFAULT '{}',
    created_by VARCHAR(64),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stock_transfers (
    id VARCHAR(64) PRIMARY KEY,
    store_id VARCHAR(64) REFERENCES stores(id) ON DELETE CASCADE,
    product_id VARCHAR(64) REFERENCES products(id) ON DELETE SET NULL,
    product_name VARCHAR(255) NOT NULL,
    from_warehouse_id VARCHAR(64) REFERENCES warehouses(id) ON DELETE SET NULL,
    from_warehouse_name VARCHAR(255),
    to_warehouse_id VARCHAR(64) REFERENCES warehouses(id) ON DELETE SET NULL,
    to_warehouse_name VARCHAR(255),
    quantity NUMERIC(12, 3) NOT NULL DEFAULT 0.000,
    transferred_by VARCHAR(100),
    transfer_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS product_stocks (
    id VARCHAR(64) PRIMARY KEY,
    store_id VARCHAR(64) REFERENCES stores(id) ON DELETE CASCADE,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    warehouse_stock JSONB DEFAULT '{}',
    transactions JSONB DEFAULT '{}',
    product_names JSONB DEFAULT '{}'
);
