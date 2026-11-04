import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/postgres_service.dart';

class TableController {
  final PostgresService _service;
  final headers = {'content-type': 'application/json'};

  TableController([PostgresService? service])
      : _service = service ?? PostgresService();

  Router get router {
    final r = Router();

    r.get('/', (Request req) {
      return Response.ok(
        jsonEncode({'tables': PostgresService.validTables.toList()}),
        headers: headers,
      );
    });

    r.get('/<table_name>', (Request req, String tableName) async {
      final table = tableName.replaceAll('-', '_');
      try {
        final q = req.url.queryParameters;
        final limit = int.tryParse(q['limit'] ?? '');
        final offset = int.tryParse(q['offset'] ?? '');
        final storeId = q['store_id'];
        final orderBy = q['order_by'];
        final descending = q['desc'] == 'true';

        final rows = await _service.listRows(
          table,
          limit: limit,
          offset: offset,
          storeId: storeId,
          orderBy: orderBy,
          descending: descending,
        );

        return Response.ok(
          jsonEncode({'table': table, 'count': rows.length, 'data': rows}),
          headers: headers,
        );
      } catch (e) {
        return _handleError(e);
      }
    });

    r.get('/<table_name>/<id>', (Request req, String tableName, String id) async {
      final table = tableName.replaceAll('-', '_');
      try {
        final row = await _service.getRow(table, id);
        if (row == null) {
          return Response.notFound(
            jsonEncode({'error': 'Record not found in $table'}),
            headers: headers,
          );
        }
        return Response.ok(
          jsonEncode({'table': table, 'id': id, 'data': row}),
          headers: headers,
        );
      } catch (e) {
        return _handleError(e);
      }
    });

    r.post('/<table_name>', (Request req, String tableName) async {
      final table = tableName.replaceAll('-', '_');
      try {
        final body = await req.readAsString();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final inserted = await _service.insertRow(table, data);
        return Response(201, body: jsonEncode(inserted), headers: headers);
      } catch (e) {
        return _handleError(e);
      }
    });

    r.put('/<table_name>/<id>', (Request req, String tableName, String id) async {
      final table = tableName.replaceAll('-', '_');
      try {
        final body = await req.readAsString();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final updated = await _service.updateRow(table, id, data);
        if (updated == null) {
          return Response.notFound(
            jsonEncode({'error': 'Record not found in $table'}),
            headers: headers,
          );
        }
        return Response.ok(jsonEncode(updated), headers: headers);
      } catch (e) {
        return _handleError(e);
      }
    });

    r.delete('/<table_name>/<id>', (Request req, String tableName, String id) async {
      final table = tableName.replaceAll('-', '_');
      try {
        final success = await _service.deleteRow(table, id);
        if (!success) {
          return Response.notFound(
            jsonEncode({'error': 'Record not found in $table'}),
            headers: headers,
          );
        }
        return Response.ok(
          jsonEncode({'message': 'Deleted record $id from $table'}),
          headers: headers,
        );
      } catch (e) {
        return _handleError(e);
      }
    });

    return r;
  }

  Response _handleError(Object e) {
    if (e is ArgumentError) {
      return Response.badRequest(
        body: jsonEncode({'error': e.message}),
        headers: headers,
      );
    }
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: headers,
    );
  }
}
