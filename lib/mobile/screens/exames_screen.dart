import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/user_banners.dart';
import '../screens/update_profile.dart';
import '../../../widgets/home_list_model.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../widgets/input_field_busca.dart';
import '../screens/exames_add.dart';
import '../screens/exames_list.dart';
import '../../../models/auth_utility.dart';
import '../../../models/login_model.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
class ExameScreen extends StatefulWidget {
  const ExameScreen({
    super.key,
  });

  @override
  State<ExameScreen> createState() => _ExameScreenState();
}

final TextEditingController _taskNameController = TextEditingController();
final TextEditingController _taskDescriptionController =
    TextEditingController();
List<Widget> mywidgets = [];
bool _isLoading = false;

class _ExameScreenState extends State<ExameScreen> {
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
        MaterialPageRoute(builder: (context) => const ExamesModalAdd()));

    final NetworkResponse response =
        await NetworkCaller().postRequest(ApiLinks.findByIdAluno, requestBody);
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
            hint: "Buscar Exames",
            obscure: false,
            icon: Icons.person_outline,
            onPresseds: onPressedss));
        for (var element in datas) {
          mywidgets.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListItensExames(
                    nome: element['nome'] ?? "",
                    medico: element['medico'] ?? "",
                    dataExame: element['dataExame'] ?? "",
                    dataEntrega: element['dataEntrega'] ?? "",
                    dataConsulta: element['dataConsulta'] ?? "",
                    laudo: element['resultado'] ?? ""),
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
            hint: "Buscar Exames",
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

  List<HomeListModel> listModels = [
    HomeListModel(
      title: "Academia - O Club",
      assetIcon: "assets/icons/gym_icon.png",
    ),
    HomeListModel(
      title: "Biometa Academia",
      assetIcon: "assets/icons/gym_icon.png",
    ),
    HomeListModel(
      title: "Academia Titanium Core",
      assetIcon: "assets/icons/gym_icon.png",
    )
  ];
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
