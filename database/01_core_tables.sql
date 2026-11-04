CREATE TABLE IF NOT EXISTS stores (
    id VARCHAR(64) PRIMARY KEY,
    store_name VARCHAR(255) NOT NULL,
    store_domain VARCHAR(100),
    store_contact VARCHAR(50),
    store_address TEXT,
    store_currency VARCHAR(20) DEFAULT 'Rs',
    store_logo TEXT,
    store_type VARCHAR(50),
    active_plan VARCHAR(50),
    tax_enabled BOOLEAN DEFAULT FALSE,
    discount_enabled BOOLEAN DEFAULT FALSE,
    service_charges_enabled BOOLEAN DEFAULT FALSE,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    store_id VARCHAR(64) REFERENCES stores(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    pass VARCHAR(255),
    role VARCHAR(50) NOT NULL DEFAULT 'till',
    till_no VARCHAR(50),
    subscription_status VARCHAR(50) DEFAULT 'active',
    category_count INT DEFAULT 0,
    product_count INT DEFAULT 0,
    device_id VARCHAR(255),
    device_ids JSONB DEFAULT '[]',
    order_count JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS categories (
    id VARCHAR(64) PRIMARY KEY,
    store_id VARCHAR(64) REFERENCES stores(id) ON DELETE CASCADE,
    category_code VARCHAR(50),
    category_name VARCHAR(255) NOT NULL,
    category_type VARCHAR(50) DEFAULT 'finished',
    is_active BOOLEAN DEFAULT TRUE,
    product_count INT DEFAULT 0,
    created_by VARCHAR(64),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS warehouses (
    id VARCHAR(64) PRIMARY KEY,
    store_id VARCHAR(64) REFERENCES stores(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    number VARCHAR(50),
    incharge VARCHAR(255),
    address TEXT,
    branch_id VARCHAR(64),
    till_ids JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS customers (
    id VARCHAR(64) PRIMARY KEY,
    store_id VARCHAR(64) REFERENCES stores(id) ON DELETE CASCADE,
    customer_name VARCHAR(255) NOT NULL,
    customer_phone VARCHAR(50),
    customer_cnic VARCHAR(50),
    customer_address TEXT,
    customer_type VARCHAR(50) DEFAULT 'customer',
    area_id VARCHAR(64),
    opening_balance NUMERIC(14, 2) DEFAULT 0.00,
    balance NUMERIC(14, 2) DEFAULT 0.00,
    disc_percentage NUMERIC(6, 2) DEFAULT 0.00,
    loyalty_card BOOLEAN DEFAULT FALSE,
    description TEXT,
    daily_closing JSONB DEFAULT '{}',
    created_by VARCHAR(64),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS employees (
    id VARCHAR(64) PRIMARY KEY,
    store_id VARCHAR(64) REFERENCES stores(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    cnic VARCHAR(50),
    address TEXT,
    salary NUMERIC(14, 2) DEFAULT 0.00,
    commission_percent NUMERIC(6, 2) DEFAULT 0.00,
    balance NUMERIC(14, 2) DEFAULT 0.00,
    till_id VARCHAR(64),
    till_no VARCHAR(50),
    created_by VARCHAR(64),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
