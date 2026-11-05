import 'package:intl/intl.dart';
import 'employee_commission_repository.dart';

class EmployeeCommissionService {
  final EmployeeCommissionRepository _repo;

  EmployeeCommissionService([EmployeeCommissionRepository? repo])
      : _repo = repo ?? EmployeeCommissionRepository();

  Future<Map<String, dynamic>> generateReport({
    String? storeId,
    String? employeeId,
    String? warehouseId,
    DateTime? fromDate,
    DateTime? toDate,
    bool includeInvoices = false,
  }) async {
    final employees = await _repo.getCommissionSummary(
      storeId: storeId,
      employeeId: employeeId,
      warehouseId: warehouseId,
      fromDate: fromDate,
      toDate: toDate,
    );

    final filterNames = await _repo.resolveFilterNames(
      storeId: storeId,
      warehouseId: warehouseId,
      employeeId: employeeId,
    );

    var totalInvoices = 0;
    var totalGross = 0.0;
    var totalReturns = 0.0;
    var totalNet = 0.0;
    var totalCommission = 0.0;

    for (final e in employees) {
      totalInvoices += (e['total_invoices'] as num?)?.toInt() ?? 0;
      totalGross += (e['gross_sales'] as num?)?.toDouble() ?? 0.0;
      totalReturns += (e['return_amount'] as num?)?.toDouble() ?? 0.0;
      totalNet += (e['net_sales'] as num?)?.toDouble() ?? 0.0;
      totalCommission += (e['total_commission'] as num?)?.toDouble() ?? 0.0;
    }

    final dateFmt = DateFormat('dd MMM yyyy');
    final formattedFrom = fromDate != null ? dateFmt.format(fromDate) : null;
    final formattedTo = toDate != null ? dateFmt.format(toDate) : null;

    List<Map<String, dynamic>>? invoiceList;
    if (includeInvoices && employeeId != null && employeeId.isNotEmpty) {
      invoiceList = await _repo.getEmployeeInvoices(
        employeeId: employeeId,
        storeId: storeId,
        warehouseId: warehouseId,
        fromDate: fromDate,
        toDate: toDate,
      );
    }

    return {
      'filters': {
        'store_id': storeId,
        'store_name': filterNames['store_name'] ?? storeId,
        'warehouse_id': warehouseId,
        'warehouse_name': filterNames['warehouse_name'] ?? warehouseId,
        'employee_id': employeeId,
        'employee_name': filterNames['employee_name'] ?? employeeId,
        'from_date': formattedFrom,
        'to_date': formattedTo,
      },
      'summary': {
        'total_employees': employees.length,
        'total_invoices': totalInvoices,
        'gross_sales': _round(totalGross),
        'total_returns': _round(totalReturns),
        'net_sales': _round(totalNet),
        'total_commission': _round(totalCommission),
      },
      'employees': employees,
      if (invoiceList != null) 'invoices': invoiceList,
    };
  }

  double _round(double val) => double.parse(val.toStringAsFixed(2));
}
