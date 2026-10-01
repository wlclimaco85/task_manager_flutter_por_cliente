import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../models/task_model.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../../models/noticias_model.dart';
import '../../web/screens/update_profile.dart';
import '../../web/screens/newsDetailScreen.dart';
import '../../../widgets/user_banners.dart';
import '../../constants/custom_colors.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
class WebTaskScreens extends StatefulWidget {
  final String screenStatus;
  final String apiLink;
  final bool showAllSummeryCard;
  final bool floatingActionButton;

  const WebTaskScreens({
    super.key,
    required this.screenStatus,
    required this.apiLink,
    this.showAllSummeryCard = false,
    this.floatingActionButton = true,
  });

  @override
  State<WebTaskScreens> createState() => _TaskScreenState();
}

class NoticiaModel {
  String? status;
  String? token;
  List<Data>? data;

  NoticiaModel({this.status, this.token, this.data});

  NoticiaModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];

    // Verifica se 'data' é uma lista de listas
    if (json['data'] != null) {
      /*  data = [];
    // Itera sobre cada lista no 'data'
    for (var list in json['data']) {
      // Adiciona à lista de 'data' uma lista de Map<String, dynamic>
      data.add(List<Map<String, dynamic>>.from(list.map((item) => Map<String, dynamic>.from(item))));
    } */
      //  List<Data> dataList = Data.fromJsonList2(json['data']['noticiasDTO']);
      List<Data> dataList = Data.fromJsonList(json['data']['noticiasDTO']);
      data =
          dataList; //json['data'] != null ? Data.fromJson(json['data']) : null;
    } else {
      data = null;
    }

    //data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  /* Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }*/

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (this.data != null) {
      // Mapeia cada item da lista 'data' para o formato JSON
      data['data'] = this.data!.map((item) => item.toJson()).toList();
    }
    return data;
  }
}

class _TaskScreenState extends State<WebTaskScreens> {
  List<Data> newsList = [];
  bool isLoading = false;
  int page = 1;

  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchNews();
    _controller.addListener(_onScroll);
  }

  Future<void> fetchNews({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        page = 1;
        newsList.clear();
      });
    }

    setState(() {
      isLoading = true;
    });

    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.allNoticias,
    );

    if (response.statusCode == 200) {
      if (response.body != null) {
        final jsonString = json.encode(response.body);
        final model = NoticiaModel.fromJson(response.body!);
        if (model.data != null) {
          setState(() {
            newsList.addAll(model.data!);
            page++;
          });
        }
      }
    } else {
      throw Exception('Falha ao carregar as notícias');
    }

    setState(() {
      isLoading = false;
    });
  }

  void _onScroll() {
    if (_controller.position.pixels == _controller.position.maxScrollExtent &&
        !isLoading) {
      fetchNews();
    }
  }

  Future<void> _refreshNews() async {
    await fetchNews(isRefresh: true);
  }

  TaskListModel _taskModel = TaskListModel();

  Future<void> getTask() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    final NetworkResponse response = await NetworkCaller().getRequest(
      widget.apiLink,
    );
    if (response.isSuccess) {
      _taskModel = TaskListModel.fromJson(response.body!);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to load data!")));
      }
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  int count1 = 0;
  int count2 = 0;
  int count3 = 0;
  int count4 = 0;

  Future<void> statusCount() async {
    isLoading = true;
    if (mounted) {
      setState(() {});
    }
    final NetworkResponse newTaskResponse = await NetworkCaller().getRequest(
      ApiLinks.newTaskStatus,
    );
    TaskListModel newTaskModel = TaskListModel.fromJson(
      (newTaskResponse.body != null ? newTaskResponse.body! : {}),
    );

    if (mounted) {
      setState(() {
        count1 = newTaskModel.data?.length ?? 0;
      });
    }

    final cancelledTaskResponse = await NetworkCaller().getRequest(
      ApiLinks.cancelledTaskStatus,
    );
    TaskListModel cancelledTaskModel = TaskListModel.fromJson(
      cancelledTaskResponse.body != null ? cancelledTaskResponse.body! : {},
    );
    if (mounted) {
      setState(() {
        count2 = cancelledTaskModel.data?.length ?? 0;
      });
    }

    final completedTaskResponse = await NetworkCaller().getRequest(
      ApiLinks.completedTaskStatus,
    );

    TaskListModel completedTaskModel = TaskListModel.fromJson(
      completedTaskResponse.body != null ? completedTaskResponse.body! : {},
    );
    if (mounted) {
      setState(() {
        count3 = completedTaskModel.data?.length ?? 0;
      });
    }

    final inProgressResponse = await NetworkCaller().getRequest(
      ApiLinks.inProgressTaskStatus,
    );
    TaskListModel inProgressTaskModel = TaskListModel.fromJson(
      inProgressResponse.body != null ? inProgressResponse.body! : {},
    );
    if (mounted) {
      setState(() {
        count4 = inProgressTaskModel.data?.length ?? 0;
      });
    }

    isLoading = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.deleteTask(taskId),
    );
    if (response.isSuccess) {
      _taskModel.data!.removeWhere((element) => element.sId == taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task Deleted Successfully!")),
        );
      }
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // int getCountForStatus(String status) {
  //   final Data? statusData = statusCountModel.data?.firstWhere(
  //     (data) => data.statusId == status,
  //     orElse: () => Data(statusId: status, count: 0),
  //   );
  //   return statusData?.count ?? 0;
  // }
  bool standardSelected = false;
  bool filledSelected = false;
  bool tonalSelected = false;
  bool outlinedSelected = false;
  int count = 0;

  void log(String message) => L.d(message);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserBannerAppBar(
        screenTitle: "Notícias",
        isLoading: isLoading,
        onRefresh: _refreshNews,
        onTapped: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WebUpdateProfileScreen(),
            ),
          );
        },
      ),
      body: Container(
        color: CustomColors().getLightGreenBackground(), // Cor de fundo da tela
        child: RefreshIndicator(
          onRefresh: _refreshNews,
          child: Stack(
            children: [
              ListView.builder(
                controller: _controller,
                itemCount: newsList.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == newsList.length) {
                    return isLoading
                        ? const Center(
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                strokeWidth: 6.0,
                              ),
                            ),
                          )
                        : const SizedBox.shrink();
                  }

                  final news = newsList[index];
                  return Card(
                    elevation: 0, // Remove a sombra padrão do Card
                    color: Colors.transparent, // Remove a cor de fundo
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // Bordas retas
                      side: BorderSide.none, // Remove qualquer borda
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            news.tituloResu ?? 'Título não disponível',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CustomColors().getTextColor(),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                news.resumo ?? 'Resumo não disponível',
                                style: TextStyle(
                                  color: CustomColors().getTextColor(),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${news.fonte ?? 'Fonte não disponível'}     ${news.dtNoticia != null ? DateFormat('dd/MM/yyyy HH:mm').format(news.dtNoticia!.toLocal()) : ''}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: CustomColors().getTextColor(),
                                    ),
                                  ),
                                  Text(
                                    news.autor ?? 'Autor não disponível',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: CustomColors().getTextColor(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WebNewsDetailScreen(news: news),
                              ),
                            );
                          },
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors
                              .grey, // Ou use CustomColors().getTextColor()
                          indent: 16,
                          endIndent: 16,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
