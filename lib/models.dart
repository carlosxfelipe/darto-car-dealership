import 'package:darto_openapi/darto_openapi.dart';

final carSchema = Schema.object({
  'id': Schema.string(format: 'uuid'),
  'brand': Schema.string(),
  'model': Schema.string(),
});

final carCreateSchema = Schema.object({
  'brand': Schema.string(),
  'model': Schema.string(),
}, required: [
  'brand',
  'model'
], additionalProperties: false);

final carUpdateSchema = Schema.object({
  'id': Schema.string(format: 'uuid'),
  'brand': Schema.string(),
  'model': Schema.string(),
}, additionalProperties: false);

