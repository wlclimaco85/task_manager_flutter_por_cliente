import 'package:flutter/material.dart';
import 'package:task_manager_flutter/widgets/responsive_widget.dart';

/// Button bar responsivo mobile-first
/// - Mobile: buttons stackados verticalmente, full width
/// - Tablet: buttons horizontais, medium width
/// - Desktop: buttons inline, compact
class ResponsiveButtonBar extends StatelessWidget {
  final List<Widget> buttons;
  final MainAxisAlignment alignment;
  final double? spacing;

  const ResponsiveButtonBar({
    required this.buttons,
    this.alignment = MainAxisAlignment.center,
    this.spacing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      mobileBuilder: (context, width) => _buildMobileButtonBar(width),
      tabletBuilder: (context, width) => _buildTabletButtonBar(width),
      desktopBuilder: (context, width) => _buildDesktopButtonBar(width),
    );
  }

  Widget _buildMobileButtonBar(double width) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: alignment,
        children: buttons
            .asMap()
            .entries
            .map(
              (e) => Padding(
                padding: EdgeInsets.only(
                  bottom: e.key < buttons.length - 1 ? (spacing ?? 8.0) : 0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: e.value,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTabletButtonBar(double width) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: alignment,
          children: buttons
              .asMap()
              .entries
              .map(
                (e) => Padding(
                  padding: EdgeInsets.only(
                    right: e.key < buttons.length - 1 ? (spacing ?? 12.0) : 0,
                  ),
                  child: e.value,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDesktopButtonBar(double width) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: alignment,
          children: buttons
              .asMap()
              .entries
              .map(
                (e) => Padding(
                  padding: EdgeInsets.only(
                    right: e.key < buttons.length - 1 ? (spacing ?? 16.0) : 0,
                  ),
                  child: e.value,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
