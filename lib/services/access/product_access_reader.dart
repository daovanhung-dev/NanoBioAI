import 'product_access_level.dart';

abstract class ProductAccessReader {
  Future<ProductAccessLevel> read();
}
