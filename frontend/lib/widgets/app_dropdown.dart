import 'package:flutter/material.dart';
import '../theme/design_system.dart';

class AppDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final void Function(T?) onChanged;
  final String Function(T) itemAsString;
  final double? width;

  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemAsString,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dropdownBgColor = isDark ? DesignSystem.cardDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06);
    final textColor = DesignSystem.getTextColor(context);
    final fieldBgColor = DesignSystem.getFieldColor(context);
    final subtitleColor = DesignSystem.getSubtitleColor(context);

    final dropdown = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: TextStyle(color: subtitleColor, fontSize: 13)),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: fieldBgColor,
            borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              onChanged: onChanged,
              dropdownColor: dropdownBgColor,
              icon: Icon(
                Icons.arrow_drop_down,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              isExpanded: true,
              hint: Text(
                'Select...',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 14,
                ),
              ),
              items: items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemAsString(item),
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );

    if (width != null) {
      return SizedBox(width: width, child: dropdown);
    }
    return dropdown;
  }
}
