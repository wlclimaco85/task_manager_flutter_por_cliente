// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import '../utils/grid_colors.dart';

class CustomTaskCard extends StatelessWidget {
  final String title;
  final String description;
  final String createdDate;
  final String status;
  final Color chipColor;
  final VoidCallback onChangeStatusPressed;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  const CustomTaskCard({
    super.key,
    required this.title,
    required this.description,
    required this.createdDate,
    required this.status,
    required this.chipColor,
    required this.onChangeStatusPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: GridColors.shadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: GridColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(color: GridColors.textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              createdDate,
              style: const TextStyle(fontSize: 12, color: GridColors.textMuted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text(
                    status,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: chipColor,
                  side: BorderSide.none,
                ),
                const Spacer(),
                IconButton(
                  onPressed: onChangeStatusPressed,
                  icon: Icon(
                    Icons.published_with_changes_outlined,
                    color: GridColors.secondary,
                  ),
                ),
                IconButton(
                  onPressed: onEditPressed,
                  icon: const Icon(
                    Icons.edit,
                    color: GridColors.accent,
                  ),
                ),
                IconButton(
                  onPressed: onDeletePressed,
                  icon: const Icon(
                    Icons.delete,
                    color: GridColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
