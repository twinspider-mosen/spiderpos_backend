import 'package:intl/intl.dart';
import 'pnl_report_repository.dart';

class PnlReportService {
  final PnlReportRepository _repo;

  PnlReportService([PnlReportRepository? repo])
      : _repo = repo ?? PnlReportRepository();

  Future<Map<String, dynamic>> generateReport({
    String? storeId,
    String? warehouseId,
    String? categoryId,
    String? productId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final products = await _repo.getProductSales(
      storeId: storeId,
      warehouseId: warehouseId,
      categoryId: categoryId,
      productId: productId,
      fromDate: fromDate,
      toDate: toDate,
    );

    final filterNames = await _repo.resolveFilterNames(
      storeId: storeId,
      warehouseId: warehouseId,
      categoryId: categoryId,
    );

    var grossSale = 0.0;
    var totalReturns = 0.0;
    var netSaleBeforeDiscount = 0.0;
    var totalCost = 0.0;
    var totalSoldQty = 0.0;
    var totalReturnQty = 0.0;
    var totalNetQty = 0.0;

    for (final p in products) {
      grossSale += (p['gross_sale'] as num?)?.toDouble() ?? 0.0;
      totalReturns += (p['return_amount'] as num?)?.toDouble() ?? 0.0;
      netSaleBeforeDiscount += (p['net_sale'] as num?)?.toDouble() ?? 0.0;
      totalCost += (p['total_cost'] as num?)?.toDouble() ?? 0.0;
      totalSoldQty += (p['sold_qty'] as num?)?.toDouble() ?? 0.0;
      totalReturnQty += (p['return_qty'] as num?)?.toDouble() ?? 0.0;
      totalNetQty += (p['net_qty'] as num?)?.toDouble() ?? 0.0;
    }

    final totalDiscount = await _repo.getTotalInvoiceDiscount(
      storeId: storeId,
      warehouseId: warehouseId,
      fromDate: fromDate,
      toDate: toDate,
    );

    final netSale = netSaleBeforeDiscount - totalDiscount;
    final netProfit = netSale - totalCost;
    final marginPct = netSale > 0 ? (netProfit / netSale) * 100 : 0.0;

    final dateFmt = DateFormat('dd MMM yyyy');
    final formattedFrom = fromDate != null ? dateFmt.format(fromDate) : null;
    final formattedTo = toDate != null ? dateFmt.format(toDate) : null;

    return {
      'filters': {
        'store_id': storeId,
        'store_name': filterNames['store_name'] ?? storeId,
        'warehouse_id': warehouseId,
        'warehouse_name': filterNames['warehouse_name'] ?? warehouseId,
        'category_id': categoryId,
        'category_name': filterNames['category_name'] ?? categoryId,
        'product_id': productId,
        'from_date': formattedFrom,
        'to_date': formattedTo,
      },
      'summary': {
        'gross_sale': _round(grossSale),
        'total_returns': _round(totalReturns),
        'total_discount': _round(totalDiscount),
        'net_sale': _round(netSale),
        'total_cost': _round(totalCost),
        'net_profit': _round(netProfit),
        'net_margin_percentage': _round(marginPct),
        'total_sold_qty': _round(totalSoldQty),
        'total_return_qty': _round(totalReturnQty),
        'total_net_qty': _round(totalNetQty),
        'total_products_count': products.length,
      },
      'products': products,
    };
  }

  double _round(double val) => double.parse(val.toStringAsFixed(2));
}
