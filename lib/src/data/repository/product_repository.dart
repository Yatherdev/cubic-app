import 'package:hive/hive.dart';
import '../../domain/models/product_item.dart';
import '../hive/hive_services.dart';

class ProductRepository {
  Box<ProductItem> get box => Hive.box<ProductItem>(HiveService.productsBox);

  List<ProductItem> getAll() => box.values.toList();

  Future<void> add(ProductItem item) async {
    await box.add(item);
  }

  Future<void> update(ProductItem item) async {
    if (item.key != null) {
      await box.put(item.key, item);
    } else {
      await box.add(item);
    }
  }

  Future<void> delete(ProductItem item) async {
    if (item.key != null) await box.delete(item.key);
  }
}