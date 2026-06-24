import 'dart:convert';

import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:darto/darto.dart';
import 'package:darto_openapi/darto_openapi.dart';
import 'package:darto_car_dealership/cars_service.dart';
import 'package:darto_car_dealership/port_killer.dart';
import 'package:darto_car_dealership/routes/cars_routes.dart';

void main() {
  group('Cars API Tests', () {
    late Darto app;
    final port = 3001;
    final baseUrl = 'http://localhost:$port';

    setUpAll(() async {
      await freePort(port);
      app = Darto();
      final api = OpenApi(app, info: Info(title: 'Test API', version: '1.0.0'));
      app.use(api.docs());
      
      final carsService = CarsService();
      setupCarsRoutes(api, carsService);
      
      app.listen(port);
    });

    tearDownAll(() async {
      // Darto might not have a public close method, we'll see if it compiles
    });

    test('POST /cars should reject extra properties with 400 Bad Request', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/cars'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'brand': 'Ford',
          'model': 'Mustang',
          'hacker': true // Extra property that should be rejected
        }),
      );

      expect(response.statusCode, 400);
      // The validator should return an error indicating an invalid schema
      expect(response.body.contains('hacker'), isTrue); 
    });

    test('POST /cars should accept valid payload and return 201', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/cars'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'brand': 'Ford',
          'model': 'Mustang'
        }),
      );

      expect(response.statusCode, 201);
      final jsonResponse = jsonDecode(response.body);
      expect(jsonResponse['brand'], 'Ford');
      expect(jsonResponse['model'], 'Mustang');
      expect(jsonResponse['id'], isNotNull);
    });
  });
}
