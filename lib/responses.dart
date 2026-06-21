import 'package:darto_openapi/darto_openapi.dart';
import 'package:darto_car_dealership/models.dart';

// --- Respostas Globais/Comuns ---
final resNotFound = Res('Recurso não encontrado');
final resBadRequest = Res('Requisição inválida ou parâmetros incorretos');

// --- Respostas Específicas das Rotas ---

final listCarsResponses = {
  200: Res('Retorna a lista de carros', body: Schema.array(carSchema)),
};

final getCarByIdResponses = {
  200: Res('Retorna o carro solicitado', body: carSchema),
  404: resNotFound,
  400: resBadRequest,
};

final createCarResponses = {
  201: Res('Carro adicionado com sucesso', body: carCreateResponseSchema),
  400: resBadRequest,
};
