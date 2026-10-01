import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/user_banners.dart';
import '../screens/update_profile.dart';
import '../../../widgets/home_list_model.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../widgets/input_field_busca.dart';
import '../../../widgets/itens_list_academia.dart';
import '../../../widgets/academia_dynamic_form.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
class AcademiaScreen extends StatefulWidget {
  const AcademiaScreen({
    super.key,
  });

  @override
  State<AcademiaScreen> createState() => _AcademiaScreenState();
}

final TextEditingController _taskNameController = TextEditingController();
final TextEditingController _taskDescriptionController =
    TextEditingController();
List<Widget> mywidgets = [];
bool _isLoading = false;

class _AcademiaScreenState extends State<AcademiaScreen> {
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
      "cref": '',
      "id": 1,
    };

    void onPressedss() => Navigator.push(context,
        MaterialPageRoute(builder: (context) => const AcademiaDynamicForm()));

    final NetworkResponse response =
        await NetworkCaller().postRequest(ApiLinks.allAcademia, requestBody);
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
            hint: "Buscar Academia",
            obscure: false,
            icon: Icons.person_outline,
            onPresseds: onPressedss));
        for (var element in datas) {
          mywidgets.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListItensAcademia(
                    nome: element['codDadosPessoal']['nome'],
                    cpf: element['codDadosPessoal']['cpf'],
                    endereco: element['codDadosPessoal']['logradouro'] +
                        ", " +
                        element['codDadosPessoal']['numero'],
                    endereco1: element['codDadosPessoal']['bairro'] +
                        ", " +
                        element['codDadosPessoal']['cidade'],
                    telefone: element['codDadosPessoal']['telefone'] ?? "",
                    foto: element['codDadosPessoal']['photo'],
                    id: element['id'],
                    listModadelidades: element['modalidaList'] != null &&
                            element['modalidaList'].length > 0
                        ? getList(element['modalidaList'])
                        : modalidadeList),
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
            hint: "Buscar Academia",
            obscure: false,
            icon: Icons.person_outline,
            onPresseds: onPressedss));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Nenhuma academia cadastrada!"),
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
