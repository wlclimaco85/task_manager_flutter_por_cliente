import 'package:flutter/material.dart';
import '../../../widgets/home_list_model.dart';
import '../../constants/custom_colors.dart';

class HomeListItem extends StatefulWidget {
  final HomeListModel homeListModel;
  const HomeListItem({super.key, required this.homeListModel});

  @override
  _HomeListItemState createState() => _HomeListItemState();
}

class _HomeListItemState extends State<HomeListItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Column(
        children: [
          Container(
            height: 15,
            decoration: BoxDecoration(
              color: CustomColors().getLightGreenBackground(),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(7),
                bottomRight: Radius.circular(7),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(widget.homeListModel.assetIcon),
                      const Padding(padding: EdgeInsets.only(left: 15)),
                      Text(
                        widget.homeListModel.title,
                        style: TextStyle(
                          color: CustomColors().getLightGreenBackground(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.delete,
                    color: Colors.red,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
