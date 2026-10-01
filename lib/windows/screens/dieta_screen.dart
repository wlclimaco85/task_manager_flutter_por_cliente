import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../utils/fotos_util.dart';
import '../../../utils/pdf_export_helper.dart';
import '../../../widgets/user_banners.dart';
import '../../../windows/screens/update_profile.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../widgets/input_field_busca.dart';
import '../../../windows/screens/dieta_add.dart';
import '../../../windows/screens/dieta_list.dart';
import '../../../models/auth_utility.dart';
import '../../models/login_model.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
class WindowsDietacreen extends StatefulWidget {
  const WindowsDietacreen({super.key});

  @override
  State<WindowsDietacreen> createState() => _DietacreenState();
}

final TextEditingController _taskNameController = TextEditingController();
final TextEditingController _taskDescriptionController =
    TextEditingController();
List<Widget> mywidgets = [];
bool _isLoading = false;

class _DietacreenState extends State<WindowsDietacreen> {
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

  /// Dados brutos de dieta para exportação PDF.
  List<Map<String, dynamic>> _dietasDados = [];

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
      "codAluno": {"id": 1},
    };

    void onPressedss() => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DietaModalAdd()),
        );

    final NetworkResponse response = await NetworkCaller().postRequest(
      ApiLinks.findByAlunoByDieta,
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
        _dietasDados = datas.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        mywidgets = [];
        mywidgets.add(
          InputBuscarField(
            hint: "Buscar Dieta",
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
                ListItensDieta(
                  nutricionista: element['nutricionista'] ?? "",
                  objetivo: element['objetivo'] ?? "",
                  dtConsulta: element['dtConsulta'] ?? "",
                  descricao: element['descricao'] ?? "",
                  oQueAchou: element['oQueAchou'] ?? "",
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
        mywidgets.add(
          InputBuscarField(
            hint: "Buscar Dieta",
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
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Exportar PDF',
        backgroundColor: const Color(0xFF93070A),
        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
        label: const Text('Exportar PDF', style: TextStyle(color: Colors.white)),
        onPressed: _dietasDados.isEmpty
            ? null
            : () {
                final nomeAluno = AuthUtility.userInfo?.data?.codDadosPessoal?.nome ?? 'Aluno';
                final primeiro = _dietasDados.first;
                PdfExportHelper.exportarDieta(
                  context,
                  nomeAluno: nomeAluno,
                  nutricionista: primeiro['nutricionista']?.toString() ?? '',
                  objetivo: primeiro['objetivo']?.toString() ?? '',
                  dtConsulta: primeiro['dtConsulta']?.toString() ?? '',
                  dtInicio: primeiro['dtInicio']?.toString() ?? '',
                  dtFinal: primeiro['dtFinal']?.toString() ?? '',
                  descricao: primeiro['descricao']?.toString() ?? '',
                  oQueAchou: primeiro['oQueAchou']?.toString() ?? '',
                  nota: (primeiro['nota'] as int?) ?? 0,
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
