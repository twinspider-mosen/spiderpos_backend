import 'dart:io';

import 'package:spiderpos_server/spiderpos_server.dart';

Future<void> main() async {
  print('Connecting to PostgreSQL...');
  await PostgresConfig.initialize();

  print('Running schema migrations (database/*.sql)...');
  await PostgresConfig.runMigrations();

  print('Migrations completed successfully.');
  await PostgresConfig.close();
  exit(0);
}
