import 'package:darto_openapi/darto_openapi.dart';
import 'package:darto_car_dealership/controllers/cars_controller.dart';
import 'package:darto_car_dealership/models.dart';
import 'package:darto_car_dealership/responses.dart';
import 'package:darto_car_dealership/cars_service.dart';

void setupCarsRoutes(OpenApi api, CarsService carsService) {
  final controller = CarsController(carsService);

  api.get(
    '/cars',
    summary: 'Lista todos os carros',
    tags: ['Carros'],
    description: 'Retorna a lista de carros em estoque.',
    responses: listCarsResponses,
    handler: controller.findAll,
  );

  api.get(
    '/cars/:id',
    summary: 'Pega um carro pelo ID',
    tags: ['Carros'],
    description: 'Busca um carro específico pelo seu ID.',
    request: Req(params: {'id': Schema.integer()}),
    responses: getCarByIdResponses,
    handler: controller.findOneById,
  );

  api.post(
    '/cars',
    summary: 'Adiciona um carro',
    tags: ['Carros'],
    description: 'Adiciona um novo carro ao estoque.',
    request: Req(json: carCreateSchema),
    responses: createCarResponses,
    handler: controller.create,
  );
}
