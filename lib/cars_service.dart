import 'package:uuid/uuid.dart';

class CarsService {
  final _uuid = Uuid();
  late List<Map<String, dynamic>> _cars;

  CarsService() {
    _cars = [
      {
        'id': _uuid.v4(),
        'brand': 'Toyota',
        'model': 'Corolla',
      },
      {
        'id': _uuid.v4(),
        'brand': 'Honda',
        'model': 'Civic',
      },
      {
        'id': _uuid.v4(),
        'brand': 'Jeep',
        'model': 'Cherokee',
      },
    ];
  }

  List<Map<String, dynamic>> findAll() {
    return _cars;
  }

  Map<String, dynamic>? findOneById(String id) {
    try {
      return _cars.firstWhere((car) => car['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> create(String brand, String model) {
    final newCar = {
      'id': _uuid.v4(),
      'brand': brand,
      'model': model,
    };
    _cars.add(newCar);
    return newCar;
  }

  Map<String, dynamic>? update(String id, Map<String, dynamic> updateCarDto) {
    final car = findOneById(id);
    if (car == null) return null;
    
    car['brand'] = updateCarDto['brand'] ?? car['brand'];
    car['model'] = updateCarDto['model'] ?? car['model'];
    
    return car;
  }

  void delete(String id) {
    _cars.removeWhere((car) => car['id'] == id);
  }
}
