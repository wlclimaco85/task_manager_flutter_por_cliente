import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/user_banners.dart';
import '../../windows/screens/update_profile.dart';
import '../../../widgets/home_list_model.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../widgets/input_field_busca.dart';
import '../../windows/screens/suplemento_list.dart';
import '../../windows/screens/suplemento_add.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
class WindowsSuplementoScreen extends StatefulWidget {
  const WindowsSuplementoScreen({super.key});

  @override
  State<WindowsSuplementoScreen> createState() => _SuplementoScreenState();
}

final TextEditingController _taskNameController = TextEditingController();
final TextEditingController _taskDescriptionController =
    TextEditingController();
List<Widget> mywidgets = [];
bool _isLoading = false;

class _SuplementoScreenState extends State<WindowsSuplementoScreen> {
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
    Map<String, dynamic> requestBody = {
      "codAluno": {"id": 1},
    };

    void onPressedss() => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SuplementoModalAdd()),
        );

    final NetworkResponse response = await NetworkCaller().postRequest(
      ApiLinks.allSuplementoAluno,
      requestBody,
    );
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
        mywidgets.add(
          InputBuscarField(
            hint: "Buscar Suplemento",
            obscure: false,
            icon: Icons.person_outline,
            onPresseds: onPressedss,
          ),
        );
        for (var element in datas) {
          mywidgets.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListItensSuplemento(
                  nome: element['nome'] ?? "",
                  marca: element['marca'] ?? "",
                  dataIni: element['dtInicio'] ?? "",
                  dataFin: element['dtFinal'] ?? "",
                  dataVal: element['dtVal'] ?? "",
                  porcao: element['dosagem'] ?? "",
                  foto: element['foto'],
                  id: element['id'],
                  valor: element['valor'] ?? "",
                  sabor: element['sabor'] ?? "",
                  tamanho: element['tamanho'] ?? "",
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
        mywidgets.add(
          InputBuscarField(
            hint: "Buscar Suplemento",
            obscure: false,
            icon: Icons.person_outline,
            onPresseds: onPressedss,
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nenhuma suplemento cadastrado!")),
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
    ),
  ];
  void refreshPage() {
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
              builder: (context) => const WindowsUpdateProfileScreen(),
            ),
          );
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
