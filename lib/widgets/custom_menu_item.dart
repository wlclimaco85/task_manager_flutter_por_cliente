import 'package:flutter/material.dart';

/// Flutter code sample for [IconButton].

/*void main() => runApp(const IconButtonExampleApp());

class IconButtonExampleApp extends StatelessWidget {
  const IconButtonExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('IconButton Sample')),
        body: const Center(
          child: IconButtonExample(),
        ),
      ),
    );
  }
} 

double _volume = 0.0;*/

class IconButtonExample extends StatelessWidget {
  const IconButtonExample({
    super.key,
    required this.text,
    required this.color,
    required this.onPresse,
  });

  final String text;
  final String color;
  final Function onPresse;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onPresse();
      },
      child: Container(
        /* width: 50.0,
        padding: new EdgeInsets.fromLTRB(20.0, 40.0, 20.0, 40.0),
        color: Colors.green,*/
        child: Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: Card(
              elevation: 6,
              color: const Color(0xFF340A9C),
              semanticContainer: true,
              // Implement InkResponse
              child: InkResponse(
                containedInkWell: true,
                highlightShape: BoxShape.rectangle,
                // Add image & text
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.asset(
                        "assets/images/$color",
                        height: 60,
                        width: 65,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      height: 40,
                      width: 150,
                      color: Colors.transparent,
                      child: Container(
                          alignment: Alignment.center,
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
                              Text(
                                text,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )),
                    ),
                    const SizedBox(height: 10)
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  /*Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Ink(
          decoration: const ShapeDecoration(
            color: Colors.lightBlue,
            shape: CircleBorder(),
          ),
          child: IconButton(
            icon: const Icon(Icons.android),
            color: Colors.white,
            onPressed: () {},
          ),
        ),
      ),
    );
  }
  
  Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          icon: new Image.asset('assets/images/carrinho.png'),
          tooltip: 'Increase volume by 10',
          onPressed: () {
            setState(() {
              _volume += 10;
            });
          },
        ),
        Text('Volumes : $_volume'),
      ],
    );
  
  */
}
