import 'package:postgres/postgres.dart';
import '../../config/postgres.dart';

class EmployeeCommissionRepository {
  final Pool<dynamic>? _customPool;

  EmployeeCommissionRepository([Pool<dynamic>? pool]) : _customPool = pool;

  Pool<dynamic> get _pool => _customPool ?? PostgresConfig.pool;

  Future<List<Map<String, dynamic>>> getCommissionSummary({
    String? storeId,
    String? employeeId,
    String? warehouseId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final where = <String>[
      "LOWER(i.status) = 'completed'",
      "LOWER(i.order_type) IN ('sale', 'sale return')",
    ];
    final params = <String, dynamic>{};

    if (storeId != null && storeId.isNotEmpty) {
      where.add('i.store_id = @store_id');
      params['store_id'] = storeId;
    }
    if (employeeId != null && employeeId.isNotEmpty) {
      where.add('e.id = @employee_id');
      params['employee_id'] = employeeId;
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

    final sql = '''
      SELECT
        e.id AS employee_id,
        e.name AS employee_name,
        COALESCE(e.commission_percent, 0.00)::float AS commission_percent,
        COUNT(i.id)::int AS total_invoices,
        ROUND(SUM(CASE WHEN LOWER(i.order_type) = 'sale' THEN i.invoice_total ELSE 0 END), 2)::float AS gross_sales,
        ROUND(SUM(CASE WHEN LOWER(i.order_type) = 'sale return' THEN i.invoice_total ELSE 0 END), 2)::float AS return_amount,
        ROUND(SUM(CASE WHEN LOWER(i.order_type) = 'sale' THEN i.invoice_total WHEN LOWER(i.order_type) = 'sale return' THEN -i.invoice_total ELSE 0 END), 2)::float AS net_sales,
        ROUND(SUM(CASE WHEN LOWER(i.order_type) = 'sale' THEN i.invoice_total WHEN LOWER(i.order_type) = 'sale return' THEN -i.invoice_total ELSE 0 END) * (COALESCE(e.commission_percent, 0.00) / 100.0), 2)::float AS total_commission
      FROM employees e
      JOIN invoices i ON (i.custom_fields->>'employee_id') = e.id
      WHERE ${where.join(' AND ')}
      GROUP BY e.id, e.name, e.commission_percent
      ORDER BY total_commission DESC, net_sales DESC;
    ''';

    final res = await _pool.execute(Sql.named(sql), parameters: params);
    return res.map((r) => r.toColumnMap()).toList();
  }

  Future<List<Map<String, dynamic>>> getEmployeeInvoices({
    required String employeeId,
    String? storeId,
    String? warehouseId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final where = <String>[
      "e.id = @employee_id",
      "LOWER(i.status) = 'completed'",
      "LOWER(i.order_type) IN ('sale', 'sale return')",
    ];
    final params = <String, dynamic>{'employee_id': employeeId};

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

    final sql = '''
      SELECT
        i.id AS invoice_id,
        i.order_number,
        i.order_type,
        i.created_at,
        i.invoice_total::float,
        COALESCE(e.commission_percent, 0.00)::float AS commission_percent,
        ROUND((CASE WHEN LOWER(i.order_type) = 'sale return' THEN -i.invoice_total ELSE i.invoice_total END) * (COALESCE(e.commission_percent, 0.00) / 100.0), 2)::float AS commission_amount
      FROM invoices i
      JOIN employees e ON (i.custom_fields->>'employee_id') = e.id
      WHERE ${where.join(' AND ')}
      ORDER BY i.created_at DESC;
    ''';

    final res = await _pool.execute(Sql.named(sql), parameters: params);
    return res.map((r) => r.toColumnMap()).toList();
  }

  Future<Map<String, String>> resolveFilterNames({
    String? storeId,
    String? warehouseId,
    String? employeeId,
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
    if (employeeId != null && employeeId.isNotEmpty) {
      final res = await _pool.execute(
        Sql.named('SELECT name FROM employees WHERE id = @id LIMIT 1'),
        parameters: {'id': employeeId},
      );
      if (res.isNotEmpty) names['employee_name'] = res.first[0]?.toString() ?? '';
    }
    return names;
  }
}
