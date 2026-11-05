import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:spiderpos_server/spiderpos_server.dart';
import 'package:test/test.dart';

void main() {
  group('Product PnL Report', () {
    setUpAll(() async {
      await PostgresConfig.initialize();
    });

    test('generates Product PnL report with correct summary calculations', () async {
      final service = PnlReportService();
      final report = await service.generateReport();

      expect(report['summary'], isNotNull);
      final summary = report['summary'] as Map<String, dynamic>;

      expect(summary['gross_sale'], isA<num>());
      expect(summary['total_discount'], isA<num>());
      expect(summary['total_returns'], isA<num>());
      expect(summary['net_sale'], isA<num>());
      expect(summary['total_cost'], isA<num>());
      expect(summary['net_profit'], isA<num>());
      expect(summary['net_margin_percentage'], isA<num>());

      // Verify math: net_sale = gross_sale - total_discount - total_returns
      final gross = (summary['gross_sale'] as num).toDouble();
      final discount = (summary['total_discount'] as num).toDouble();
      final returns = (summary['total_returns'] as num).toDouble();
      final expectedNetSale = double.parse((gross - discount - returns).toStringAsFixed(2));
      expect(summary['net_sale'], equals(expectedNetSale));

      // Verify products list
      final products = report['products'] as List;
      expect(products, isNotEmpty);
      final first = products.first as Map<String, dynamic>;
      expect(first, contains('product_id'));
      expect(first, contains('product_name'));
      expect(first, contains('quantity'));
      expect(first, contains('sale_price'));
      expect(first, contains('purchase_price'));
      expect(first, contains('gross_sale'));
      expect(first, contains('total_cost'));
      expect(first, contains('gross_profit'));
    });

    test('controller responds with 200 OK for /product-pnl endpoint', () async {
      final controller = PnlReportController();
      final response = await controller.router(
        Request('GET', Uri.parse('http://localhost/product-pnl?limit=5')),
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
