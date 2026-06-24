import 'package:darto_openapi/darto_openapi.dart';
import 'package:darto_car_dealership/models.dart';

// --- Respostas Específicas das Rotas ---

final listCarsResponses = {
  200: Res('Retorna a lista de carros', body: Schema.array(carSchema)),
};

final getCarByIdResponses = {
  200: Res('Retorna o carro solicitado', body: carSchema),
  404: Res('Carro não encontrado', body: Schema.object({
    'message': Schema.string(),
    'error': Schema.string(),
    'statusCode': Schema.integer(),
  })),
  400: Res('Requisição inválida', body: Schema.object({
    'message': Schema.string(),
    'error': Schema.string(),
    'statusCode': Schema.integer(),
  })),
};

final createCarResponses = {
  201: Res('Carro adicionado com sucesso', body: carSchema),
  400: Res('Requisição inválida'),
};

final updateCarResponses = {
  200: Res('Carro atualizado com sucesso', body: carSchema),
  404: Res('Carro não encontrado'),
  400: Res('Requisição inválida'),
};

final deleteCarResponses = {
  200: Res('Carro deletado com sucesso', body: Schema.object({'message': Schema.string()})),
  404: Res('Carro não encontrado'),
  400: Res('Requisição inválida'),
};
