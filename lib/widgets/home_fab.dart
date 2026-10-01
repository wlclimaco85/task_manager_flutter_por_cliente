import 'package:flutter/material.dart';

import '../../../widgets/home_modal_add.dart';
import 'home_list_model.dart';

FloatingActionButton getHomeFab(
  BuildContext context,
  List<HomeListModel> listModels,
  Function fncRefresh,
) {
  void configurandoModalBottomSheet2(context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 200,
          child: Center(
              child: ElevatedButton(
            child: const Text('Adicionar Personal'),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const HomeModalAdd())),
          )),
        );
      },
    );
  }

  return FloatingActionButton(
    child: const Text(
      "+",
      style: TextStyle(fontSize: 24),
    ),
    onPressed: () {
      return configurandoModalBottomSheet2(context);
    },
  );
}
