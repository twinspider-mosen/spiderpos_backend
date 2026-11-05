import 'package:intl/intl.dart';
import 'stock_report_repository.dart';

class StockReportService {
  final StockReportRepository _repo;

  StockReportService([StockReportRepository? repo])
      : _repo = repo ?? StockReportRepository();

  Future<Map<String, dynamic>> generateReport({
    String? storeId,
    String? warehouseId,
    String? categoryId,
    String? productId,
    DateTime? toDate,
  }) async {
    final products = await _repo.getStock(
      storeId: storeId,
      warehouseId: warehouseId,
      categoryId: categoryId,
      productId: productId,
      toDate: toDate,
    );

    final filterNames = await _repo.resolveFilterNames(
      storeId: storeId,
      warehouseId: warehouseId,
      categoryId: categoryId,
      productId: productId,
    );

    var totalPurchased = 0.0;
    var totalSaleReturned = 0.0;
    var totalSold = 0.0;
    var totalPurchaseReturned = 0.0;
    var totalActiveStock = 0.0;
    var totalStockValue = 0.0;

    for (final p in products) {
      totalPurchased += (p['purchased_qty'] as num?)?.toDouble() ?? 0.0;
      totalSaleReturned += (p['sale_returned_qty'] as num?)?.toDouble() ?? 0.0;
      totalSold += (p['sold_qty'] as num?)?.toDouble() ?? 0.0;
      totalPurchaseReturned += (p['purchase_returned_qty'] as num?)?.toDouble() ?? 0.0;
      totalActiveStock += (p['active_stock'] as num?)?.toDouble() ?? 0.0;
      totalStockValue += (p['stock_value'] as num?)?.toDouble() ?? 0.0;
    }

    final dateFmt = DateFormat('dd MMM yyyy');
    final formattedAsOf = toDate != null ? dateFmt.format(toDate) : dateFmt.format(DateTime.now());

    return {
      'filters': {
        'store_id': storeId,
        'store_name': filterNames['store_name'] ?? storeId,
        'warehouse_id': warehouseId,
        'warehouse_name': filterNames['warehouse_name'] ?? warehouseId,
        'category_id': categoryId,
        'category_name': filterNames['category_name'] ?? categoryId,
        'product_id': productId,
        'product_name': filterNames['product_name'] ?? productId,
        'as_of_date': formattedAsOf,
      },
      'summary': {
        'total_products': products.length,
        'total_purchased_qty': _round(totalPurchased),
        'total_sale_returned_qty': _round(totalSaleReturned),
        'total_sold_qty': _round(totalSold),
        'total_purchase_returned_qty': _round(totalPurchaseReturned),
        'total_active_stock': _round(totalActiveStock),
        'total_stock_value': _round(totalStockValue),
      },
      'products': products,
    };
  }

  double _round(double val) => double.parse(val.toStringAsFixed(2));
}
