import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/hive/hive_services.dart';
import '../../data/repository/client_repository.dart';
import '../../data/repository/counter_repository.dart';
import '../../data/repository/expense_repository.dart';
import '../../data/repository/invoice_repository.dart';
import '../../data/repository/product_repository.dart';
import '../../data/repository/purchase_repository.dart';
import '../../domain/models/cachbox.dart';
import '../../domain/models/product_item.dart';
import '../../domain/models/client.dart';
import '../../domain/models/invoice.dart';
import '../../domain/models/invoice_item.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/purchase.dart';
import 'package:uuid/uuid.dart';

final productRepoProvider = Provider((ref) => ProductRepository());

final clientRepoProvider = Provider((ref) => ClientRepository());

final invoiceRepoProvider = Provider((ref) => InvoiceRepository());

final expenseRepoProvider = Provider((ref) => ExpenseRepository());

final countersRepoProvider = Provider((ref) => CountersRepository());

final purchaseRepoProvider = Provider((ref) => PurchaseRepository());

final productsProvider =
    StateNotifierProvider<ProductsController, List<ProductItem>>((ref) {
      return ProductsController(ref.read(productRepoProvider));
    });

class ProductsController extends StateNotifier<List<ProductItem>> {
  final ProductRepository repo;

  ProductsController(this.repo) : super([]) {
    load();
  }

  void load() {
    try {
      state = repo.getAll();
    } catch (e) {
      print('Error loading products: $e');
      state = [];
    }
  }

  Future<void> add(ProductItem item) async {
    try {
      await repo.add(item);
      load(); // تحديث الحالة بعد الإضافة
    } catch (e) {
      print('Error adding product: $e');
      throw Exception(
        'Failed to add product: $e',
      ); // رمي استثناء لمعالجة الأخطاء
    }
  }

