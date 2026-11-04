-- Multi-tenant & reporting performance indexes

-- Invoices: fast date range & store aggregations
CREATE INDEX IF NOT EXISTS idx_invoices_store_created 
    ON invoices(store_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_invoices_store_type_status 
    ON invoices(store_id, order_type, status);

CREATE INDEX IF NOT EXISTS idx_invoices_customer 
    ON invoices(store_id, customer_id);

CREATE INDEX IF NOT EXISTS idx_invoices_order_number 
    ON invoices(store_id, order_number);

-- Invoice items: fast sales by product/category/warehouse
CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice 
    ON invoice_items(invoice_id);

CREATE INDEX IF NOT EXISTS idx_invoice_items_store_product 
    ON invoice_items(store_id, product_id);

CREATE INDEX IF NOT EXISTS idx_invoice_items_store_warehouse 
    ON invoice_items(store_id, warehouse_id);

CREATE INDEX IF NOT EXISTS idx_invoice_items_store_created 
    ON invoice_items(store_id, created_at DESC);

-- Payments: customer balance & date reports
CREATE INDEX IF NOT EXISTS idx_payments_store_date 
    ON payments(store_id, payment_date DESC);

CREATE INDEX IF NOT EXISTS idx_payments_customer 
    ON payments(store_id, customer_id);

CREATE INDEX IF NOT EXISTS idx_payments_type 
    ON payments(store_id, payment_type);

-- Products: lookup & category filtering
CREATE INDEX IF NOT EXISTS idx_products_store_category 
    ON products(store_id, category_id);

CREATE INDEX IF NOT EXISTS idx_products_barcode 
    ON products(store_id, bar_code);

-- Stock transfers: movement audit
CREATE INDEX IF NOT EXISTS idx_stock_transfers_store_date 
    ON stock_transfers(store_id, transfer_date DESC);

-- Invoice reports: daily till closing lookups
CREATE INDEX IF NOT EXISTS idx_invoice_reports_store_date 
    ON invoice_reports(store_id, report_date DESC);
