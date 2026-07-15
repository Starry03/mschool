import 'package:flutter/material.dart';
import '../../theme/design_system.dart';

class GeneratingSpinner extends StatelessWidget {
  const GeneratingSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: DesignSystem.primary,
              strokeWidth: 5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Solving the scheduling model...',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'OR-Tools is calculating the best timetable that satisfies all constraints.',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
