import 'package:darto_zard_openapi/darto_zard_openapi.dart';
import 'package:darto_car_dealership/models.dart';

// --- Respostas Específicas das Rotas ---

final errorSchema = z
    .map({'message': z.string(), 'error': z.string(), 'statusCode': z.int()})
    .openapiSchema('Error');

final messageSchema = z.map({'message': z.string()}).openapiSchema('Message');

final listCarsResponses = [
  Res(200, 'Retorna a lista de carros', body: z.list(zCar).openapiSchema()),
];

final getCarByIdResponses = [
  Res(200, 'Retorna o carro solicitado', body: carSchema),
  Res(404, 'Carro não encontrado', body: errorSchema),
  Res(400, 'Requisição inválida', body: errorSchema),
];

final createCarResponses = [
  Res(201, 'Carro adicionado com sucesso', body: carSchema),
  Res(400, 'Requisição inválida'),
];

final updateCarResponses = [
  Res(200, 'Carro atualizado com sucesso', body: carSchema),
  Res(404, 'Carro não encontrado'),
  Res(400, 'Requisição inválida'),
];

final deleteCarResponses = [
  Res(200, 'Carro deletado com sucesso', body: messageSchema),
  Res(404, 'Carro não encontrado'),
  Res(400, 'Requisição inválida'),
];
