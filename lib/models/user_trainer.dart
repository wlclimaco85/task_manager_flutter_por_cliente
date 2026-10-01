import '../../../models/user_abstract.dart';
import '../../../models/user_client.dart';

class UserTrainer extends AbstractUser {
  // Lista de ids dos clientes (API)
  List<int> listClientIds = [];

  // Lista dos Clientes
  List<UserClient> listClients = [];
}
