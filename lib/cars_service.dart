class CarsService {
  final List<Map<String, dynamic>> _cars = [
    {
      'id': 1,
      'brand': 'Toyota',
      'model': 'Corolla',
    },
    {
      'id': 2,
      'brand': 'Honda',
      'model': 'Civic',
    },
    {
      'id': 3,
      'brand': 'Jeep',
      'model': 'Cherokee',
    },
  ];

  List<Map<String, dynamic>> findAll() {
    return _cars;
  }

  Map<String, dynamic>? findOneById(int id) {
    try {
      return _cars.firstWhere((car) => car['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> create(String brand, String model) {
    final newCar = {
      'id': _cars.isNotEmpty ? (_cars.last['id'] as int) + 1 : 1,
      'brand': brand,
      'model': model,
    };
    _cars.add(newCar);
    return newCar;
  }
}
