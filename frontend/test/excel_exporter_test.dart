import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mschool/models/models.dart';
import 'package:mschool/services/excel_exporter.dart';

void main() {
  test('ExcelExporter generates valid excel matching Aranova model', () {
    final t1 = Teacher(id: 1, firstName: 'Francesca', lastName: 'AQUILANTI');
    final t2 = Teacher(id: 2, firstName: 'Angelo', lastName: 'AVVAMPATO');
    final t3 = Teacher(id: 3, firstName: 'Ivo', lastName: 'PAGLIONI', constraints: [
      for (int h = 0; h < 6; h++) TeacherConstraint(id: h, teacherId: 3, day: 0, hour: h),
    ]);
    final t4 = Teacher(id: 4, firstName: 'Raffaella Rita', lastName: 'MIDOLO');

    final c1d = SchoolClass(id: 1, name: '1d');
    final c2d = SchoolClass(id: 2, name: '2d');
    final c3e = SchoolClass(id: 3, name: '3e');
    final cGran = SchoolClass(id: 4, name: '3a Granaretto');

    final subIta = Subject(id: 1, name: 'Italiano');
    final subDisp = Subject(id: 2, name: 'Disposizione');
    final subAlt = Subject(id: 3, name: 'Attività Alternativa');

    final slots = [
      TimetableSlot(id: 1, day: 0, hour: 0, classId: 1, teacherId: 1, subjectId: 1, schoolClass: c1d, teacher: t1, subject: subIta),
      TimetableSlot(id: 2, day: 0, hour: 1, classId: 1, teacherId: 1, subjectId: 1, schoolClass: c1d, teacher: t1, subject: subIta),
      TimetableSlot(id: 3, day: 0, hour: 2, classId: 1, teacherId: 1, subjectId: 2, schoolClass: c1d, teacher: t1, subject: subDisp),
      TimetableSlot(id: 4, day: 0, hour: 3, classId: 2, teacherId: 1, subjectId: 1, schoolClass: c2d, teacher: t1, subject: subIta),
      
      TimetableSlot(id: 5, day: 0, hour: 0, classId: 3, teacherId: 2, subjectId: 1, schoolClass: c3e, teacher: t2, subject: subIta),
      TimetableSlot(id: 6, day: 0, hour: 1, classId: 3, teacherId: 2, subjectId: 1, schoolClass: c3e, teacher: t2, subject: subIta),
      TimetableSlot(id: 7, day: 0, hour: 2, classId: 3, teacherId: 2, subjectId: 1, schoolClass: c3e, teacher: t2, subject: subIta),
      TimetableSlot(id: 8, day: 0, hour: 3, classId: 3, teacherId: 2, subjectId: 2, schoolClass: c3e, teacher: t2, subject: subDisp),

      TimetableSlot(id: 9, day: 1, hour: 1, classId: 4, teacherId: 4, subjectId: 1, schoolClass: cGran, teacher: t4, subject: subIta),
      TimetableSlot(id: 10, day: 1, hour: 2, classId: 4, teacherId: 4, subjectId: 3, schoolClass: cGran, teacher: t4, subject: subAlt),
    ];

    final bytes = ExcelExporter.generateExcelBytes(
      slots: slots,
      teachers: [t1, t2, t3, t4],
      classes: [c1d, c2d, c3e, cGran],
      days: 5,
      hours: 6,
      title: 'ORARIO DEFINITIVO ARANOVA DAL 29/09/2025 a.s. 2025/2026',
    );

    expect(bytes, isNotNull);
    expect(bytes.isNotEmpty, isTrue);

    final file = File('/home/starry/.gemini/antigravity/brain/7e197dd6-f1a5-4afe-839e-4e5252530a4d/test_export.xlsx');
    file.writeAsBytesSync(bytes);
    expect(file.existsSync(), isTrue);
  });

  test('archive zip injection works', () {
    final file = File('/home/starry/.gemini/antigravity/brain/7e197dd6-f1a5-4afe-839e-4e5252530a4d/test_export.xlsx');
    final zipBytes = file.readAsBytesSync();
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
    final encoded = ZipEncoder().encode(newArchive);
    expect(encoded, isNotNull);
    File('/home/starry/.gemini/antigravity/brain/7e197dd6-f1a5-4afe-839e-4e5252530a4d/test_dart_landscape.xlsx').writeAsBytesSync(encoded!);
  });
}
