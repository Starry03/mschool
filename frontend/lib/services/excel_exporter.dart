import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'file_saver/file_saver.dart';
import '../models/models.dart';

class ExcelExporter {
  static const List<String> _dayNames = [
    'LUNEDÌ',
    'MARTEDÌ',
    'MERCOLEDÌ',
    'GIOVEDÌ',
    'VENERDÌ',
    'SABATO',
    'DOMENICA',
  ];

  static Future<void> exportTimetable({
    required List<TimetableSlot> slots,
    required List<Teacher> teachers,
    required List<SchoolClass> classes,
    required int days,
    required int hours,
    String title = 'ORARIO DEFINITIVO ARANOVA a.s. 2025/2026',
  }) async {
    final Uint8List bytes = generateExcelBytes(
      slots: slots,
      teachers: teachers,
      classes: classes,
      days: days,
      hours: hours,
      title: title,
    );

    await FileSaver.saveFile(
      bytes: bytes,
      fileName: 'orario_scolastico.xlsx',
      dialogTitle: 'Save Timetable Excel',
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  static Uint8List generateExcelBytes({
    required List<TimetableSlot> slots,
    required List<Teacher> teachers,
    required List<SchoolClass> classes,
    required int days,
    required int hours,
    String title = 'ORARIO DEFINITIVO ARANOVA a.s. 2025/2026',
  }) {
    final excel = Excel.createExcel();

    // 1. Sheet: Orario Docenti
    const String teacherSheetName = 'Orario Docenti';
    final Sheet teacherSheet = excel[teacherSheetName];
    excel.setDefaultSheet(teacherSheetName);
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    _buildTeacherSheet(
      sheet: teacherSheet,
      slots: slots,
      teachers: teachers,
      days: days,
      hours: hours,
      title: title,
    );

    // 2. Sheet: Orario Classi
    const String classSheetName = 'Orario Classi';
    final Sheet classSheet = excel[classSheetName];

    _buildClassSheet(
      sheet: classSheet,
      slots: slots,
      classes: classes,
      days: days,
      hours: hours,
      title: title.replaceAll('DOCENTI', 'CLASSI').replaceAll('ARANOVA', 'ARANOVA - CLASSI'),
    );

    final List<int>? encoded = excel.encode();
    if (encoded == null) {
      throw Exception('Unable to encode Excel file.');
    }
    return _injectPageSetup(Uint8List.fromList(encoded));
  }

  static Uint8List _injectPageSetup(Uint8List zipBytes) {
    try {
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final newArchive = Archive();
      for (final f in archive) {
        if (f.name.startsWith('xl/worksheets/sheet') && f.name.endsWith('.xml')) {
          final content = utf8.decode(f.content as List<int>);
          final updated = content.replaceFirst(
            '</worksheet>',
            '<pageSetup orientation="landscape" paperSize="9" fitToWidth="1" fitToHeight="0"/></worksheet>',
          );
          final bytes = utf8.encode(updated);
          newArchive.addFile(ArchiveFile(f.name, bytes.length, bytes));
        } else {
          newArchive.addFile(f);
        }
      }
      final result = ZipEncoder().encode(newArchive);
      if (result != null) {
        return Uint8List.fromList(result);
      }
    } catch (_) {}
    return zipBytes;
  }

  static String _formatTeacherName(Teacher t) {
    if (t.lastName != null && t.lastName!.isNotEmpty) {
      return '${t.lastName!.toUpperCase()} ${t.firstName}';
    }
    return t.firstName;
  }

  static String _cleanClassName(String name) {
    var s = name.trim();
    if (s.contains(' ')) {
      s = s.split(' ').first;
    }
    return s;
  }

  static void _buildTeacherSheet({
    required Sheet sheet,
    required List<TimetableSlot> slots,
    required List<Teacher> teachers,
    required int days,
    required int hours,
    required String title,
  }) {
    final sortedTeachers = List<Teacher>.from(teachers)
      ..sort((a, b) {
        final aLast = a.lastName ?? '';
        final bLast = b.lastName ?? '';
        final cmp = aLast.compareTo(bLast);
        if (cmp != 0) return cmp;
        return a.firstName.compareTo(b.firstName);
      });

    final totalCols = 1 + (days * hours);

    final mediumBorder = Border(
      borderStyle: BorderStyle.Medium,
      borderColorHex: ExcelColor.black,
    );
    final thinBorder = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString('FF9CA3AF'),
    );

    // Column Widths
    sheet.setColumnWidth(0, 30.0);
    for (int c = 1; c < totalCols; c++) {
      sheet.setColumnWidth(c, 5.5);
    }

    // Row 0: Title Banner
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: totalCols - 1, rowIndex: 0),
      customValue: TextCellValue(title),
    );
    sheet.setRowHeight(0, 28.0);
    for (int c = 0; c < totalCols; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('FFF3F4F6'),
        topBorder: mediumBorder,
        bottomBorder: mediumBorder,
        leftBorder: c == 0 ? mediumBorder : null,
        rightBorder: c == totalCols - 1 ? mediumBorder : null,
      );
    }

    // Row 1: Day Headers
    sheet.setRowHeight(1, 24.0);
    final docCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    docCell.value = TextCellValue('DOCENTE');
    docCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('FFF9FAFB'),
      topBorder: mediumBorder,
      bottomBorder: mediumBorder,
      leftBorder: mediumBorder,
      rightBorder: mediumBorder,
    );

    for (int d = 0; d < days; d++) {
      final startCol = 1 + (d * hours);
      final endCol = startCol + hours - 1;
      final dayLabel = d < _dayNames.length ? _dayNames[d] : 'GIORNO ${d + 1}';

      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: startCol, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: endCol, rowIndex: 1),
        customValue: TextCellValue(dayLabel),
      );

      for (int c = startCol; c <= endCol; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1));
        cell.cellStyle = CellStyle(
          bold: true,
          fontSize: 10,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
          backgroundColorHex: ExcelColor.fromHexString('FFF9FAFB'),
          topBorder: mediumBorder,
          bottomBorder: mediumBorder,
          leftBorder: c == startCol ? mediumBorder : thinBorder,
          rightBorder: c == endCol ? mediumBorder : thinBorder,
        );
      }
    }

    // Teacher rows: Rows 2 to 2 + sortedTeachers.length - 1
    for (int tIdx = 0; tIdx < sortedTeachers.length; tIdx++) {
      final teacher = sortedTeachers[tIdx];
      final row = 2 + tIdx;
      final isLastTeacher = (tIdx == sortedTeachers.length - 1);
      sheet.setRowHeight(row, 20.0);

      final teacherCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      teacherCell.value = TextCellValue(_formatTeacherName(teacher));
      teacherCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 9,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        topBorder: thinBorder,
        bottomBorder: isLastTeacher ? mediumBorder : thinBorder,
        leftBorder: mediumBorder,
        rightBorder: mediumBorder,
      );

      for (int d = 0; d < days; d++) {
        for (int h = 0; h < hours; h++) {
          final col = 1 + (d * hours) + h;
          final isDayStart = (h == 0);
          final isDayEnd = (h == hours - 1);

          final slot = slots.firstWhere(
            (s) => s.teacherId == teacher.id && s.day == d && s.hour == h,
            orElse: () => TimetableSlot(
              id: -1,
              day: d,
              hour: h,
              classId: -1,
              teacherId: -1,
              subjectId: -1,
              schoolClass: SchoolClass(id: -1, name: ''),
              teacher: Teacher(id: -1, firstName: ''),
              subject: Subject(id: -1, name: ''),
            ),
          );

          final isUnavailable = teacher.constraints.any((c) => c.day == d && c.hour == h);

          String cellText = '';
          ExcelColor bgColor = ExcelColor.none;
          ExcelColor fontColor = ExcelColor.black;

          if (slot.id != -1) {
            final subjectLower = slot.subject.name.toLowerCase();
            final classLower = slot.schoolClass.name.toLowerCase();
            final cleanClass = _cleanClassName(slot.schoolClass.name);

            if (subjectLower.contains('disposiz') || subjectLower == 'disp' || subjectLower == 'd') {
              cellText = 'd';
              bgColor = ExcelColor.fromHexString('FFFCA5A5'); // Light red
              fontColor = ExcelColor.fromHexString('FF991B1B');
            } else if (subjectLower.contains('alternativ')) {
              cellText = cleanClass.isNotEmpty ? cleanClass : 'Alt';
              bgColor = ExcelColor.fromHexString('FFE879F9'); // Light purple
              fontColor = ExcelColor.fromHexString('FF701A75');
            } else if (classLower.contains('granaretto') || subjectLower.contains('granaretto')) {
              cellText = cleanClass;
              bgColor = ExcelColor.fromHexString('FFFDE047'); // Yellow
              fontColor = ExcelColor.black;
            } else {
              cellText = cleanClass;
              bgColor = ExcelColor.none;
              fontColor = ExcelColor.black;
            }
          } else if (isUnavailable) {
            // Orario in altre scuole o giorno libero
            cellText = '';
            bgColor = ExcelColor.fromHexString('FF38BDF8'); // Sky blue
          }

          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
          cell.value = TextCellValue(cellText);
          cell.cellStyle = CellStyle(
            bold: cellText.isNotEmpty,
            fontSize: 9,
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
            backgroundColorHex: bgColor,
            fontColorHex: fontColor,
            leftBorder: isDayStart ? mediumBorder : thinBorder,
            rightBorder: isDayEnd ? mediumBorder : thinBorder,
            topBorder: thinBorder,
            bottomBorder: isLastTeacher ? mediumBorder : thinBorder,
          );
        }
      }
    }

    // Legend at bottom
    final legendRow = 2 + sortedTeachers.length + 1;
    sheet.setRowHeight(legendRow, 22.0);

    void setLegendItem(int boxCol, int startTextCol, int endTextCol, ExcelColor color, String text) {
      final boxCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: boxCol, rowIndex: legendRow));
      boxCell.value = TextCellValue('');
      boxCell.cellStyle = CellStyle(
        backgroundColorHex: color,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      if (endTextCol > startTextCol) {
        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: startTextCol, rowIndex: legendRow),
          CellIndex.indexByColumnRow(columnIndex: endTextCol, rowIndex: legendRow),
          customValue: TextCellValue(text),
        );
      }
      for (int c = startTextCol; c <= endTextCol; c++) {
        final textCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: legendRow));
        textCell.cellStyle = CellStyle(
          bold: true,
          fontSize: 9,
          horizontalAlign: HorizontalAlign.Left,
          verticalAlign: VerticalAlign.Center,
        );
      }
    }

    // 1. Attività alternativa (Purple)
    if (totalCols > 5) {
      setLegendItem(1, 2, 5, ExcelColor.fromHexString('FFE879F9'), 'Attività alternativa');
    }
    // 2. Orario in altre scuole o giorno libero (Blue)
    if (totalCols > 14) {
      setLegendItem(7, 8, 14, ExcelColor.fromHexString('FF38BDF8'), 'Orario in altre scuole o giorno libero');
    }
    // 3. Orario a Granaretto (Yellow)
    if (totalCols > 21) {
      setLegendItem(16, 17, 21, ExcelColor.fromHexString('FFFDE047'), 'Orario a Granaretto');
    }
    // 4. Disposizione (Red)
    if (totalCols > 27) {
      setLegendItem(23, 24, 28, ExcelColor.fromHexString('FFFCA5A5'), 'Disposizione');
    }
  }

  static void _buildClassSheet({
    required Sheet sheet,
    required List<TimetableSlot> slots,
    required List<SchoolClass> classes,
    required int days,
    required int hours,
    required String title,
  }) {
    final sortedClasses = List<SchoolClass>.from(classes)
      ..sort((a, b) => a.name.compareTo(b.name));

    final totalCols = 1 + (days * hours);

    final mediumBorder = Border(
      borderStyle: BorderStyle.Medium,
      borderColorHex: ExcelColor.black,
    );
    final thinBorder = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString('FF9CA3AF'),
    );

    // Column Widths
    sheet.setColumnWidth(0, 16.0);
    for (int c = 1; c < totalCols; c++) {
      sheet.setColumnWidth(c, 14.0);
    }

    // Row 0: Title Banner
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: totalCols - 1, rowIndex: 0),
      customValue: TextCellValue(title),
    );
    sheet.setRowHeight(0, 28.0);
    for (int c = 0; c < totalCols; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('FFF3F4F6'),
        topBorder: mediumBorder,
        bottomBorder: mediumBorder,
        leftBorder: c == 0 ? mediumBorder : null,
        rightBorder: c == totalCols - 1 ? mediumBorder : null,
      );
    }

    // Row 1: Day Headers
    sheet.setRowHeight(1, 24.0);
    final classHeaderCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    classHeaderCell.value = TextCellValue('CLASSE');
    classHeaderCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('FFF9FAFB'),
      topBorder: mediumBorder,
      bottomBorder: mediumBorder,
      leftBorder: mediumBorder,
      rightBorder: mediumBorder,
    );

    for (int d = 0; d < days; d++) {
      final startCol = 1 + (d * hours);
      final endCol = startCol + hours - 1;
      final dayLabel = d < _dayNames.length ? _dayNames[d] : 'GIORNO ${d + 1}';

      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: startCol, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: endCol, rowIndex: 1),
        customValue: TextCellValue(dayLabel),
      );

      for (int c = startCol; c <= endCol; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1));
        cell.cellStyle = CellStyle(
          bold: true,
          fontSize: 10,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
          backgroundColorHex: ExcelColor.fromHexString('FFF9FAFB'),
          topBorder: mediumBorder,
          bottomBorder: mediumBorder,
          leftBorder: c == startCol ? mediumBorder : thinBorder,
          rightBorder: c == endCol ? mediumBorder : thinBorder,
        );
      }
    }

    // Class rows
    for (int cIdx = 0; cIdx < sortedClasses.length; cIdx++) {
      final schoolClass = sortedClasses[cIdx];
      final row = 2 + cIdx;
      final isLastClass = (cIdx == sortedClasses.length - 1);
      sheet.setRowHeight(row, 20.0);

      final classCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      classCell.value = TextCellValue(schoolClass.name);
      classCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        topBorder: thinBorder,
        bottomBorder: isLastClass ? mediumBorder : thinBorder,
        leftBorder: mediumBorder,
        rightBorder: mediumBorder,
      );

      for (int d = 0; d < days; d++) {
        for (int h = 0; h < hours; h++) {
          final col = 1 + (d * hours) + h;
          final isDayStart = (h == 0);
          final isDayEnd = (h == hours - 1);

          final slot = slots.firstWhere(
            (s) => s.classId == schoolClass.id && s.day == d && s.hour == h,
            orElse: () => TimetableSlot(
              id: -1,
              day: d,
              hour: h,
              classId: -1,
              teacherId: -1,
              subjectId: -1,
              schoolClass: SchoolClass(id: -1, name: ''),
              teacher: Teacher(id: -1, firstName: ''),
              subject: Subject(id: -1, name: ''),
            ),
          );

          String text = '';
          if (slot.id != -1) {
            final teacherName = slot.teacher.lastName ?? slot.teacher.firstName;
            text = '${slot.subject.name} ($teacherName)';
          }

          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
          cell.value = TextCellValue(text);
          cell.cellStyle = CellStyle(
            fontSize: 9,
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
            leftBorder: isDayStart ? mediumBorder : thinBorder,
            rightBorder: isDayEnd ? mediumBorder : thinBorder,
            topBorder: thinBorder,
            bottomBorder: isLastClass ? mediumBorder : thinBorder,
          );
        }
      }
    }
  }
}
