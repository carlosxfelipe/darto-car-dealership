import 'package:darto/darto.dart';
import 'package:darto_zard_openapi/darto_zard_openapi.dart';
import 'package:darto_car_dealership/cars_service.dart';
import 'package:darto_car_dealership/port_killer.dart';
import 'package:darto_car_dealership/routes/cars_routes.dart';

void main() async {
  await freePort(3000);

  final app = Darto();

  final api = OpenAPIDarto(app);

  api.doc(
    '/openapi.json',
    info: Info(title: 'Oficial Car Dealership API', version: '1.0.0'),
  );
  app.get('/docs', [], scalarUI(url: '/openapi.json'));

  app.get('/', [], (c) => c.redirect('/docs'));

  final carsService = CarsService();

  setupCarsRoutes(api, carsService);

  await app.listen(3000, () => print('Listening on http://localhost:3000'));
}
