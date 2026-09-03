import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'file_saver/file_saver.dart';
import '../models/models.dart';

class ExcelExporter {
  static const List<String> _dayNames = [
    'Lunedì',
    'Martedì',
    'Mercoledì',
    'Giovedì',
    'Venerdì',
    'Sabato',
    'Domenica'
  ];

  static Future<void> exportTimetable({
    required List<TimetableSlot> slots,
    required List<Teacher> teachers,
    required List<SchoolClass> classes,
    required int days,
    required int hours,
  }) async {
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
    );

    final List<int>? encoded = excel.encode();
    if (encoded == null) {
      throw Exception('Impossibile codificare il file Excel.');
    }
    final Uint8List bytes = Uint8List.fromList(encoded);

    await FileSaver.saveFile(
      bytes: bytes,
      fileName: 'orario_scolastico.xlsx',
      dialogTitle: 'Salva Orario Excel',
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  static void _buildTeacherSheet({
    required Sheet sheet,
    required List<TimetableSlot> slots,
    required List<Teacher> teachers,
    required int days,
    required int hours,
  }) {
    // Header Row 0: Day names spanning hours
    // Header Row 1: Hour numbers (Ora 1, Ora 2...)
    final sortedTeachers = List<Teacher>.from(teachers)
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    // Cell A1 & A2: Docente
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('Docente');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value =
        TextCellValue('');

    for (int d = 0; d < days; d++) {
      final dayLabel = d < _dayNames.length ? _dayNames[d] : 'Giorno ${d + 1}';
      for (int h = 0; h < hours; h++) {
        final col = 1 + (d * hours) + h;
        if (h == 0) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).value =
              TextCellValue(dayLabel);
        }
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 1)).value =
            TextCellValue('Ora ${h + 1}');
      }
    }

    // Teacher rows
    for (int tIdx = 0; tIdx < sortedTeachers.length; tIdx++) {
      final teacher = sortedTeachers[tIdx];
      final row = 2 + tIdx;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue(teacher.fullName);

      for (int d = 0; d < days; d++) {
        for (int h = 0; h < hours; h++) {
          final col = 1 + (d * hours) + h;
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

          if (slot.id != -1) {
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value =
                TextCellValue('${slot.schoolClass.name} (${slot.subject.name})');
          } else {
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value =
                TextCellValue('-');
          }
        }
      }
    }
  }

  static void _buildClassSheet({
    required Sheet sheet,
    required List<TimetableSlot> slots,
    required List<SchoolClass> classes,
    required int days,
    required int hours,
  }) {
    final sortedClasses = List<SchoolClass>.from(classes)
      ..sort((a, b) => a.name.compareTo(b.name));

    // Cell A1 & A2: Classe
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('Classe');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value =
        TextCellValue('');

    for (int d = 0; d < days; d++) {
      final dayLabel = d < _dayNames.length ? _dayNames[d] : 'Giorno ${d + 1}';
      for (int h = 0; h < hours; h++) {
        final col = 1 + (d * hours) + h;
        if (h == 0) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).value =
              TextCellValue(dayLabel);
        }
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 1)).value =
            TextCellValue('Ora ${h + 1}');
      }
    }

    // Class rows
    for (int cIdx = 0; cIdx < sortedClasses.length; cIdx++) {
      final schoolClass = sortedClasses[cIdx];
      final row = 2 + cIdx;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue(schoolClass.name);

      for (int d = 0; d < days; d++) {
        for (int h = 0; h < hours; h++) {
          final col = 1 + (d * hours) + h;
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

          if (slot.id != -1) {
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value =
                TextCellValue('${slot.subject.name} (${slot.teacher.fullName})');
          } else {
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value =
                TextCellValue('-');
          }
        }
      }
    }
  }
}
