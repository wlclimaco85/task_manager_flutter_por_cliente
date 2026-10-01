import '../../../widgets/input_field.dart';
import 'package:flutter/material.dart';

class FormContainer extends StatelessWidget {
  const FormContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: const Form(
          child: Column(
        children: [
          InputField(
              hint: "Username", obscure: false, icon: Icons.person_outline),
          InputField(hint: "Password", obscure: true, icon: Icons.lock_outline),
        ],
      )),
    );
  }
}
