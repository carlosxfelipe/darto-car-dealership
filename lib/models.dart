import 'package:darto_openapi/darto_openapi.dart';

final carSchema = Schema.object({
  'id': Schema.integer(),
  'brand': Schema.string(),
  'model': Schema.string(),
});

final carCreateSchema = Schema.object({
  'brand': Schema.string(minLength: 2),
  'model': Schema.string(minLength: 2),
}, required: [
  'brand',
  'model'
]);

final carCreateResponseSchema = Schema.object({
  'status': Schema.string(),
  'car': carSchema,
});
