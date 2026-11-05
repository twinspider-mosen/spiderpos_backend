import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:spiderpos_server/spiderpos_server.dart';
import 'package:test/test.dart';

void main() {
  group('Stock Report', () {
    setUpAll(() async {
      await PostgresConfig.initialize();
    });

    test('generates Stock report with correct aggregations and formula', () async {
      final service = StockReportService();
      final report = await service.generateReport();

      expect(report['summary'], isNotNull);
      final summary = report['summary'] as Map<String, dynamic>;

      expect(summary['total_products'], isA<int>());
      expect(summary['total_purchased_qty'], isA<num>());
      expect(summary['total_sale_returned_qty'], isA<num>());
      expect(summary['total_sold_qty'], isA<num>());
      expect(summary['total_purchase_returned_qty'], isA<num>());
      expect(summary['total_active_stock'], isA<num>());
      expect(summary['total_stock_value'], isA<num>());

      final products = report['products'] as List;
      expect(products, isNotEmpty);

      final first = products.first as Map<String, dynamic>;
      expect(first, contains('product_id'));
      expect(first, contains('product_name'));
      expect(first, contains('category_name'));
      expect(first, contains('purchase_price'));
      expect(first, contains('purchased_qty'));
      expect(first, contains('sale_returned_qty'));
      expect(first, contains('sold_qty'));
      expect(first, contains('purchase_returned_qty'));
      expect(first, contains('active_stock'));
      expect(first, contains('stock_value'));

      // Verify formula: active_stock = purchased + sale_return - sold - purchase_return
      final pQty = (first['purchased_qty'] as num).toDouble();
      final srQty = (first['sale_returned_qty'] as num).toDouble();
      final sQty = (first['sold_qty'] as num).toDouble();
      final prQty = (first['purchase_returned_qty'] as num).toDouble();
      final expectedStock = double.parse((pQty + srQty - sQty - prQty).toStringAsFixed(3));
      expect(first['active_stock'], equals(expectedStock));
    });

    test('controller handles /api/reports/stock endpoint', () async {
      final controller = StockReportController();
      final response = await controller.handleReport(
        Request('GET', Uri.parse('http://localhost/api/reports/stock')),
      );

      expect(response.statusCode, equals(200));
      final body = jsonDecode(await response.readAsString()) as Map;
      expect(body['summary'], isNotNull);
      expect(body['products'], isA<List>());
    });

    tearDownAll(() async {
      await PostgresConfig.close();
    });
  });
}
