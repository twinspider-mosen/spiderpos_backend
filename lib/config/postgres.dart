import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

class PostgresConfig {
  static Pool<dynamic>? _pool;

  static Pool<dynamic> get pool {
    if (_pool == null) {
      throw StateError(
        'PostgreSQL not initialized. Call PostgresConfig.initialize() first.',
      );
    }
    return _pool!;
  }

  static Future<Pool<dynamic>> initialize() async {
    if (_pool != null) return _pool!;

    if (File('.env').existsSync()) {
      load('.env');
    }

    final host = env['DB_HOST'] ?? Platform.environment['DB_HOST'] ?? 'localhost';
    final portStr = env['DB_PORT'] ?? Platform.environment['DB_PORT'] ?? '5432';
    final port = int.tryParse(portStr) ?? 5432;
    final database = env['DB_NAME'] ?? Platform.environment['DB_NAME'] ?? 'spiderpos';
    final username = env['DB_USER'] ?? Platform.environment['DB_USER'] ?? 'postgres';
    final password = env['DB_PASSWORD'] ?? Platform.environment['DB_PASSWORD'];

    final sslEnabled = (env['DB_SSL'] ?? Platform.environment['DB_SSL']) == 'true';

    final endpoint = Endpoint(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
    );

    _pool = Pool.withEndpoints(
      [endpoint],
      settings: PoolSettings(
        maxConnectionCount: 10,
        sslMode: sslEnabled ? SslMode.require : SslMode.disable,
      ),
    );

    return _pool!;
  }

  static Future<void> runMigrations() async {
    final migrationDir = Directory('database');
    if (!migrationDir.existsSync()) return;

    final files = migrationDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sql'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final sql = await file.readAsString();
      final statements = sql
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);

      for (final statement in statements) {
        await pool.execute(statement);
      }
    }
  }

  static Future<void> close() async {
    await _pool?.close();
    _pool = null;
  }
}
