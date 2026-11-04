import 'dart:convert';
import 'package:postgres/postgres.dart';
import '../config/postgres.dart';

class PostgresService {
  final Pool<dynamic>? _customPool;

  static const validTables = {
    'stores',
    'users',
    'categories',
    'warehouses',
    'customers',
    'employees',
    'products',
    'stock_transfers',
    'product_stocks',
    'invoices',
    'invoice_items',
    'payments',
    'salaries',
    'invoice_reports',
    'app_configs',
  };

  PostgresService([Pool<dynamic>? pool]) : _customPool = pool;

  Pool<dynamic> get _pool => _customPool ?? PostgresConfig.pool;

  void _assertValidTable(String table) {
    if (!validTables.contains(table)) {
      throw ArgumentError('Invalid table name: $table');
    }
  }

  Future<List<Map<String, dynamic>>> listRows(
    String table, {
    int? limit,
    int? offset,
    String? storeId,
    String? orderBy,
    bool descending = false,
  }) async {
    _assertValidTable(table);

    final conditions = <String>[];
    final params = <String, dynamic>{};

    if (storeId != null && storeId.isNotEmpty) {
      conditions.add('store_id = @store_id');
      params['store_id'] = storeId;
    }

    var sql = 'SELECT * FROM $table';
    if (conditions.isNotEmpty) {
      sql += ' WHERE ${conditions.join(' AND ')}';
    }

    final safeOrder = (orderBy != null && RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(orderBy))
        ? orderBy
        : 'created_at';
    final dir = descending ? 'DESC' : 'ASC';
    sql += ' ORDER BY $safeOrder $dir';

    final safeLimit = (limit != null && limit > 0) ? limit : 100;
    sql += ' LIMIT $safeLimit';

    if (offset != null && offset > 0) {
      sql += ' OFFSET $offset';
    }

    final result = await _pool.execute(Sql.named(sql), parameters: params);
    return result
        .map((row) => _sanitize(row.toColumnMap()) as Map<String, dynamic>)
        .toList();
  }

  Future<Map<String, dynamic>?> getRow(String table, String id) async {
    _assertValidTable(table);
    final sql = 'SELECT * FROM $table WHERE id = @id LIMIT 1';
    final result = await _pool.execute(Sql.named(sql), parameters: {'id': id});
    if (result.isEmpty) return null;
    return _sanitize(result.first.toColumnMap()) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> insertRow(
    String table,
    Map<String, dynamic> data,
  ) async {
    _assertValidTable(table);
    final cols = data.keys.toList();
    final placeholders = cols.map((c) => '@$c').join(', ');
    final sql = 'INSERT INTO $table (${cols.join(', ')}) VALUES ($placeholders) RETURNING *';

    final result = await _pool.execute(
      Sql.named(sql),
      parameters: _encodeParams(data),
    );
    return _sanitize(result.first.toColumnMap()) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> updateRow(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    _assertValidTable(table);
    final updates = data.keys.map((c) => '$c = @$c').join(', ');
    final sql = 'UPDATE $table SET $updates WHERE id = @id RETURNING *';

    final params = _encodeParams(data)..['id'] = id;
    final result = await _pool.execute(Sql.named(sql), parameters: params);
    if (result.isEmpty) return null;
    return _sanitize(result.first.toColumnMap()) as Map<String, dynamic>;
  }

  Future<bool> deleteRow(String table, String id) async {
    _assertValidTable(table);
    final sql = 'DELETE FROM $table WHERE id = @id';
    final result = await _pool.execute(Sql.named(sql), parameters: {'id': id});
    return result.affectedRows > 0;
  }

  Map<String, dynamic> _encodeParams(Map<String, dynamic> data) {
    return data.map((key, val) {
      if (val is Map || val is List) return MapEntry(key, jsonEncode(val));
      return MapEntry(key, val);
    });
  }

  dynamic _sanitize(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val.toIso8601String();
    if (val is Map) return val.map((k, v) => MapEntry(k.toString(), _sanitize(v)));
    if (val is Iterable) return val.map(_sanitize).toList();
    return val;
  }
}
