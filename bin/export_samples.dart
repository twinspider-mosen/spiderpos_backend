import 'dart:convert';
import 'dart:io';

import 'package:spiderpos_server/spiderpos_server.dart';

Future<void> main() async {
  await FirebaseConfig.initialize();

  final service = FirebaseService();
  final collections = await service.listCollections();
  final outputDir = Directory('data/samples');

  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  const encoder = JsonEncoder.withIndent('  ');

  for (final col in collections) {
    try {
      final records = await service.getCollection(col, limit: 10);
      final file = File('${outputDir.path}/${col.toLowerCase()}.json');
      await file.writeAsString(encoder.convert(records));
      print('Exported ${records.length} records -> ${file.path}');
    } catch (e) {
      stderr.writeln('Failed to export $col: $e');
    }
  }

  print('Done. Total collections exported: ${collections.length}');
  exit(0);
}
