import 'package:flutter/material.dart';
import '../../../widgets/calendar_screen.dart';
import '../../../widgets/simple_tag.dart';
import '../screens/events_example.dart';
import '../../constants/custom_colors.dart';

class ListItensExames extends StatelessWidget {
  ListItensExames({
    super.key,
    required this.nome,
    required this.medico,
    required this.dataExame,
    required this.dataEntrega,
    required this.dataConsulta,
    required this.laudo,
  });

  final String nome;
  final String dataExame;
  final String laudo;
  final String medico;
  final String dataEntrega;
  final String dataConsulta;
  final String title = "";

  final List<String> listModadelidades = [];

  @override
  void initState() {
    listModadelidades.add(dataEntrega);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 200,
      alignment: Alignment.topCenter,
      color: Colors.transparent,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Flexible(
                child: Container(
                  height: 180,
                  color: CustomColors().getLightGreenBackground(),
                  child: Column(
                    children: [
                      Column(
                        children: <Widget>[
                          (Text(
                            'Exame: $nome ',
                            textAlign: TextAlign.start,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )), // <-- Wrapped in Flexible.
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          (Text(
                            'Medico: $medico',
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )), // <-- Wrapped in Flexible.
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          (Text(
                            'Data Exame: $dataExame  Data Entrega: $dataEntrega',
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              color: Color.fromARGB(255, 14, 13, 13),
                            ),
                          )), // <-- Wrapped in Flexible.
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          (Text(
                            'Data Consulta: $dataConsulta ',
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              color: Color.fromARGB(255, 14, 13, 13),
                            ),
                          )), // <-- Wrapped in Flexible.
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          (Text(
                            'Resultado Exame/Consulta: $laudo',
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              color: Color.fromARGB(255, 14, 13, 13),
                            ),
                          )), // <-- Wrapped in Flexible.
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                        width: 10,
                      ),
                      SimpleTag(content: listModadelidades),
                      const SizedBox(
                        height: 10,
                        width: double.infinity,
                      ),
                      const SizedBox(
                        height: 1,
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: Colors.black),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                        width: double.infinity,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(4.0),
                            decoration: const BoxDecoration(
                                color: Color(0xFFFA903A),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(6.0),
                                  topRight: Radius.circular(6.0),
                                  bottomLeft: Radius.circular(6.0),
                                  bottomRight: Radius.circular(6.0),
                                )),
                            child: Column(
                              children: <Widget>[
                                Tooltip(
                                  message: 'this is something',
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const TableComplexExample()));
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: Image.asset(
                                        "assets/images/anexo.ico",
                                        width: 30,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                            width: 10,
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(4.0),
                            decoration: const BoxDecoration(
                                color: Color(0xFFFA903A),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(6.0),
                                  topRight: Radius.circular(6.0),
                                  bottomLeft: Radius.circular(6.0),
                                  bottomRight: Radius.circular(6.0),
                                )),
                            child: Column(
                              children: <Widget>[
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const TableEventsExample()));
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.0),
                                    child: Image.asset(
                                      "assets/images/editar.ico",
                                      height: 30,
                                      width: 30,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                            width: 10,
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(4.0),
                            decoration: const BoxDecoration(
                                color: Color(0xFFFA903A),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(6.0),
                                  topRight: Radius.circular(6.0),
                                  bottomLeft: Radius.circular(6.0),
                                  bottomRight: Radius.circular(6.0),
                                )),
                            child: Column(
                              children: <Widget>[
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const TableEventsExample()));
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.0),
                                    child: Image.asset(
                                      "assets/images/remove_new.ico",
                                      height: 30,
                                      width: 30,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                            width: 10,
                          ),
                          const SizedBox(
                            height: 5,
                            width: 5,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
