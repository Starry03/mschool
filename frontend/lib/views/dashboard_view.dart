import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/pdf_exporter.dart';
import '../services/excel_exporter.dart';
import '../theme/design_system.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import 'components/generating_spinner.dart';
import 'components/timetable_grid.dart';

class DashboardView extends StatefulWidget {
  final SchoolSettings schoolSettings;
  const DashboardView({super.key, required this.schoolSettings});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  List<TimetableSlot> _slots = [];
  List<SchoolClass> _classes = [];
  List<Teacher> _teachers = [];

  bool _isLoading = false;
  bool _isGenerating = false;

  // Filtering
  String _filterType = 'class'; // 'class' or 'teacher'
  int? _selectedFilterId;

  // Error / Diagnostics after generation
  String? _genErrorTitle;
  String? _genErrorDetails;

  @override
  void initState() {
    super.initState();
    _loadFilterData();
  }

  Future<void> _loadFilterData() async {
    setState(() => _isLoading = true);
    try {
      final classes = await ApiService.getClasses();
      final teachers = await ApiService.getTeachers();

      setState(() {
        _classes = classes;
        _teachers = teachers;

        if (_filterType == 'class' && classes.isNotEmpty) {
          _selectedFilterId = classes.first.id;
        } else if (_filterType == 'teacher' && teachers.isNotEmpty) {
          _selectedFilterId = teachers.first.id;
        }
      });

      await _loadTimetable();
    } catch (e) {
      _showError('Unable to load filter data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTimetable() async {
    if (_selectedFilterId == null) {
      setState(() => _slots = []);
      return;
    }

    try {
      List<TimetableSlot> list;
      if (_filterType == 'class') {
        list = await ApiService.getTimetableByClass(_selectedFilterId!);
      } else {
        list = await ApiService.getTimetableByTeacher(_selectedFilterId!);
      }
      setState(() => _slots = list);
    } catch (e) {
      _showError('Unable to load timetable: $e');
    }
  }

  Future<void> _generateTimetable() async {
    setState(() {
      _isGenerating = true;
      _genErrorTitle = null;
      _genErrorDetails = null;
    });

    try {
      final response = await ApiService.generateTimetable(maxTimeSeconds: 15.0);
      if (response.success) {
        _showSuccess('Timetable generated successfully!');
        _loadTimetable();
      } else {
        setState(() {
          _genErrorTitle = response.message;
          _genErrorDetails = response.errorDetails;
        });
      }
    } catch (e) {
      _showError('Error during timetable generation: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _clearTimetable() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignSystem.cardDark,
        title: const Text(
          'Clear Timetable',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete the generated timetable? You will need to regenerate it.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ApiService.clearTimetable();
        _showSuccess('Timetable cleared!');
        _loadTimetable();
      } catch (e) {
        _showError('Unable to clear timetable: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: DesignSystem.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: DesignSystem.success),
    );
  }

  Future<void> _exportExcel() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleController = TextEditingController(
      text: 'ORARIO DEFINITIVO ARANOVA a.s. 2025/2026',
    );
    final textColor = DesignSystem.getTextColor(context);
    final bgColor = isDark ? DesignSystem.cardDark : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
    final fieldBg = DesignSystem.getFieldColor(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Export Excel Timetable',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Customize timetable header (Aranova model):',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Document Title',
                  labelStyle: TextStyle(
                    color: textColor.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: fieldBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFF6366F1), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: textColor.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Export Excel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final allSlots = await ApiService.getTimetable();
      await ExcelExporter.exportTimetable(
        slots: allSlots,
        teachers: _teachers,
        classes: _classes,
        days: widget.schoolSettings.daysPerWeek,
        hours: widget.schoolSettings.hoursPerDay,
        title: titleController.text.trim().isNotEmpty
            ? titleController.text.trim()
            : 'ORARIO DEFINITIVO ARANOVA a.s. 2025/2026',
      );
      _showSuccess('Excel exported successfully!');
    } catch (e) {
      _showError('Unable to export Excel: $e');
    }
  }

  Future<void> _saveTimetable() async {
    if (_slots.isEmpty) {
      _showError('No timetable to save. Please generate a timetable first.');
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final textColor = DesignSystem.getTextColor(context);
    final bgColor = isDark ? DesignSystem.cardDark : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
    final fieldBg = DesignSystem.getFieldColor(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Save Timetable',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Name (e.g., Fall Timetable)',
                  labelStyle: TextStyle(
                    color: textColor.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: fieldBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: DesignSystem.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: TextStyle(color: textColor),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Comment (optional)',
                  labelStyle: TextStyle(
                    color: textColor.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: fieldBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: DesignSystem.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
          ),
          AppButton.primary(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      final name = nameController.text.trim();
      if (name.isEmpty) {
        _showError('Please enter a name for the timetable.');
        return;
      }
      try {
        await ApiService.saveTimetable(
          name: name,
          description: descController.text.trim().isEmpty
              ? null
              : descController.text.trim(),
          slots: _slots,
          daysPerWeek: widget.schoolSettings.daysPerWeek,
          hoursPerDay: widget.schoolSettings.hoursPerDay,
        );
        _showSuccess('Timetable "$name" saved successfully!');
      } catch (e) {
        _showError('Error during saving: $e');
      }
    }
  }

  Future<void> _showHistory() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = DesignSystem.getTextColor(context);
    final bgColor = isDark ? DesignSystem.cardDark : Colors.white;
    final subtitleColor = DesignSystem.getSubtitleColor(context);
    final rowBg = isDark
        ? DesignSystem.fieldDark.withValues(alpha: 0.5)
        : const Color(0xFFF1F5F9);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    List<SavedTimetable> timetables;
    try {
      timetables = await ApiService.getSavedTimetables();
    } catch (e) {
      _showError('Unable to load history: $e');
      return;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) => AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Timetable History',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: SizedBox(
            width: 520,
            height: 380,
            child: timetables.isEmpty
                ? Center(
                    child: Text(
                      'No saved timetables.',
                      style: TextStyle(color: subtitleColor),
                    ),
                  )
                : ListView.builder(
                    itemCount: timetables.length,
                    itemBuilder: (_, i) {
                      final st = timetables[i];
                      final dateStr =
                          '${st.createdAt.day.toString().padLeft(2, '0')}/${st.createdAt.month.toString().padLeft(2, '0')}/${st.createdAt.year}';
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: rowBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    st.name,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                      color: DesignSystem.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (st.description != null &&
                                      st.description!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      st.description!,
                                      style: TextStyle(
                                        color: subtitleColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Restore button
                            Tooltip(
                              message: 'Restore as active timetable',
                              child: IconButton(
                                icon: const Icon(
                                  Icons.restore,
                                  color: DesignSystem.success,
                                ),
                                onPressed: () async {
                                  try {
                                    await ApiService.restoreSavedTimetable(
                                      st.id,
                                    );
                                    if (!ctx.mounted) return;
                                    Navigator.pop(ctx);
                                    _loadTimetable();
                                    _showSuccess(
                                      'Timetable "${st.name}" restored!',
                                    );
                                  } catch (e) {
                                    _showError('Error during restore: $e');
                                  }
                                },
                              ),
                            ),
                            // Delete button
                            Tooltip(
                              message: 'Delete saved timetable',
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: DesignSystem.error,
                                ),
                                onPressed: () async {
                                  try {
                                    await ApiService.deleteSavedTimetable(
                                      st.id,
                                    );
                                    setStateDialog(
                                      () => timetables.removeAt(i),
                                    );
                                    _showSuccess('Timetable deleted.');
                                  } catch (e) {
                                    _showError('Error during deletion: $e');
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Close',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.schoolSettings.daysPerWeek;
    final hours = widget.schoolSettings.hoursPerDay;
    final giorniNomi = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(
              child: RepaintBoundary(
                child: CircularProgressIndicator(color: DesignSystem.primary),
              ),
            )
          : Padding(
              padding: EdgeInsets.all(DesignSystem.getPagePadding(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopToolbar(),
                  SizedBox(height: DesignSystem.getGridGap(context)),

                  // Diagnostic Error box if solve failed
                  if (_genErrorTitle != null) ...[
                    _buildDiagnosticErrorBox(),
                    SizedBox(height: DesignSystem.getGridGap(context)),
                  ],

                  // Main Timetable Grid Card
                  Expanded(
                    child: _isGenerating
                        ? const GeneratingSpinner()
                        : _buildTimetableCard(days, hours, giorniNomi),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTopToolbar() {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Widget selectorWidget = _filterType == 'class'
        ? (_classes.isNotEmpty
            ? PopupMenuButton<SchoolClass>(
                onSelected: (val) {
                  setState(() => _selectedFilterId = val.id);
                  _loadTimetable();
                },
                itemBuilder: (context) => _classes.map((c) {
                  return PopupMenuItem<SchoolClass>(
                    value: c,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: DesignSystem.secondary.withValues(alpha: 0.15),
                          child: Text(
                            c.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: DesignSystem.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(c.name),
                      ],
                    ),
                  );
                }).toList(),
                child: _buildSelectorButton(
                  avatar: CircleAvatar(
                    radius: 16,
                    backgroundColor: DesignSystem.secondary.withValues(alpha: 0.15),
                    child: Text(
                      (_classes.any((c) => c.id == _selectedFilterId)
                              ? _classes.firstWhere((c) => c.id == _selectedFilterId).name[0]
                              : 'C').toUpperCase(),
                      style: const TextStyle(
                        color: DesignSystem.secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  label: _classes.any((c) => c.id == _selectedFilterId)
                      ? _classes.firstWhere((c) => c.id == _selectedFilterId).name
                      : 'Select Class',
                ),
              )
            : const SizedBox.shrink())
        : (_teachers.isNotEmpty
            ? PopupMenuButton<Teacher>(
                onSelected: (val) {
                  setState(() => _selectedFilterId = val.id);
                  _loadTimetable();
                },
                itemBuilder: (context) => _teachers.map((t) {
                  return PopupMenuItem<Teacher>(
                    value: t,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: DesignSystem.primary.withValues(alpha: 0.15),
                          child: Text(
                            t.firstName[0].toUpperCase(),
                            style: const TextStyle(
                              color: DesignSystem.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(t.fullName),
                      ],
                    ),
                  );
                }).toList(),
                child: _buildSelectorButton(
                  avatar: CircleAvatar(
                    radius: 16,
                    backgroundColor: DesignSystem.primary.withValues(alpha: 0.15),
                    child: Text(
                      (_teachers.any((t) => t.id == _selectedFilterId)
                              ? _teachers.firstWhere((t) => t.id == _selectedFilterId).firstName[0]
                              : 'T').toUpperCase(),
                      style: const TextStyle(
                        color: DesignSystem.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  label: _teachers.any((t) => t.id == _selectedFilterId)
                      ? _teachers.firstWhere((t) => t.id == _selectedFilterId).fullName
                      : 'Select Teacher',
                ),
              )
            : const SizedBox.shrink());

    final Widget filtersWidget = Row(
      mainAxisSize: isDesktop ? MainAxisSize.min : MainAxisSize.max,
      children: [
        // Mode toggle
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: DesignSystem.getFieldColor(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.school, size: 20),
                color: _filterType == 'class' ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                style: IconButton.styleFrom(
                  backgroundColor: _filterType == 'class' ? DesignSystem.primary : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(6),
                ),
                onPressed: () {
                  setState(() {
                    _filterType = 'class';
                    if (_classes.isNotEmpty) {
                      _selectedFilterId = _classes.first.id;
                    } else {
                      _selectedFilterId = null;
                    }
                  });
                  _loadTimetable();
                },
                tooltip: 'By Class',
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.person, size: 20),
                color: _filterType == 'teacher' ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                style: IconButton.styleFrom(
                  backgroundColor: _filterType == 'teacher' ? DesignSystem.primary : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(6),
                ),
                onPressed: () {
                  setState(() {
                    _filterType = 'teacher';
                    if (_teachers.isNotEmpty) {
                      _selectedFilterId = _teachers.first.id;
                    } else {
                      _selectedFilterId = null;
                    }
                  });
                  _loadTimetable();
                },
                tooltip: 'By Teacher',
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (isDesktop) selectorWidget else Expanded(child: selectorWidget),
      ],
    );

    final Widget actionDropdownMenu = PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'history':
            _showHistory();
            break;
          case 'save':
            _saveTimetable();
            break;
          case 'export':
            try {
              final allSlots = await ApiService.getTimetable();
              await PdfExporter.exportTimetable(
                slots: allSlots,
                teachers: _teachers,
                days: widget.schoolSettings.daysPerWeek,
                hours: widget.schoolSettings.hoursPerDay,
              );
            } catch (e) {
              _showError('Unable to export PDF: $e');
            }
            break;
          case 'export_excel':
            _exportExcel();
            break;
          case 'clear':
            _clearTimetable();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'history',
          child: Row(
            children: [
              Icon(Icons.history, size: 20),
              SizedBox(width: 8),
              Text('History'),
            ],
          ),
        ),
        if (_slots.isNotEmpty) ...[
          const PopupMenuItem(
            value: 'save',
            child: Row(
              children: [
                Icon(Icons.save_outlined, size: 20, color: DesignSystem.success),
                SizedBox(width: 8),
                Text('Save'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'export',
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf_outlined, size: 20, color: DesignSystem.primary),
                SizedBox(width: 8),
                Text('Export PDF'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'export_excel',
            child: Row(
              children: [
                Icon(Icons.table_chart_outlined, size: 20, color: DesignSystem.success),
                SizedBox(width: 8),
                Text('Export Excel'),
              ],
            ),
          ),
        ],
        const PopupMenuItem(
          value: 'clear',
          child: Row(
            children: [
              Icon(Icons.delete_sweep_outlined, size: 20, color: DesignSystem.error),
              SizedBox(width: 8),
              Text('Clear'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: DesignSystem.getFieldColor(context),
          borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.more_horiz, color: isDark ? Colors.white70 : Colors.black87, size: 20),
            const SizedBox(width: 6),
            Text(
              'Actions',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: isDark ? Colors.white54 : Colors.black54,
              size: 20,
            ),
          ],
        ),
      ),
    );

    final Widget generateButton = AppButton.primary(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      onPressed: _isGenerating ? null : _generateTimetable,
      child: _isGenerating
          ? const RepaintBoundary(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.autorenew, size: 20),
                SizedBox(width: 8),
                Text(
                  'Generate',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
    );

    return AppCard(
      padding: EdgeInsets.all(DesignSystem.getCardPadding(context)),
      child: isDesktop
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                filtersWidget,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    generateButton,
                    const SizedBox(width: 12),
                    actionDropdownMenu,
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                filtersWidget,
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: generateButton),
                    const SizedBox(width: 8),
                    actionDropdownMenu,
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSelectorButton({required Widget avatar, required String label}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = DesignSystem.getTextColor(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: DesignSystem.getFieldColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar,
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: isDark ? Colors.white54 : Colors.black54,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticErrorBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignSystem.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignSystem.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: DesignSystem.error,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _genErrorTitle ?? 'Generation failed',
                  style: const TextStyle(
                    color: DesignSystem.error,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _genErrorDetails ??
                      'Check that the hourly constraints or overall hour load are not impossible to satisfy.',
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableCard(int days, int hours, List<String> giorniNomi) {
    final textColor = DesignSystem.getTextColor(context);
    final mutedColor = DesignSystem.getMutedColor(context);

    if (_selectedFilterId == null) {
      return AppCard(
        child: Center(
          child: Text(
            'Select a class or a teacher to view the timetable',
            style: TextStyle(
              color: mutedColor,
              fontSize: DesignSystem.getBodyLargeSize(context),
            ),
          ),
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _filterType == 'class' ? 'Class Timetable' : 'Teacher Schedule',
                style: TextStyle(
                  color: textColor,
                  fontSize: DesignSystem.getTitleMediumSize(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignSystem.getGridGap(context)),

          Expanded(
            child: SingleChildScrollView(
              child: TimetableGrid(
                slots: _slots,
                days: days,
                hours: hours,
                filterType: _filterType,
                giorniNomi: giorniNomi,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
