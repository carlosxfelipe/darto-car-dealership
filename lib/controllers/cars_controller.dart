import 'package:darto/darto.dart';
import 'package:darto_car_dealership/cars_service.dart';

class CarsController {
  final CarsService carsService;

  CarsController(this.carsService);

  Response findAll(Context c) {
    return c.ok(carsService.findAll());
  }

  Response _notFound(Context c, String id) {
    return c.status(404).json({
      'message': 'Carro com id $id não encontrado.',
      'error': 'Not Found',
      'statusCode': 404
    });
  }

  Response findOneById(Context c) {
    final params = c.req.valid<Map<String, dynamic>>('param');
    final id = params['id'] as String;

    final car = carsService.findOneById(id);
    if (car != null) {
      return c.ok(car);
    }
    return _notFound(c, id);
  }

  Response create(Context c) {
    final body = c.req.valid<Map<String, dynamic>>('json');
    final car = carsService.create(body['brand'] as String, body['model'] as String);
    return c.status(201).json(car);
  }

  Response update(Context c) {
    final params = c.req.valid<Map<String, dynamic>>('param');
    final id = params['id'] as String;
    final body = c.req.valid<Map<String, dynamic>>('json');

    if (body.containsKey('id') && body['id'] != id) {
      return c.status(400).json({
        'message': 'O ID do carro não pode ser alterado no corpo da requisição.',
        'error': 'Bad Request',
        'statusCode': 400
      });
    }

    final carExists = carsService.findOneById(id);
    if (carExists == null) {
      return _notFound(c, id);
    }

    final car = carsService.update(id, body);
    return c.ok(car);
  }

  Response delete(Context c) {
    final params = c.req.valid<Map<String, dynamic>>('param');
    final id = params['id'] as String;

    final carExists = carsService.findOneById(id);
    if (carExists == null) {
      return _notFound(c, id);
    }

    carsService.delete(id);
    return c.ok({
      'message': 'Carro com id $id deletado com sucesso.'
    });
  }
}
