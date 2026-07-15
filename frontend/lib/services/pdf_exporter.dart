import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';

class PdfExporter {
  static String _getSlotClass(
    List<TimetableSlot> slots,
    int teacherId,
    int d,
    int h,
  ) {
    final slot = slots.firstWhere(
      (s) => s.teacherId == teacherId && s.day == d && s.hour == h,
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
    return slot.id != -1 ? slot.schoolClass.name : '';
  }

  static Future<void> exportTimetable({
    required List<TimetableSlot> slots,
    required List<Teacher> teachers,
    required int days,
    required int hours,
  }) async {
    final fontData = await rootBundle.load('assets/fonts/Outfit.ttf');
    final myFont = pw.Font.ttf(fontData);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: myFont, bold: myFont),
    );
    final dayList = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    // Sort teachers by name
    final sortedTeachers = List<Teacher>.from(teachers)
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    // Width layout calculations (A4 Landscape usable width: ~793.89)
    const double teacherWidth = 100.0;
    final double totalWidth = PdfPageFormat.a4.landscape.width - 48;
    final double remainingWidth = totalWidth - teacherWidth;
    final int totalCols = days * hours;
    final double colWidth = remainingWidth / totalCols;

    // Day headers row (rendered above the main Table)
    final dayHeaderRow = pw.Row(
      children: [
        pw.Container(
          width: teacherWidth,
          height: 24,
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey200,
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          alignment: pw.Alignment.centerLeft,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6),
          child: pw.Text(
            'Teacher',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
          ),
        ),
        for (int d = 0; d < days; d++)
          pw.Container(
            width: colWidth * hours,
            height: 24,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#6366F1'),
              border: pw.Border(
                top: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                left: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                right: d == days - 1
                    ? const pw.BorderSide(color: PdfColors.grey300, width: 0.5)
                    : pw.BorderSide.none,
                bottom: const pw.BorderSide(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
              ),
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              d < dayList.length ? dayList[d] : 'Day ${d + 1}',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
                color: PdfColors.white,
              ),
            ),
          ),
      ],
    );

    // Main Table containing Hours header and Data rows
    final mainTable = pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(teacherWidth),
        for (int i = 1; i <= totalCols; i++) i: pw.FixedColumnWidth(colWidth),
      },
      children: [
        // Hours header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'Hours',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 7,
                  color: PdfColors.grey700,
                ),
              ),
            ),
            for (int d = 0; d < days; d++)
              for (int h = 0; h < hours; h++)
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Text(
                    '${h + 1}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 7,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
          ],
        ),

        // Data rows
        for (final teacher in sortedTeachers)
          pw.TableRow(
            children: [
              pw.Container(
                alignment: pw.Alignment.centerLeft,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                child: pw.Text(
                  teacher.fullName,
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
              for (int d = 0; d < days; d++)
                for (int h = 0; h < hours; h++)
                  pw.Container(
                    alignment: pw.Alignment.center,
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text(
                      _getSlotClass(slots, teacher.id, d, h),
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                  ),
            ],
          ),
      ],
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
          ),
        ),
        build: (context) {
          return [
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Export Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            dayHeaderRow,
            mainTable,
          ];
        },
      ),
    );

    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'timetable_teachers.pdf',
      );
    } else {
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Timetable PDF',
        fileName: 'timetable_teachers.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(pdfBytes);
      }
    }
  }
}
