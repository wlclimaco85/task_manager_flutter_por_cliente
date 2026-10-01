import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/user_banners.dart';
import '../screens/update_profile.dart';
import '../../../widgets/home_modal_add.dart';
import '../../../widgets/home_list_model.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../widgets/input_field_busca.dart';
import '../../../widgets/itens_list_personal.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
class PersonalScreen extends StatefulWidget {
  const PersonalScreen({
    super.key,
  });

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

final TextEditingController _taskNameController = TextEditingController();
final TextEditingController _taskDescriptionController =
    TextEditingController();
List<Widget> mywidgets = [];
bool _isLoading = false;

class _PersonalScreenState extends State<PersonalScreen> {
  @override
  void initState() {
    findAllPersonal();
    super.initState();
  }

  bool standardSelected = false;
  bool filledSelected = false;
  bool tonalSelected = false;
  bool outlinedSelected = false;
  int count = 0;

  void log(String message) => L.d(message);

  bool _addNewTaskLoading = false;

  void onPresseds() => Navigator.push(
      context, MaterialPageRoute(builder: (context) => const HomeModalAdd()));

  Future<void> findAllPersonal() async {
    _isLoading = true;
    _addNewTaskLoading = true;
    if (mounted) {
      setState(() {});
    }
    Map<String, dynamic> requestBody = {
      "cref": '',
      "id": 1,
    };

    final NetworkResponse response =
        await NetworkCaller().postRequest(ApiLinks.allPersonal, requestBody);
    _addNewTaskLoading = false;
    if (mounted) {
      setState(() {});
    }
    if (response.isSuccess) {
      _taskNameController.clear();
      _taskDescriptionController.clear();
      if (mounted) {
        dynamic data = response.body?['data'];
        List<dynamic> datas = data['personalDto'];
        mywidgets = [];
        mywidgets.add(InputBuscarField(
            hint: "Buscar Personal ",
            obscure: false,
            icon: Icons.person_outline,
            onPresseds: onPresseds));
        for (var element in datas) {
          mywidgets.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListItensExample(
                  nome: element['codDadosPessoal']['nome'],
                  cpf: element['codDadosPessoal']['cpf'],
                  cref: element['cref'],
                  valor: element['vlrAula'],
                  foto: element['codDadosPessoal']['photo'],
                  id: element['id'],
                ),
              ],
            ),
          );
        }
        _isLoading = false;
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Task Added Failed"),
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
