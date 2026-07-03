import 'package:flutter/material.dart';
import 'desktop/table_analyzer_desktop_layout.dart';
import 'mobile/table_analyzer_mobile_layout.dart';

/// Base responsive screen widget evaluating constraints at the 600dp breakpoint.
/// Seamlessly toggles between Mobile and Desktop layouts while preserving shared Riverpod state.
class TableAnalyzerScreen extends StatelessWidget {
  const TableAnalyzerScreen({super.key});

  static const double desktopBreakpoint = 600.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= desktopBreakpoint) {
          return const TableAnalyzerDesktopLayout();
        } else {
          return const TableAnalyzerMobileLayout();
        }
      },
    );
  }
}
