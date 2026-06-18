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
      final car = carsService.findOneById(2);
      expect(car, isNotNull);
      expect(car?['brand'], 'Honda');
      expect(car?['model'], 'Civic');
    });

    test('findOneById should return null for non-existent id', () {
      final car = carsService.findOneById(99);
      expect(car, isNull);
    });

    test('create should add a new car and return it', () {
      final newCar = carsService.create('Ford', 'Mustang');
      expect(newCar['id'], 4);
      expect(newCar['brand'], 'Ford');
      expect(newCar['model'], 'Mustang');

      final cars = carsService.findAll();
      expect(cars.length, 4);
      expect(cars.last['brand'], 'Ford');
    });
  });
}
