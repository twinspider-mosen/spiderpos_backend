import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:spiderpos_server/spiderpos_server.dart';

Future<void> main() async {
  await FirebaseConfig.initialize();

  final firebaseService = FirebaseService();
  final tableController = TableController();
  final router = Router();
  final headers = {'content-type': 'application/json'};
  final address = InternetAddress.anyIPv4;
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;

  router.get('/', (Request r) {
    return Response.ok(
      jsonEncode({'message': 'SpiderPOS Server API is running'}),
      headers: headers,
    );
  });

  router.get('/api/collections', (Request r) async {
    try {
      final collections = await firebaseService.listCollections();
      return Response.ok(
        jsonEncode({'collections': collections}),
        headers: headers,
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: headers,
      );
    }
  });

  router.get('/api/collections/<name>', (Request r, String name) async {
    try {
      final limit = int.tryParse(r.url.queryParameters['limit'] ?? '');
      final data = await firebaseService.getCollection(name, limit: limit);
      return Response.ok(
        jsonEncode({'collection': name, 'count': data.length, 'data': data}),
        headers: headers,
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: headers,
      );
    }
  });

  router.get('/api/collections/<name>/<id>',
      (Request r, String name, String id) async {
    try {
      final doc = await firebaseService.getDocument(name, id);
      if (doc == null) {
        return Response.notFound(
          jsonEncode({'error': 'Document not found'}),
          headers: headers,
        );
      }
      return Response.ok(
        jsonEncode({'collection': name, 'id': id, 'data': doc}),
        headers: headers,
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: headers,
      );
    }
  });

  router.mount('/api/tables/', tableController.router.call);
  router.mount('/api/', tableController.router.call);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server = await io.serve(handler, address, port);
  print('Server running on http://${server.address.host}:${server.port}');
}
