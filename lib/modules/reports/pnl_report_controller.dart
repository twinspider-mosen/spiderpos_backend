import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'pnl_report_service.dart';

class PnlReportController {
  final PnlReportService _service;
  final headers = {'content-type': 'application/json'};

  PnlReportController([PnlReportService? service])
      : _service = service ?? PnlReportService();

  Router get router {
    final r = Router();

    r.get('/', handleIndex);
    r.get('/product-pnl', handleProductPnL);

    return r;
  }

  Response handleIndex(Request req) {
    return Response.ok(
      jsonEncode({
        'message': 'Reports API',
        'available_reports': [
          '/api/reports/product-pnl',
          '/api/reports/employee-commission',
          '/api/reports/stock',
        ],
      }),
      headers: headers,
    );
  }

  Future<Response> handleProductPnL(Request req) async {
    try {
      final q = req.url.queryParameters;

      final storeId = q['store_id'];
      final warehouseId = q['warehouse_id'];
      final categoryId = q['category_id'];
      final productId = q['product_id'];

      final fromDateStr = q['from_date'];
      final toDateStr = q['to_date'];

      DateTime? fromDate;
      DateTime? toDate;

      if (fromDateStr != null && fromDateStr.isNotEmpty) {
        fromDate = DateTime.tryParse(fromDateStr);
      }
      if (toDateStr != null && toDateStr.isNotEmpty) {
        toDate = DateTime.tryParse(toDateStr);
      }

      final report = await _service.generateReport(
        storeId: storeId,
        warehouseId: warehouseId,
        categoryId: categoryId,
        productId: productId,
        fromDate: fromDate,
        toDate: toDate,
      );

      return Response.ok(jsonEncode(report), headers: headers);
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: headers,
      );
    }
  }
}
