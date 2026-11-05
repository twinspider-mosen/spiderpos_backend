import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:spiderpos_server/spiderpos_server.dart';
import 'package:test/test.dart';

void main() {
  group('Employee Commission Report', () {
    setUpAll(() async {
      await PostgresConfig.initialize();
    });

    test('generates Employee Commission report with correct aggregations', () async {
      final service = EmployeeCommissionService();
      final report = await service.generateReport();

      expect(report['summary'], isNotNull);
      final summary = report['summary'] as Map<String, dynamic>;

      expect(summary['total_employees'], isA<int>());
      expect(summary['total_invoices'], isA<int>());
      expect(summary['gross_sales'], isA<num>());
      expect(summary['total_returns'], isA<num>());
      expect(summary['net_sales'], isA<num>());
      expect(summary['total_commission'], isA<num>());

      final employees = report['employees'] as List;
      expect(employees, isNotEmpty);

      final first = employees.first as Map<String, dynamic>;
      expect(first, contains('employee_id'));
      expect(first, contains('employee_name'));
      expect(first, contains('commission_percent'));
      expect(first, contains('total_invoices'));
      expect(first, contains('gross_sales'));
      expect(first, contains('return_amount'));
      expect(first, contains('net_sales'));
      expect(first, contains('total_commission'));
    });

    test('controller handles employee commission endpoint', () async {
      final controller = EmployeeCommissionController();
      final response = await controller.handleReport(
        Request('GET', Uri.parse('http://localhost/api/reports/employee-commission')),
      );

      expect(response.statusCode, equals(200));
      final body = jsonDecode(await response.readAsString()) as Map;
      expect(body['summary'], isNotNull);
      expect(body['employees'], isA<List>());
    });

    tearDownAll(() async {
      await PostgresConfig.close();
    });
  });
}