  Future<void> update(ProductItem item) async {
    try {
      await repo.update(item);
      load(); // تحديث الحالة بعد التعديل
    } catch (e) {
      print('Error updating product: $e');
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> remove(ProductItem item) async {
    try {
      await repo.delete(item);
      load(); // تحديث الحالة بعد الحذف
    } catch (e) {
      print('Error removing product: $e');
      throw Exception('Failed to remove product: $e');
    }
  }
}

final clientsProvider = StateNotifierProvider<ClientsController, List<Client>>((
  ref,
) {
  return ClientsController(ref.read(clientRepoProvider));
});

class ClientsController extends StateNotifier<List<Client>> {
  final ClientRepository repo;

  ClientsController(this.repo) : super([]) {
    load();
  }

  void load() {
    try {
      state = repo.getAll();
    } catch (e) {
      print('Error loading clients: $e');
      state = [];
    }
  }

  Future<void> add(Client client) async {
    try {
      await repo.add(client);
      load();
    } catch (e) {
      print('Error adding client: $e');
      throw Exception('Failed to add client: $e');
    }
  }

  Future<void> update(Client client) async {
    try {
      await repo.update(client);
      load();
    } catch (e) {
      print('Error updating client: $e');
      throw Exception('Failed to update client: $e');
    }
  }

  List<Client> search(String query) {
    return state
        .where((c) => c.name.contains(query) || c.phone.contains(query))
        .toList();
  }
}

final invoicesProvider =
    StateNotifierProvider<InvoicesController, List<Invoice>>((ref) {
      return InvoicesController(
        ref.read(invoiceRepoProvider),
        ref.read(countersRepoProvider),
      );
    });

class InvoicesController extends StateNotifier<List<Invoice>> {
  final InvoiceRepository repo;
  final CountersRepository counters;

  InvoicesController(this.repo, this.counters) : super([]) {
    load();
  }

  void load() {
    try {
      state = repo.getAll();
    } catch (e) {
      print('Error loading invoices: $e');
      state = [];
    }
  }

  Future<String> createInvoice({
    String? clientId,
    required List<InvoiceItem> items,
    required PaymentType paymentType,
    double discount = 0,
    bool isPaid = false,
  }) async {
    try {
      final id = const Uuid().v4();
      final number = counters.nextInvoiceNumber().toString().padLeft(6, '0');
      final invoice = Invoice(
        id: id,
        number: number,
        date: DateTime.now(),
        clientId: clientId,
        items: items,
        paymentType: paymentType,
        discount: discount,
        isPaid: isPaid,
      );
      await repo.add(invoice);
      load(); // تحديث الحالة بعد إضافة الفاتورة
      return id;
    } catch (e) {
      print('Error creating invoice: $e');
      throw Exception('Failed to create invoice: $e');
    }
  }

  Future<void> update(Invoice invoice) async {
    try {
      await repo.update(invoice);
      load(); // تحديث الحالة بعد التعديل
    } catch (e) {
      print('Error updating invoice: $e');
      throw Exception('Failed to update invoice: $e');
    }
  }
}

final expensesProvider =
    StateNotifierProvider<ExpensesController, List<Expense>>((ref) {
      return ExpensesController(ref.read(expenseRepoProvider));
    });

class ExpensesController extends StateNotifier<List<Expense>> {
  final ExpenseRepository repo;

  ExpensesController(this.repo) : super([]) {
    load();
  }

  void load() {
    try {
      state = repo.getAll();
    } catch (e) {
      print('Error loading expenses: $e');
      state = [];
    }
  }

  Future<void> add(Expense expense) async {
    try {
      await repo.add(expense);
      load();
    } catch (e) {
      print('Error adding expense: $e');
      throw Exception('Failed to add expense: $e');
    }
  }
}

final cashboxProvider = StateNotifierProvider<CashboxController, Cashbox>((
  ref,
) {
  return CashboxController();
});

class CashboxController extends StateNotifier<Cashbox> {
  CashboxController() : super(Cashbox(balance: 0)) {
    load();
  }

  void load() {
    try {
      final box = Hive.box<Cashbox>(HiveService.cashboxBox);
      if (box.isNotEmpty) {
        state = box.getAt(0) ?? Cashbox(balance: 0);
      }
    } catch (e) {
      print('Error loading cashbox: $e');
      state = Cashbox(balance: 0);
    }
  }

  Future<void> addAmount(double amount) async {
    try {
      state = Cashbox(balance: state.balance + amount);
      final box = Hive.box<Cashbox>(HiveService.cashboxBox);
      if (box.isEmpty) {
        await box.add(state);
      } else {
        await box.putAt(0, state);
      }
    } catch (e) {
      print('Error adding amount to cashbox: $e');
      throw Exception('Failed to add amount to cashbox: $e');
    }
  }
}

final purchasesProvider =
    StateNotifierProvider<PurchasesController, List<Purchase>>((ref) {
      return PurchasesController(ref.read(purchaseRepoProvider));
    });

class PurchasesController extends StateNotifier<List<Purchase>> {
  final PurchaseRepository repo;

  PurchasesController(this.repo) : super([]) {
    load();
  }

  Future<void> load() async {
    try {
      state = await repo.getAll();
    } catch (e) {
      print('Error loading purchases: $e');
      state = [];
    }
  }

  Future<void> add(Purchase purchase) async {
    try {
      await repo.add(purchase);
      load();
    } catch (e) {
      print('Error adding purchase: $e');
      throw Exception('Failed to add purchase: $e');
    }
  }

  Future<void> update(Purchase purchase) async {
    try {
      await repo.update(purchase);
      load();
    } catch (e) {
      print('Error updating purchase: $e');
      throw Exception('Failed to update purchase: $e');
    }
  }

  Future<void> remove(Purchase purchase) async {
    try {
      await repo.delete(purchase);
      load();
    } catch (e) {
      print('Error removing purchase: $e');
      throw Exception('Failed to remove purchase: $e');
    }
  }
}
