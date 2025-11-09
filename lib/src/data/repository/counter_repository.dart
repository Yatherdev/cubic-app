import 'package:hive/hive.dart';

import '../hive/hive_services.dart';
class CountersRepository {
  Box<int> get box => Hive.box<int>(HiveService.countersBox);

  int nextInvoiceNumber() {
    final current = box.get('invoiceNumber', defaultValue: 0) ?? 0;
    box.put('invoiceNumber', current + 1);
    return current + 1;
  }
}