import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'employee_commission_service.dart';

class EmployeeCommissionController {
  final EmployeeCommissionService _service;
  final headers = {'content-type': 'application/json'};

  EmployeeCommissionController([EmployeeCommissionService? service])
      : _service = service ?? EmployeeCommissionService();

  Router get router {
    final r = Router();
    r.get('/', handleReport);
    return r;
  }

  Future<Response> handleReport(Request req) async {
    try {
      final q = req.url.queryParameters;

      final storeId = q['store_id'];
      final employeeId = q['employee_id'];
      final warehouseId = q['warehouse_id'];
      final includeInvoices = q['detailed'] == 'true' || q['include_invoices'] == 'true';

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
        employeeId: employeeId,
        warehouseId: warehouseId,
        fromDate: fromDate,
        toDate: toDate,
        includeInvoices: includeInvoices,
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
