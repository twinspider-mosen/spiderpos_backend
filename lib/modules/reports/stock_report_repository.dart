import 'package:postgres/postgres.dart';
import '../../config/postgres.dart';

class StockReportRepository {
  final Pool<dynamic>? _customPool;

  StockReportRepository([Pool<dynamic>? pool]) : _customPool = pool;

  Pool<dynamic> get _pool => _customPool ?? PostgresConfig.pool;

  Future<List<Map<String, dynamic>>> getStock({
    String? storeId,
    String? warehouseId,
    String? categoryId,
    String? productId,
    DateTime? toDate,
  }) async {
    final where = <String>["LOWER(i.status) = 'completed'"];
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
        ROUND(SUM(CASE WHEN LOWER(i.order_type) = 'purchase' THEN ii.product_quantity ELSE 0 END), 3)::float AS purchased_qty,
        ROUND(SUM(CASE WHEN LOWER(i.order_type) = 'sale return' THEN ii.product_quantity ELSE 0 END), 3)::float AS sale_returned_qty,
        ROUND(SUM(CASE WHEN LOWER(i.order_type) = 'sale' THEN ii.product_quantity ELSE 0 END), 3)::float AS sold_qty,
        ROUND(SUM(CASE WHEN LOWER(i.order_type) = 'purchase return' THEN ii.product_quantity ELSE 0 END), 3)::float AS purchase_returned_qty,
        ROUND(SUM(CASE WHEN LOWER(i.order_type) IN ('purchase', 'sale return') THEN ii.product_quantity ELSE -ii.product_quantity END), 3)::float AS active_stock,
        ROUND(SUM(CASE WHEN LOWER(i.order_type) IN ('purchase', 'sale return') THEN ii.product_quantity ELSE -ii.product_quantity END) * COALESCE(p.purchase_price, 0.00), 2)::float AS stock_value
      FROM invoice_items ii
      JOIN invoices i ON i.id = ii.invoice_id
      LEFT JOIN products p ON p.id = ii.product_id
      WHERE ${where.join(' AND ')}
      GROUP BY ii.product_id, p.product_name, ii.product_name, p.product_category, p.purchase_price
      ORDER BY active_stock DESC, product_name ASC;
    ''';

    final res = await _pool.execute(Sql.named(sql), parameters: params);
    return res.map((r) => r.toColumnMap()).toList();
  }

  Future<Map<String, String>> resolveFilterNames({
    String? storeId,
    String? warehouseId,
    String? categoryId,
    String? productId,
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
    if (productId != null && productId.isNotEmpty) {
      final res = await _pool.execute(
        Sql.named('SELECT product_name FROM products WHERE id = @id LIMIT 1'),
        parameters: {'id': productId},
      );
      if (res.isNotEmpty) names['product_name'] = res.first[0]?.toString() ?? '';
    }
    return names;
  }
}
