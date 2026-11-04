import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:spiderpos_server/spiderpos_server.dart';
import 'package:test/test.dart';

void main() {
  group('TableController API routing', () {
    test('lists all valid PostgreSQL tables', () async {
      final controller = TableController();
      final response = await controller.router(
        Request('GET', Uri.parse('http://localhost/')),
      );

      expect(response.statusCode, equals(200));
      final body = jsonDecode(await response.readAsString()) as Map;
      expect(body['tables'], isNotEmpty);
      expect(body['tables'], contains('invoices'));
      expect(body['tables'], contains('products'));
      expect(body['tables'], contains('stores'));
    });

    test('rejects invalid table names with 400 Bad Request', () async {
      final controller = TableController();
      final response = await controller.router(
        Request('GET', Uri.parse('http://localhost/invalid_table_xyz')),
      );

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.readAsString()) as Map;
      expect(body['error'], contains('Invalid table name'));
    });
  });
}
