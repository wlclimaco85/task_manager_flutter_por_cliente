import 'package:flutter/material.dart';
import '../utils/grid_colors.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPresse;
  final String labels;

  const CustomButton({
    super.key,
    required this.onPresse,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    /* return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPresse,
        child: const Icon(Icons.arrow_circle_right_outlined),
      ),
    );*/
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: GridColors.primary,
        foregroundColor: GridColors.textPrimary,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {
        onPresse();
      },
      child: Text(
        labels,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );

    /*return Container(
      IconButton(
        icon: Icon(Icons.volume_up),
        iconSize: 50,
        color: Colors.brown,
        tooltip: 'Increase volume by 5',
        onPressed: () {  };
        },
        
      ),
      Text('Speaker Volume: $_speakervolume')
    )*/
  }
}
