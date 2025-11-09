import 'package:hive/hive.dart';

import '../../domain/models/expense.dart';
import '../hive/hive_services.dart';

class ExpenseRepository {
  Box<Expense> get box => Hive.box<Expense>(HiveService.expensesBox);

  List<Expense> getAll() => box.values.toList();

  Future<void> add(Expense expense) async => await box.add(expense);

  Future<void> update(Expense expense) async {
    if (expense.key != null) await box.put(expense.key, expense);
  }

  Future<void> delete(Expense expense) async {
    if (expense.key != null) await box.delete(expense.key);
  }
}