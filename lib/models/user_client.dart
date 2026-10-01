import '../../../models/training_block.dart';
import '../../../models/user_abstract.dart';

class UserClient extends AbstractUser {
  String uniqueCodeClient = "";
  List<TrainingBlock> listTrainingBlock = [];
}
