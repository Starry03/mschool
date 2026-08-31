import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/design_system.dart';

class TimetableGrid extends StatelessWidget {
  final List<TimetableSlot> slots;
  final int days;
  final int hours;
  final String filterType;
  final List<String> giorniNomi;

  const TimetableGrid({
    super.key,
    required this.slots,
    required this.days,
    required this.hours,
    required this.filterType,
    required this.giorniNomi,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = DesignSystem.getTextColor(context);
    final subtitleColor = DesignSystem.getSubtitleColor(context);
    final mutedColor = DesignSystem.getMutedColor(context);
    final tableHeaderBg = isDark
        ? const Color(0xFF2E334D).withValues(alpha: 0.2)
        : const Color(0xFFF1F5F9);

    final slotMap = <int, TimetableSlot>{
      for (final s in slots) (s.day * 100 + s.hour): s,
    };

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double minWidth = 100.0 + (days * 120.0);
          final double widthToUse = constraints.maxWidth > minWidth
              ? constraints.maxWidth
              : minWidth;
          final bool needsScroll = constraints.maxWidth < minWidth;

          Widget tableWidget = SizedBox(
            width: widthToUse,
            child: Table(
              border: TableBorder.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                width: 0.5,
              ),
              columnWidths: const {0: FixedColumnWidth(80)},
              children: [
                TableRow(
                  decoration: BoxDecoration(color: tableHeaderBg),
                  children: [
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(),
                      ),
                    ),
                    ...List.generate(
                      days,
                      (d) => TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            giorniNomi[d],
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                ...List.generate(hours, (h) {
                  return TableRow(
                    children: [
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 24.0,
                            ),
                            child: Text(
                              '${h + 1}',
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      ...List.generate(days, (d) {
                        final slot = slotMap[d * 100 + h];
                        final isAssigned = slot != null && slot.id != -1;
                        final cellBgColor = isAssigned
                            ? DesignSystem.primary.withValues(alpha: 0.08)
                            : Colors.transparent;
                        final cellBorderColor = isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.04);

                        return TableCell(
                          child: Container(
                            height: 80,
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: cellBgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isAssigned
                                  ? DesignSystem.primary.withValues(alpha: 0.8)
                                  : cellBorderColor,
                              width: isAssigned ? 1.5 : 1,
                            ),
                            boxShadow: isAssigned
                                ? [
                                    BoxShadow(
                                      color: DesignSystem.primary.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                    )
                                  ]
                                : null,
                          ),
                          child: isAssigned
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      slot.subject.name,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      filterType == 'class'
                                          ? slot.teacher.fullName
                                          : 'Class ${slot.schoolClass.name}',
                                      style: TextStyle(
                                        color: subtitleColor,
                                        fontSize: 11,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                )
                              : Center(
                                  child: Text(
                                    '',
                                    style: TextStyle(
                                      color: mutedColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        );

        if (needsScroll) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: tableWidget,
          );
        } else {
          return tableWidget;
        }
      },
    ),);
  }
}
