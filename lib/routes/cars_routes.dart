import 'package:darto_zard_openapi/darto_zard_openapi.dart';
import 'package:darto_car_dealership/controllers/cars_controller.dart';
import 'package:darto_car_dealership/models.dart';
import 'package:darto_car_dealership/responses.dart';
import 'package:darto_car_dealership/cars_service.dart';

void setupCarsRoutes(OpenAPIDarto api, CarsService carsService) {
  final controller = CarsController(carsService);

  final listCars = createRoute(
    method: 'get',
    path: '/cars',
    summary: 'Lista todos os carros',
    tags: ['Carros'],
    description: 'Retorna a lista de carros em estoque.',
    responses: listCarsResponses,
  );
  api.openapi(listCars, [], controller.findAll);

  final getCarById = createRoute(
    method: 'get',
    path: '/cars/:id',
    summary: 'Pega um carro pelo ID',
    tags: ['Carros'],
    description: 'Busca um carro específico pelo seu ID.',
    request: Req(params: z.map({'id': z.string().uuid()}).openapiSchema()),
    responses: getCarByIdResponses,
  );
  api.openapi(getCarById, [], controller.findOneById);

  final createCar = createRoute(
    method: 'post',
    path: '/cars',
    summary: 'Adiciona um carro',
    tags: ['Carros'],
    description: 'Adiciona um novo carro ao estoque.',
    request: Req(json: carCreateSchema),
    responses: createCarResponses,
  );
  api.openapi(createCar, [], controller.create);

  final updateCar = createRoute(
    method: 'patch',
    path: '/cars/:id',
    summary: 'Atualiza um carro pelo ID',
    tags: ['Carros'],
    description: 'Atualiza os dados de um carro específico.',
    request: Req(
      params: z.map({'id': z.string().uuid()}).openapiSchema(),
      json: carUpdateSchema,
    ),
    responses: updateCarResponses,
  );
  api.openapi(updateCar, [], controller.update);

  final deleteCar = createRoute(
    method: 'delete',
    path: '/cars/:id',
    summary: 'Deleta um carro pelo ID',
    tags: ['Carros'],
    description: 'Remove um carro específico do estoque.',
    request: Req(params: z.map({'id': z.string().uuid()}).openapiSchema()),
    responses: deleteCarResponses,
  );
  api.openapi(deleteCar, [], controller.delete);
}
