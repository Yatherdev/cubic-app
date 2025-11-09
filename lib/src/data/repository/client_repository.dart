import 'package:hive/hive.dart';
import '../../domain/models/client.dart';
import '../hive/hive_services.dart';

class ClientRepository {
  Box<Client> get box => Hive.box<Client>(HiveService.clientsBox);

  List<Client> getAll() => box.values.toList();

  Future<void> add(Client client) async => await box.add(client);

  Future<void> update(Client client) async {
    if (client.key != null) await box.put(client.key, client);
  }

  Future<void> delete(Client client) async {
    if (client.key != null) await box.delete(client.key);
  }
}
