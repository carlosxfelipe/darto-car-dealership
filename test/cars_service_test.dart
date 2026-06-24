import 'package:test/test.dart';
import 'package:darto_car_dealership/cars_service.dart';

void main() {
  group('CarsService', () {
    late CarsService carsService;

    setUp(() {
      carsService = CarsService();
    });

    test('findAll should return all initial cars', () {
      final cars = carsService.findAll();
      expect(cars.length, 3);
      expect(cars.first['brand'], 'Toyota');
    });

    test('findOneById should return the correct car', () {
      final cars = carsService.findAll();
      final id = cars[1]['id'] as String;
      
      final car = carsService.findOneById(id);
      expect(car, isNotNull);
      expect(car?['brand'], 'Honda');
      expect(car?['model'], 'Civic');
    });

    test('findOneById should return null for non-existent id', () {
      final car = carsService.findOneById('non-existent-id');
      expect(car, isNull);
    });

    test('create should add a new car and return it', () {
      final newCar = carsService.create('Ford', 'Mustang');
      expect(newCar['id'], isA<String>());
      expect(newCar['brand'], 'Ford');
      expect(newCar['model'], 'Mustang');

      final cars = carsService.findAll();
      expect(cars.length, 4);
      expect(cars.last['brand'], 'Ford');
    });
    
    test('update should modify existing car', () {
      final cars = carsService.findAll();
      final id = cars[0]['id'] as String;
      
      final updatedCar = carsService.update(id, {'brand': 'Lexus', 'model': 'RX'});
      expect(updatedCar, isNotNull);
      expect(updatedCar?['brand'], 'Lexus');
      expect(updatedCar?['model'], 'RX');
    });
    
    test('delete should remove existing car', () {
      final cars = carsService.findAll();
      final id = cars[0]['id'] as String;
      
      carsService.delete(id);
      expect(carsService.findAll().length, 2);
      expect(carsService.findOneById(id), isNull);
    });
  });
}
