import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'stock_report_service.dart';

class StockReportController {
  final StockReportService _service;
  final headers = {'content-type': 'application/json'};

  StockReportController([StockReportService? service])
      : _service = service ?? StockReportService();

  Router get router {
    final r = Router();
    r.get('/', handleReport);
    return r;
  }

  Future<Response> handleReport(Request req) async {
    try {
      final q = req.url.queryParameters;

      final storeId = q['store_id'];
      final warehouseId = q['warehouse_id'];
      final categoryId = q['category_id'];
      final productId = q['product_id'];

      final toDateStr = q['to_date'] ?? q['as_of_date'];
      DateTime? toDate;

      if (toDateStr != null && toDateStr.isNotEmpty) {
        toDate = DateTime.tryParse(toDateStr);
      }

      final report = await _service.generateReport(
        storeId: storeId,
        warehouseId: warehouseId,
        categoryId: categoryId,
        productId: productId,
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
