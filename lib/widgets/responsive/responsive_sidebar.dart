import 'package:flutter/material.dart';
import 'package:task_manager_flutter/widgets/responsive_widget.dart';

/// Sidebar responsivo mobile-first
/// - Mobile: hidden (drawer/hamburger)
/// - Tablet: collapsible, 200px
/// - Desktop: permanent, 250px
class ResponsiveSidebar extends StatefulWidget {
  final List<Widget> items;
  final Widget? header;
  final Widget? footer;
  final Color? backgroundColor;

  const ResponsiveSidebar({
    required this.items,
    this.header,
    this.footer,
    this.backgroundColor,
    super.key,
  });

  @override
  State<ResponsiveSidebar> createState() => _ResponsiveSidebarState();
}

class _ResponsiveSidebarState extends State<ResponsiveSidebar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      mobileBuilder: (context, width) => _buildMobileSidebar(context, width),
      tabletBuilder: (context, width) =>
          _buildCollapsibleSidebar(context, width, 200),
      desktopBuilder: (context, width) =>
          _buildPermanentSidebar(context, width, 250),
    );
  }

  // Mobile: Hidden by default, accessible via drawer/hamburger
  Widget _buildMobileSidebar(BuildContext context, double width) {
    return SizedBox.shrink();
  }

  // Tablet: Collapsible sidebar
  Widget _buildCollapsibleSidebar(
      BuildContext context, double width, double sidebarWidth) {
    return Row(
      children: [
        if (_isExpanded)
          SizedBox(
            width: sidebarWidth,
            child: _buildSidebarContent(),
          ),
        Expanded(
          child: Column(
            children: [
              if (!_isExpanded)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      setState(() => _isExpanded = true);
                    },
                  ),
                ),
              Expanded(child: Container()),
            ],
          ),
        ),
      ],
    );
  }

  // Desktop: Permanent sidebar
  Widget _buildPermanentSidebar(
      BuildContext context, double width, double sidebarWidth) {
    return Row(
      children: [
        SizedBox(
          width: sidebarWidth,
          child: _buildSidebarContent(),
        ),
        Expanded(child: Container()),
      ],
    );
  }

  // Shared sidebar content
  Widget _buildSidebarContent() {
    return Container(
      color: widget.backgroundColor ?? Colors.grey[200],
      child: Column(
        children: [
          if (widget.header != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: widget.header,
            ),
          Expanded(
            child: ListView(
              children: widget.items,
            ),
          ),
          if (widget.footer != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: widget.footer,
            ),
        ],
      ),
    );
  }
}
