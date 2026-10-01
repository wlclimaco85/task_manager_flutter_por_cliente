import 'package:flutter/material.dart';

class InputBuscarField extends StatelessWidget {
  const InputBuscarField(
      {super.key,
      required this.hint,
      required this.obscure,
      required this.icon,
      required this.onPresseds
      });

  final String hint;
  final bool obscure;
  final IconData icon;
  final void Function()? onPresseds;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.all(8),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
          color: Color(0xFFFA903A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(6.0),
            topRight: Radius.circular(6.0),
            bottomLeft: Radius.circular(6.0),
            bottomRight: Radius.circular(6.0),
          )),
      child: Row(
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                height: 30,
                width: 280,
                margin: const EdgeInsets.all(8),
                alignment: Alignment.topRight,
                decoration: const BoxDecoration(
                    color: Color(0xFFFA903A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(6.0),
                      topRight: Radius.circular(6.0),
                      bottomLeft: Radius.circular(6.0),
                      bottomRight: Radius.circular(6.0),
                    )),
                child: Flexible(
                  child: TextField(
                    decoration: InputDecoration(
                      suffixIcon: SizedBox(
                        height: 50.0,
                        width: 50.0,
                        child: IconButton(
                          padding: const EdgeInsets.all(0.0),
                          color: const Color(0xFFFA903A),
                          icon: Image.asset('assets/images/Buscar.ico'),
                          onPressed: null,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(10.0),
                      hintText: hint,
                      hintStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 15.0,
                      ),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Column(children: <Widget>[
            Container(
              height: 30,
              width: 20,
              alignment: Alignment.topRight,
              color: const Color(0xFFFA903A),
            ),
          ]),
          Column(children: <Widget>[
            Container(
              height: 30,
              width: 40,
              margin: const EdgeInsets.all(8),
              alignment: Alignment.topRight,
              color: const Color(0xFFFA903A),
              child: SizedBox(
                height: 40.0,
                width: 40.0,
                child: IconButton(
                  padding: const EdgeInsets.all(0.0),
                  color: const Color(0xFFFA903A),
                  tooltip: 'Adicionar Personal',
                  icon: Image.asset('assets/images/adcionarNew.ico'),
                  onPressed: onPresseds,
                ),
              ),
            ),
          ])
        ],
      ),
    );

    /*Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 50.0,
      color: const Color(0xffFA903A),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Padding(
            padding: const EdgeInsets.all(0.0),
            child: Icon(
              Icons.search,
              color: Colors.grey,
            ),
          ),
          Flexible(
            child: TextFormField(
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(10.0),
                hintText: 'Search artist, genre, playlist',
                hintStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 11.0,
                ),
                border: InputBorder.none,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20.0,
              ),
            ),
          ),
        ],
      ),
    ); */
  }
}
