import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import '../config/postgres.dart';

class ImportService {
  final Pool<dynamic> _pool;

  ImportService([Pool<dynamic>? pool]) : _pool = pool ?? PostgresConfig.pool;

  Future<int> importFile(String file, String table, {Map<String, String>? aliases}) async {
    final f = File('data/samples/$file');
    if (!f.existsSync()) return 0;

    final records = (jsonDecode(await f.readAsString()) as List).cast<Map<String, dynamic>>();
    if (records.isEmpty) return 0;

    final cols = await _getTableColumns(table);
    var count = 0;

    for (final raw in records) {
      final row = _mapRow(raw, cols, aliases);
      if (row.isEmpty || row['id'] == null) continue;

      final keys = row.keys.toList();
      final placeholders = keys.map((k) => '@$k').join(', ');
      final sql = 'INSERT INTO $table (${keys.join(', ')}) VALUES ($placeholders) ON CONFLICT (id) DO NOTHING';

      final res = await _pool.execute(Sql.named(sql), parameters: _encode(row));
      count += res.affectedRows;

      if (table == 'invoices' && raw['invoice_items'] is List) {
        await _importInvoiceItems(raw['id'].toString(), raw['store_id']?.toString() ?? '', raw['invoice_items'] as List);
      }
    }
    return count;
  }

  Future<void> _importInvoiceItems(String invoiceId, String storeId, List items) async {
    final itemCols = await _getTableColumns('invoice_items');
    for (final it in items.whereType<Map<String, dynamic>>()) {
      final mapped = _mapRow(it, itemCols, null)
        ..['invoice_id'] = invoiceId
        ..['store_id'] = storeId
        ..remove('id');

      final keys = mapped.keys.toList();
      final placeholders = keys.map((k) => '@$k').join(', ');
      final sql = 'INSERT INTO invoice_items (${keys.join(', ')}) VALUES ($placeholders)';
      await _pool.execute(Sql.named(sql), parameters: _encode(mapped));
    }
  }

  Future<Set<String>> _getTableColumns(String table) async {
    final res = await _pool.execute(
      Sql.named('SELECT column_name FROM information_schema.columns WHERE table_name = @t'),
      parameters: {'t': table},
    );
    return res.map((r) => r[0] as String).toSet();
  }

  Map<String, dynamic> _mapRow(Map<String, dynamic> raw, Set<String> validCols, Map<String, String>? aliases) {
    final mapped = <String, dynamic>{};
    for (final entry in raw.entries) {
      var col = aliases?[entry.key] ?? _camelToSnake(entry.key);
      if (validCols.contains(col)) {
        var val = entry.value;
        if (col == 'created_at' && val is int) {
          val = DateTime.fromMillisecondsSinceEpoch(val).toIso8601String();
        }
        mapped[col] = val;
      }
    }
    return mapped;
  }

  Map<String, dynamic> _encode(Map<String, dynamic> row) {
    return row.map((k, v) {
      if (v is Map || v is List) return MapEntry(k, jsonEncode(v));
      return MapEntry(k, v);
    });
  }

  String _camelToSnake(String name) {
    return name.replaceAllMapped(RegExp(r'([A-Z])'), (m) => '_${m[1]!.toLowerCase()}');
  }
}
