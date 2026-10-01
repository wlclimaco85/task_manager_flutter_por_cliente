import 'package:flutter/material.dart';
import '../../constants/custom_colors.dart';

Drawer getHomeDrawer() {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        const UserAccountsDrawerHeader(
          decoration: BoxDecoration(color: Color(0xff0A6D92)),
          accountName: Text("Ricarth Lima"),
          accountEmail: Text("rrsl@cin.ufpe.br"),
          currentAccountPicture: CircleAvatar(
            backgroundColor: Colors.white,
            child: Text(
              "RL",
              style: TextStyle(fontSize: 40),
            ),
          ),
        ),
        ListTile(
          leading: Icon(
            Icons.settings,
            color: CustomColors().getLightGreenBackground(),
          ),
          title: const Text(
            "Configurações",
          ),
        ),
        ListTile(
          leading: Icon(
            Icons.arrow_back_sharp,
            color: CustomColors().getLightGreenBackground(),
          ),
          title: const Text(
            "Sair",
          ),
        )
      ],
    ),
  );
}
