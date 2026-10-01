// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import '../../constants/custom_colors.dart';
import 'package:simple_tags/simple_tags.dart';

class SimpleTag extends StatelessWidget {
  final List<String> content;

  const SimpleTag({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        (SimpleTags(
          content: content,
          wrapSpacing: 4,
          wrapRunSpacing: 4,
          tagContainerPadding: const EdgeInsets.all(6),
          tagTextStyle: const TextStyle(
            color: Color.fromARGB(255, 14, 13, 13),
          ),
          tagContainerDecoration: BoxDecoration(
            color: CustomColors().getLightGreenBackground(),
            border: Border.all(color: CustomColors().getLightGreenBackground()),
            borderRadius: const BorderRadius.all(
              Radius.circular(20),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(139, 139, 142, 0.16),
                spreadRadius: 1,
                blurRadius: 1,
                offset: Offset(1.75, 3.5), // c
              )
            ],
          ), // This trailing comma makes auto-formatting nicer for build methods.
        )), // <-- Wrapped in Flexible.
      ],
    );
  }
}
