import 'package:hive/hive.dart';
import '../../domain/models/invoice.dart';
import '../hive/hive_services.dart';

class InvoiceRepository {
  Box<Invoice> get box => Hive.box<Invoice>(HiveService.invoicesBox);

  List<Invoice> getAll() => box.values.toList();

  Future<void> add(Invoice invoice) async => await box.add(invoice);

  Future<void> update(Invoice invoice) async {
    if (invoice.key != null) await box.put(invoice.key, invoice);
  }

  Future<void> delete(Invoice invoice) async {
    if (invoice.key != null) await box.delete(invoice.key);
  }
}