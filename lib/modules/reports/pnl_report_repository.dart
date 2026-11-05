import 'package:postgres/postgres.dart';
import '../../config/postgres.dart';

class PnlReportRepository {
  final Pool<dynamic>? _customPool;

  PnlReportRepository([Pool<dynamic>? pool]) : _customPool = pool;

  Pool<dynamic> get _pool => _customPool ?? PostgresConfig.pool;

  Future<List<Map<String, dynamic>>> getProductSales({
    String? storeId,
    String? warehouseId,
    String? categoryId,
    String? productId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final where = <String>[
      "LOWER(i.order_type) IN ('sale', 'sale return')",
      "LOWER(i.status) = 'completed'",
    ];
    final params = <String, dynamic>{};

    if (storeId != null && storeId.isNotEmpty) {
      where.add('i.store_id = @store_id');
      params['store_id'] = storeId;
    }
    if (warehouseId != null && warehouseId.isNotEmpty) {
      where.add('ii.warehouse_id = @warehouse_id');
      params['warehouse_id'] = warehouseId;
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      where.add('p.category_id = @category_id');
      params['category_id'] = categoryId;
    }
    if (productId != null && productId.isNotEmpty) {
      where.add('ii.product_id = @product_id');
      params['product_id'] = productId;
    }
    if (fromDate != null) {
      where.add('i.created_at >= @from_date');
      params['from_date'] = fromDate.toIso8601String();
    }
    if (toDate != null) {
      where.add('i.created_at <= @to_date');
      params['to_date'] = toDate.toIso8601String();
    }

    final sql = '''
      SELECT 
        ii.product_id,
        COALESCE(p.product_name, ii.product_name) AS product_name,
        COALESCE(p.product_category, '') AS category_name,
        COALESCE(p.purchase_price, 0.00)::float AS purchase_price,
        ROUND(CASE WHEN SUM(CASE WHEN LOWER(i.order_type) = 'sale' AND ii.product_quantity > 0 THEN ii.product_quantity ELSE 0 END) > 0
          THEN SUM(CASE WHEN LOWER(i.order_type) = 'sale' AND ii.product_quantity > 0 THEN ii.product_total ELSE 0 END) /
               SUM(CASE WHEN LOWER(i.order_type) = 'sale' AND ii.product_quantity > 0 THEN ii.product_quantity ELSE 0 END)
          ELSE 0 END, 2)::float AS sale_price,
        ROUND(SUM(CASE WHEN LOWER(i.order_type) = 'sale' AND ii.product_quantity > 0 THEN ii.product_quantity ELSE 0 END), 3)::float AS sold_qty,
        ROUND(SUM(CASE WHEN LOWER(i.order_type) = 'sale' AND ii.product_quantity > 0 THEN ii.product_total ELSE 0 END), 2)::float AS gross_sale,
        ROUND(SUM(CASE WHEN LOWER(i.order_type) = 'sale return' THEN ABS(ii.product_quantity) WHEN LOWER(i.order_type) = 'sale' AND ii.product_quantity < 0 THEN ABS(ii.product_quantity) ELSE 0 END), 3)::float AS return_qty,
        ROUND(SUM(CASE WHEN LOWER(i.order_type) = 'sale return' THEN ABS(ii.product_total) WHEN LOWER(i.order_type) = 'sale' AND ii.product_total < 0 THEN ABS(ii.product_total) ELSE 0 END), 2)::float AS return_amount,
        ROUND(SUM(CASE WHEN LOWER(i.order_type) = 'sale' AND ii.product_quantity > 0 THEN ii.product_quantity ELSE 0 END) - 
              SUM(CASE WHEN LOWER(i.order_type) = 'sale return' THEN ABS(ii.product_quantity) WHEN LOWER(i.order_type) = 'sale' AND ii.product_quantity < 0 THEN ABS(ii.product_quantity) ELSE 0 END), 3)::float AS net_qty,
        ROUND(SUM(CASE WHEN LOWER(i.order_type) = 'sale' AND ii.product_quantity > 0 THEN ii.product_quantity ELSE 0 END) - 
              SUM(CASE WHEN LOWER(i.order_type) = 'sale return' THEN ABS(ii.product_quantity) WHEN LOWER(i.order_type) = 'sale' AND ii.product_quantity < 0 THEN ABS(ii.product_quantity) ELSE 0 END), 3)::float AS quantity,
        ROUND(SUM(CASE WHEN LOWER(i.order_type) = 'sale' AND ii.product_quantity > 0 THEN ii.product_total ELSE 0 END) - 
              SUM(CASE WHEN LOWER(i.order_type) = 'sale return' THEN ABS(ii.product_total) WHEN LOWER(i.order_type) = 'sale' AND ii.product_total < 0 THEN ABS(ii.product_total) ELSE 0 END), 2)::float AS net_sale,
        ROUND((SUM(CASE WHEN LOWER(i.order_type) = 'sale' AND ii.product_quantity > 0 THEN ii.product_quantity ELSE 0 END) - 
               SUM(CASE WHEN LOWER(i.order_type) = 'sale return' THEN ABS(ii.product_quantity) WHEN LOWER(i.order_type) = 'sale' AND ii.product_quantity < 0 THEN ABS(ii.product_quantity) ELSE 0 END)) * COALESCE(p.purchase_price, 0.00), 2)::float AS total_cost,
        ROUND((SUM(CASE WHEN LOWER(i.order_type) = 'sale' AND ii.product_quantity > 0 THEN ii.product_total ELSE 0 END) - 
               SUM(CASE WHEN LOWER(i.order_type) = 'sale return' THEN ABS(ii.product_total) WHEN LOWER(i.order_type) = 'sale' AND ii.product_total < 0 THEN ABS(ii.product_total) ELSE 0 END)) -
              ((SUM(CASE WHEN LOWER(i.order_type) = 'sale' AND ii.product_quantity > 0 THEN ii.product_quantity ELSE 0 END) - 
                SUM(CASE WHEN LOWER(i.order_type) = 'sale return' THEN ABS(ii.product_quantity) WHEN LOWER(i.order_type) = 'sale' AND ii.product_quantity < 0 THEN ABS(ii.product_quantity) ELSE 0 END)) * COALESCE(p.purchase_price, 0.00)), 2)::float AS gross_profit
      FROM invoice_items ii
      JOIN invoices i ON i.id = ii.invoice_id
      LEFT JOIN products p ON p.id = ii.product_id
      WHERE ${where.join(' AND ')}
      GROUP BY ii.product_id, p.product_name, ii.product_name, p.product_category, p.purchase_price
      ORDER BY gross_sale DESC
    ''';

    final res = await _pool.execute(Sql.named(sql), parameters: params);
    return res.map((r) => r.toColumnMap()).toList();
  }

  Future<double> getTotalInvoiceDiscount({
    String? storeId,
    String? warehouseId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final where = <String>["LOWER(i.order_type) = 'sale'", "LOWER(i.status) = 'completed'"];
    final params = <String, dynamic>{};

    if (storeId != null && storeId.isNotEmpty) {
      where.add('i.store_id = @store_id');
      params['store_id'] = storeId;
    }
    if (warehouseId != null && warehouseId.isNotEmpty) {
      where.add('EXISTS (SELECT 1 FROM invoice_items ii WHERE ii.invoice_id = i.id AND ii.warehouse_id = @warehouse_id)');
      params['warehouse_id'] = warehouseId;
    }
    if (fromDate != null) {
      where.add('i.created_at >= @from_date');
      params['from_date'] = fromDate.toIso8601String();
    }
    if (toDate != null) {
      where.add('i.created_at <= @to_date');
      params['to_date'] = toDate.toIso8601String();
    }

    final sql = 'SELECT COALESCE(SUM(i.invoice_discount), 0.00)::float FROM invoices i WHERE ${where.join(' AND ')}';
    final res = await _pool.execute(Sql.named(sql), parameters: params);
    return (res.first[0] as num).toDouble();
  }

  Future<Map<String, String>> resolveFilterNames({
    String? storeId,
    String? warehouseId,
    String? categoryId,
  }) async {
    final names = <String, String>{};
    if (storeId != null && storeId.isNotEmpty) {
      final res = await _pool.execute(
        Sql.named('SELECT store_name FROM stores WHERE id = @id LIMIT 1'),
        parameters: {'id': storeId},
      );
      if (res.isNotEmpty) names['store_name'] = res.first[0]?.toString() ?? '';
    }
    if (warehouseId != null && warehouseId.isNotEmpty) {
      final res = await _pool.execute(
        Sql.named('SELECT name FROM warehouses WHERE id = @id LIMIT 1'),
        parameters: {'id': warehouseId},
      );
      if (res.isNotEmpty) names['warehouse_name'] = res.first[0]?.toString() ?? '';
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      final res = await _pool.execute(
        Sql.named('SELECT category_name FROM categories WHERE id = @id LIMIT 1'),
        parameters: {'id': categoryId},
      );
      if (res.isNotEmpty) names['category_name'] = res.first[0]?.toString() ?? '';
    }
    return names;
  }
}
