import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../utils/fotos_util.dart';
import '../../../widgets/user_banners.dart';
import '../screens/update_profile.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../widgets/input_field_busca.dart';
import '../screens/Medicamento_add.dart';
import '../screens/Medicamento_list.dart';
import '../../../models/auth_utility.dart';
import '../../../models/login_model.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
class Medicamentoscreen extends StatefulWidget {
  const Medicamentoscreen({
    super.key,
  });

  @override
  State<Medicamentoscreen> createState() => _MedicamentoscreenState();
}

final TextEditingController _taskNameController = TextEditingController();
final TextEditingController _taskDescriptionController =
    TextEditingController();
List<Widget> mywidgets = [];
bool _isLoading = false;

class _MedicamentoscreenState extends State<Medicamentoscreen> {
  @override
  void initState() {
    findAllAcademia();
    super.initState();
  }

  bool standardSelected = false;
  bool filledSelected = false;
  bool tonalSelected = false;
  bool outlinedSelected = false;
  int count = 0;
  final List<String> modalidadeList = ['Musculação'];

  void log(String message) => L.d(message);

  bool _addNewTaskLoading = false;

  List<String> getList(List<dynamic> newMap) {
    late List<String> modList = [];
    for (var v in newMap) {
      Map<String, dynamic> request = v;
      modList.add(v['nome']);
    }

    return modList;
  }

  Future<void> findAllAcademia() async {
    _isLoading = true;
    _addNewTaskLoading = true;
    if (mounted) {
      setState(() {});
    }
    Data userInfo = AuthUtility.userInfo?.data ?? Data();

    Map<String, dynamic> af = {};
    af["id"] = userInfo.id;
    Map<String, dynamic> requestBody = {
      "idaluno": {"id": 1},
    };

    void onPressedss() => Navigator.push(context,
        MaterialPageRoute(builder: (context) => const MedicamentosModalAdd()));

    final NetworkResponse response = await NetworkCaller()
        .postRequest(ApiLinks.findByAlunoByMedicamento, requestBody);
    _addNewTaskLoading = false;
    if (mounted) {
      setState(() {});
    }
    if (response.isSuccess) {
      _taskNameController.clear();
      _taskDescriptionController.clear();
      if (mounted) {
        dynamic data = response.body?['data'];
        List<dynamic> datas = data;
        mywidgets = [];
        mywidgets.add(InputBuscarField(
            hint: "Buscar Medicamentos",
            obscure: false,
            icon: Icons.person_outline,
            onPresseds: onPressedss));
        for (var element in datas) {
          mywidgets.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListItensMedicamentos(
                  medicamento: element['medicamento'] ?? "",
                  laboratorio: element['laboratorio'] ?? "",
                  medicoReceitou: element['medicoReceitou'] ?? "",
                  dosagem: element['dosagem'] ?? "",
                  descricao: element['descricao'] ?? "",
                  valor: element['valor'] ?? 0,
                  dtInicio: element['dtInicio'] ?? "",
                  dtFinal: element['dtFinal'] ?? "",
                  nota: element['nota'] ?? 0,
                  foto: element['fotos'] != null
                      ? verificFoto(element['fotos'][0])
                      : getImagepadrao(),
                ),
              ],
            ),
          );
        }
        _isLoading = false;
      }
    } else {
      if (mounted) {
        mywidgets = [];
        mywidgets.add(InputBuscarField(
            hint: "Buscar Medicamentos",
            obscure: false,
            icon: Icons.person_outline,
            onPresseds: onPressedss));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Nenhuma suplemento cadastrado!"),
          ),
        );
        _isLoading = false;
      }
    }
  }

  refreshPage() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  floatingActionButton: getHomeFab(context, listModels, refreshPage),
      backgroundColor: const Color(0xFF340A9C),
      appBar: UserBannerAppBar(
        onTapped: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const UpdateProfileScreen()));
        },
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: mywidgets,
          ),
        ),
      ),
    );
  }
}
