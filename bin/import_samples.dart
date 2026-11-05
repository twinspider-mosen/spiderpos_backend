import 'dart:io';

import 'package:spiderpos_server/spiderpos_server.dart';

Future<void> main() async {
  print('Connecting to PostgreSQL...');
  await PostgresConfig.initialize();

  final importer = ImportService();

  final jobs = <(String, String, Map<String, String>?)>[
    ('storesettings.json', 'stores', {'createdAt': 'created_at'}),
    ('users.json', 'users', {'createdAt': 'created_at'}),
    ('categories.json', 'categories', null),
    ('warehouses.json', 'warehouses', null),
    ('customers.json', 'customers', null),
    ('employees.json', 'employees', null),
    ('products.json', 'products', {'barCode': 'bar_code'}),
    ('stocktransfer.json', 'stock_transfers', {
      'fromWhId': 'from_warehouse_id',
      'toWhId': 'to_warehouse_id',
      'fromWarehosueName': 'from_warehouse_name',
      'toWarehosueName': 'to_warehouse_name',
      'productId': 'product_id',
      'productName': 'product_name',
      'storeId': 'store_id',
      'date': 'transfer_date',
      'by': 'transferred_by',
    }),
    ('productstock.json', 'product_stocks', null),
    ('invoices.json', 'invoices', null),
    ('payments.json', 'payments', null),
    ('invoicereport.json', 'invoice_reports', null),
    ('salaries.json', 'salaries', null),
    ('app.json', 'app_configs', null),
  ];

  print('Importing data into PostgreSQL tables...');
  for (final (file, table, aliases) in jobs) {
    try {
      final count = await importer.importFile(file, table, aliases: aliases);
      print('Inserted $count rows into $table (from $file)');
    } catch (e) {
      stderr.writeln('Error importing $file into $table: $e');
    }
  }

  print('Data injection complete.');
  await PostgresConfig.close();
  exit(0);
}
