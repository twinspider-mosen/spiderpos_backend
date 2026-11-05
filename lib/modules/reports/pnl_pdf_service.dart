import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PnlPdfService {
  final _currency = NumberFormat('#,##0.00');

  Future<File> generatePdf({
    required Map<String, dynamic> report,
    String outputPath = 'output/reports/product_wise_pnl_report.pdf',
  }) async {
    final pdf = pw.Document();
    final summary = (report['summary'] as Map?)?.cast<String, dynamic>() ?? {};
    final filters = (report['filters'] as Map?)?.cast<String, dynamic>() ?? {};
    final products = (report['products'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (ctx) => _buildHeader(ctx, filters),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          _buildSummary(summary),
          pw.SizedBox(height: 12),
          _buildProductTable(products),
        ],
      ),
    );

    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildHeader(pw.Context ctx, Map<String, dynamic> filters) {
    final fromDate = filters['from_date'] ?? 'All';
    final toDate = filters['to_date'] ?? 'All';
    final store = filters['store_name'] ?? filters['store_id'] ?? 'All';
    final warehouse = filters['warehouse_name'] ?? filters['warehouse_id'] ?? 'All';
    final cat = filters['category_name'] ?? filters['category_id'];
    final catText = cat != null ? ' | Category: $cat' : '';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Product Wise Profit & Loss Report',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
            ),
            pw.Text(
              'Generated: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'Date Range: $fromDate to $toDate | Store: $store | Warehouse: $warehouse$catText',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
      ],
    );
  }

  pw.Widget _buildSummary(Map<String, dynamic> s) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _metric('Gross Sale', _currency.format(s['gross_sale'] ?? 0)),
          _metric('Returns/Exch', _currency.format(s['total_returns'] ?? 0), color: PdfColors.red800),
          _metric('Discount', _currency.format(s['total_discount'] ?? 0)),
          _metric('Net Sale', _currency.format(s['net_sale'] ?? 0), color: PdfColors.blue800),
          _metric('Total Cost', _currency.format(s['total_cost'] ?? 0)),
          _metric('Net Profit', _currency.format(s['net_profit'] ?? 0), color: PdfColors.green800),
          _metric('Margin', '${s['net_margin_percentage'] ?? 0}%'),
          _metric('Net Qty', '${s['total_net_qty'] ?? 0}'),
        ],
      ),
    );
  }

  pw.Widget _metric(String label, String val, {PdfColor color = PdfColors.black}) => pw.Column(children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(val, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: color)),
      ]);

  pw.Widget _buildProductTable(List<Map<String, dynamic>> products) {
    const headers = [
      '#', 'Product', 'Category', 'Cost', 'Price', 'Sold', 'Gross Sale',
      'Ret Qty', 'Ret Amt', 'Net Qty', 'Net Sale', 'Cost', 'Profit'
    ];

    final data = <List<String>>[];
    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      final soldQty = p['sold_qty'] ?? p['quantity'] ?? 0;
      final returnQty = p['return_qty'] ?? 0;
      final returnAmt = p['return_amount'] ?? 0;
      final netQty = p['net_qty'] ?? p['quantity'] ?? 0;
      final netSale = p['net_sale'] ?? p['gross_sale'] ?? 0;

      data.add([
        '${i + 1}',
        p['product_name']?.toString() ?? '',
        p['category_name']?.toString() ?? '',
        _currency.format(p['purchase_price'] ?? 0),
        _currency.format(p['sale_price'] ?? 0),
        '$soldQty',
        _currency.format(p['gross_sale'] ?? 0),
        '$returnQty',
        _currency.format(returnAmt),
        '$netQty',
        _currency.format(netSale),
        _currency.format(p['total_cost'] ?? 0),
        _currency.format(p['gross_profit'] ?? 0),
      ]);
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      cellStyle: const pw.TextStyle(fontSize: 7),
      cellAlignment: pw.Alignment.centerRight,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
      },
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    );
  }

  pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('SpiderPOS Server Financial Reporting', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
        pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
      ],
    );
  }
}
