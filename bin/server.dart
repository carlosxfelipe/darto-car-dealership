import 'package:darto/darto.dart';
import 'package:darto_openapi/darto_openapi.dart';
import 'package:darto_car_dealership/cars_service.dart';
import 'package:darto_car_dealership/port_killer.dart';
import 'package:darto_car_dealership/routes/cars_routes.dart';

void main() async {
  await freePort(3000);

  final app = Darto();

  final api = OpenApi(app,
      info: Info(title: 'Oficial Car Dealership API', version: '1.0.0'));

  app.use(api.docs());

  final carsService = CarsService();

  setupCarsRoutes(api, carsService);

  await app.listen(3000, () => print('Listening on http://localhost:3000'));
}
