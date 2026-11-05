import 'dart:convert';
import 'dart:io';
import 'package:spiderpos_server/spiderpos_server.dart';
import 'package:spiderpos_server/modules/reports/pnl_pdf_service.dart';

Future<void> main(List<String> args) async {
  final params = <String, String>{};
  String? jsonFile;
  String outputPath = 'output/reports/product_wise_pnl_report.pdf';

  for (final arg in args) {
    if (arg.startsWith('--output=') || arg.startsWith('-o=')) {
      outputPath = arg.split('=')[1];
    } else if (arg.startsWith('--json=')) {
      jsonFile = arg.split('=')[1];
    } else if (arg.startsWith('--') && arg.contains('=')) {
      final parts = arg.substring(2).split('=');
      params[parts[0]] = parts.sublist(1).join('=');
    } else if (arg.endsWith('.json')) {
      jsonFile = arg;
    } else if (arg.endsWith('.pdf')) {
      outputPath = arg;
    }
  }

  Map<String, dynamic> report;
  if (jsonFile != null && File(jsonFile).existsSync()) {
    print('Reading report from $jsonFile...');
    report = jsonDecode(await File(jsonFile).readAsString()) as Map<String, dynamic>;
  } else {
    print('Generating report directly from PostgreSQL...');
    await PostgresConfig.initialize();
    final service = PnlReportService();
    report = await service.generateReport(
      storeId: params['store_id'],
      warehouseId: params['warehouse_id'],
      categoryId: params['category_id'],
      productId: params['product_id'],
      fromDate: params['from_date'] != null ? DateTime.tryParse(params['from_date']!) : null,
      toDate: params['to_date'] != null ? DateTime.tryParse(params['to_date']!) : null,
    );
    await PostgresConfig.close();
  }

  print('Generating PDF...');
  final pdfFile = await PnlPdfService().generatePdf(
    report: report,
    outputPath: outputPath,
  );
  print('PDF ready: ${pdfFile.path} (${pdfFile.lengthSync()} bytes)');
}
