import 'package:darto/darto.dart';
import 'package:darto_openapi/darto_openapi.dart';
import 'package:darto_car_dealership/cars_service.dart';

void main() async {
  final app = Darto();

  // Integrando o plugin oficial do ecossistema Darto para Swagger/OpenAPI
  final api = OpenApi(app,
      info: Info(title: 'Oficial Car Dealership API', version: '1.0.0'));

  // Monta a interface interativa (Scalar) no /docs
  app.use(api.docs());

  final carsService = CarsService();

  api.get(
    '/cars',
    summary: 'Lista todos os carros',
    description: 'Retorna a lista de carros em estoque.',
    responses: {
      200: Res('Retorna a lista de carros',
          body: Schema.array(Schema.object({
            'id': Schema.integer(),
            'brand': Schema.string(),
            'model': Schema.string(),
          })))
    },
    handler: (c) => c.ok(carsService.findAll()),
  );

  api.get(
    '/cars/:id',
    summary: 'Pega um carro pelo ID',
    description: 'Busca um carro específico pelo seu ID.',
    request: Req(params: {'id': Schema.integer()}),
    responses: {
      200: Res('Retorna o nome do carro',
          body: Schema.object({
            'id': Schema.integer(),
            'brand': Schema.string(),
            'model': Schema.string(),
          })),
      404: Res('Carro não encontrado'),
      400: Res('O ID fornecido não é um número válido')
    },
    handler: (Context c) {
      final params = c.req.valid<Map<String, dynamic>>('param');
      final id = params['id'] as int;

      final car = carsService.findOneById(id);
      if (car != null) {
        return c.ok(car);
      }
      return c.status(404).json({'error': 'Not found'});
    },
  );

  api.post(
    '/cars',
    summary: 'Adiciona um carro',
    description: 'Adiciona um novo carro ao estoque.',
    request: Req(
        json: Schema.object({
      'brand': Schema.string(minLength: 2),
      'model': Schema.string(minLength: 2),
    }, required: [
      'brand',
      'model'
    ])),
    responses: {
      201: Res('Carro adicionado com sucesso',
          body: Schema.object({
            'status': Schema.string(),
            'car': Schema.object({
              'id': Schema.integer(),
              'brand': Schema.string(),
              'model': Schema.string(),
            })
          }))
    },
    handler: (Context c) {
      final body = c.req.valid<Map<String, dynamic>>('json');
      final car =
          carsService.create(body['brand'] as String, body['model'] as String);
      return c.created({
        'status': 'Carro ${car["brand"]} adicionado com sucesso!',
        'car': car
      });
    },
  );

  await app.listen(3000, () => print('Listening on http://localhost:3000'));
}
