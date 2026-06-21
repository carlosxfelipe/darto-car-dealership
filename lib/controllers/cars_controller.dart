import 'package:darto/darto.dart';
import 'package:darto_car_dealership/cars_service.dart';

class CarsController {
  final CarsService carsService;

  CarsController(this.carsService);

  Response findAll(Context c) {
    return c.ok(carsService.findAll());
  }

  Response findOneById(Context c) {
    final params = c.req.valid<Map<String, dynamic>>('param');
    final id = params['id'] as int;

    final car = carsService.findOneById(id);
    if (car != null) {
      return c.ok(car);
    }
    return c.status(404).json({'error': 'Not found'});
  }

  Response create(Context c) {
    final body = c.req.valid<Map<String, dynamic>>('json');
    final car =
        carsService.create(body['brand'] as String, body['model'] as String);
    return c.created({
      'status': 'Carro ${car["brand"]} adicionado com sucesso!',
      'car': car
    });
  }
}
