import 'package:spiderpos_server/spiderpos_server.dart';
import 'package:test/test.dart';

void main() {
  group('FirebaseService & FirebaseConfig', () {
    setUpAll(() async {
      await FirebaseConfig.initialize();
    });

    test('FirebaseConfig initializes Firestore instance', () {
      expect(FirebaseConfig.db, isNotNull);
      expect(FirebaseConfig.firestore, isNotNull);
    });

    test('FirebaseService lists collections', () async {
      final service = FirebaseService();
      final collections = await service.listCollections();
      expect(collections, isNotEmpty);
      expect(collections, contains('Products'));
      expect(collections, contains('Users'));
    });

    test('FirebaseService fetches collection documents with sanitized fields',
        () async {
      final service = FirebaseService();
      final products = await service.getCollection('Products', limit: 2);
      expect(products, isNotEmpty);
      expect(products.first, contains('id'));
      expect(products.first['id'], isNotEmpty);
    });

    test('FirebaseService fetches single document by id', () async {
      final service = FirebaseService();
      final products = await service.getCollection('Products', limit: 1);
      final firstId = products.first['id'] as String;

      final doc = await service.getDocument('Products', firstId);
      expect(doc, isNotNull);
      expect(doc!['id'], equals(firstId));
    });
  });
}
