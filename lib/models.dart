import 'package:darto_zard_openapi/darto_zard_openapi.dart';

final zCar = z.map({
  'id': z.string().uuid(),
  'brand': z.string(),
  'model': z.string(),
});
final carSchema = zCar.openapiSchema('Car');

final zCarCreate = z.map({'brand': z.string(), 'model': z.string()}).strict();
final carCreateSchema = zCarCreate.openapiSchema('CarCreate');

final zCarUpdate = z.map({
  'id': z.string().uuid().optional(),
  'brand': z.string().optional(),
  'model': z.string().optional(),
}).strict();
final carUpdateSchema = zCarUpdate.openapiSchema('CarUpdate');
