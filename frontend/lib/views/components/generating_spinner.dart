import 'package:flutter/material.dart';
import '../../theme/design_system.dart';

class GeneratingSpinner extends StatelessWidget {
  const GeneratingSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const RepaintBoundary(
              child: SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: DesignSystem.primary,
                  strokeWidth: 4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Solving the scheduling model',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'OR-Tools is calculating the best timetable that satisfies all constraints',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
