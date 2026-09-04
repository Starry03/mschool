import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/design_system.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_dropdown.dart';

class DataManagementView extends StatefulWidget {
  final SchoolSettings? schoolSettings;
  const DataManagementView({super.key, this.schoolSettings});

  @override
  State<DataManagementView> createState() => _DataManagementViewState();
}

class _DataManagementViewState extends State<DataManagementView> {
  SchoolSettings? _schoolSettings;
  List<SchoolClass> _classes = [];
  List<Subject> _subjects = [];
  List<ClassSubjectConstraint> _constraints = [];

  bool _isLoadingClasses = false;
  bool _isLoadingSubjects = false;
  bool _isLoadingConstraints = false;

  final _classController = TextEditingController();
  final _subjectController = TextEditingController();

  final Set<int> _selectedClassIdsConstraint = {};
  Subject? _selectedSubjectConstraint;
  int _constraintHours = 4;

  @override
  void initState() {
    super.initState();
    _schoolSettings = widget.schoolSettings;
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (_schoolSettings == null) {
      try {
        final s = await ApiService.getSettings();
        if (mounted) setState(() => _schoolSettings = s);
      } catch (_) {}
    }
    await _loadClasses();
    await _loadSubjects();
    await _loadConstraints();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoadingClasses = true);
    try {
      final list = await ApiService.getClasses();
      setState(() {
        _classes = list;
      });
    } catch (e) {
      _showError('Unable to load classes: $e');
    } finally {
      setState(() => _isLoadingClasses = false);
    }
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoadingSubjects = true);
    try {
      final list = await ApiService.getSubjects();
      setState(() {
        _subjects = list;
        if (list.isNotEmpty && _selectedSubjectConstraint == null) {
          _selectedSubjectConstraint = list.first;
        }
      });
    } catch (e) {
      _showError('Unable to load subjects: $e');
    } finally {
      setState(() => _isLoadingSubjects = false);
    }
  }

  Future<void> _loadConstraints() async {
    setState(() => _isLoadingConstraints = true);
    try {
      final list = await ApiService.getClassSubjectConstraints();
      setState(() {
        _constraints = list;
        // Update dropdown selections if necessary
        if (_subjects.isNotEmpty && (_selectedSubjectConstraint == null || !_subjects.contains(_selectedSubjectConstraint))) {
          _selectedSubjectConstraint = _subjects.first;
        }
      });
    } catch (e) {
      _showError('Unable to load subject hour constraints: $e');
    } finally {
      setState(() => _isLoadingConstraints = false);
    }
  }

  Future<void> _addClass() async {
    final name = _classController.text.trim();
    if (name.isEmpty) return;
    try {
      await ApiService.createClass(name);
      _classController.clear();
      _showSuccess('Class added!');
      await _loadClasses();
      await _loadConstraints();
    } catch (e) {
      _showError('Error during class creation: $e');
    }
  }

  Future<void> _addSubject() async {
    final name = _subjectController.text.trim();
    if (name.isEmpty) return;
    try {
      await ApiService.createSubject(name);
      _subjectController.clear();
      _showSuccess('Subject added!');
      await _loadSubjects();
      await _loadConstraints();
    } catch (e) {
      _showError('Error during subject creation: $e');
    }
  }

  Future<void> _addConstraint() async {
    if (_selectedSubjectConstraint == null || _selectedClassIdsConstraint.isEmpty) {
      _showError('Select the subject and at least one class before adding the constraint.');
      return;
    }

    try {
      int successCount = 0;
      for (final classId in _selectedClassIdsConstraint) {
        // Verify if a constraint already exists for this class and subject
        final exists = _constraints.any((c) => c.classId == classId && c.subjectId == _selectedSubjectConstraint!.id);
        if (!exists) {
          await ApiService.createClassSubjectConstraint(
            classId,
            _selectedSubjectConstraint!.id,
            _constraintHours,
          );
          successCount++;
        }
      }
      _showSuccess('Added $successCount subject hour constraints!');
      setState(() {
        _selectedClassIdsConstraint.clear();
      });
      _loadConstraints();
    } catch (e) {
      _showError('Error during adding constraint: $e');
    }
  }

  Future<void> _deleteClass(int id) async {
    try {
      await ApiService.deleteClass(id);
      _showSuccess('Class deleted!');
      _selectedClassIdsConstraint.remove(id);
      await _loadClasses();
      await _loadConstraints();
    } catch (e) {
      _showError('Error during class deletion: $e');
    }
  }

  Future<void> _deleteSubject(int id) async {
    try {
      await ApiService.deleteSubject(id);
      _showSuccess('Subject deleted!');
      if (_selectedSubjectConstraint?.id == id) {
        _selectedSubjectConstraint = null;
      }
      await _loadSubjects();
      await _loadConstraints();
    } catch (e) {
      _showError('Error during subject deletion: $e');
    }
  }

  Future<void> _editClass(SchoolClass schoolClass) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = DesignSystem.getTextColor(context);
    final bgColor = isDark ? DesignSystem.cardDark : Colors.white;
    final subtitleColor = DesignSystem.getSubtitleColor(context);
    final fieldBg = DesignSystem.getFieldColor(context);
    final editController = TextEditingController(text: schoolClass.name);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Modifica Classe',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: SizedBox(
          width: 380,
          child: TextField(
            controller: editController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Nome Classe *',
              labelStyle: TextStyle(color: subtitleColor),
              filled: true,
              fillColor: fieldBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: DesignSystem.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
          ),
          AppButton.primary(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            onPressed: () async {
              final newName = editController.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ApiService.updateClass(schoolClass.id, newName);
                _showSuccess('Classe aggiornata con successo!');
                await _loadClasses();
                await _loadConstraints();
              } catch (e) {
                _showError('Errore durante la modifica della classe: $e');
              }
            },
            child: const Text('Salva', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _openSubjectSettings(Subject subject) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = DesignSystem.getTextColor(context);
    final bgColor = isDark ? DesignSystem.cardDark : Colors.white;
    final subtitleColor = DesignSystem.getSubtitleColor(context);
    final fieldBg = DesignSystem.getFieldColor(context);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05);

    final nameController = TextEditingController(text: subject.name);
    int currentMaxConsec = subject.maxConsecutiveHours ?? 0; // 0 = no limit
    int dialogMaxConsec = currentMaxConsec;
    int currentMaxDaily = subject.maxHoursPerDay ?? 0; // 0 = no limit
    int dialogMaxDaily = currentMaxDaily;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) => AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Modifica Materia',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Nome Materia *',
                      labelStyle: TextStyle(color: subtitleColor),
                      filled: true,
                      fillColor: fieldBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: DesignSystem.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Max Consecutive Hours
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: fieldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dialogMaxConsec == 0
                              ? 'Max consecutive hours: No limit'
                              : 'Max consecutive hours: $dialogMaxConsec',
                          style: TextStyle(
                            color: subtitleColor, fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Slider(
                          value: dialogMaxConsec.toDouble(),
                          min: 0,
                          max: 6,
                          divisions: 6,
                          activeColor: DesignSystem.primary,
                          inactiveColor: isDark ? Colors.white12 : Colors.black12,
                          label: dialogMaxConsec == 0 ? 'No limit' : '$dialogMaxConsec',
                          onChanged: (val) => setStateDialog(() => dialogMaxConsec = val.toInt()),
                        ),
                        Text(
                          dialogMaxConsec == 0
                              ? 'No consecutivity constraint for this subject'
                              : 'Maximum $dialogMaxConsec consecutive ${dialogMaxConsec == 1 ? "hour" : "hours"} per class',
                          style: TextStyle(color: subtitleColor.withValues(alpha: 0.7), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Max Daily Hours
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: fieldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dialogMaxDaily == 0
                              ? 'Max daily hours: No limit'
                              : 'Max daily hours: $dialogMaxDaily',
                          style: TextStyle(
                            color: subtitleColor, fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Slider(
                          value: dialogMaxDaily.toDouble(),
                          min: 0,
                          max: 6,
                          divisions: 6,
                          activeColor: DesignSystem.primary,
                          inactiveColor: isDark ? Colors.white12 : Colors.black12,
                          label: dialogMaxDaily == 0 ? 'No limit' : '$dialogMaxDaily',
                          onChanged: (val) => setStateDialog(() => dialogMaxDaily = val.toInt()),
                        ),
                        Text(
                          dialogMaxDaily == 0
                              ? 'No daily limit for this subject'
                              : 'Maximum $dialogMaxDaily ${dialogMaxDaily == 1 ? "hour" : "hours"} per day per class',
                          style: TextStyle(color: subtitleColor.withValues(alpha: 0.7), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            AppButton.primary(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ApiService.updateSubject(
                    subject.id,
                    name: newName,
                    maxConsecutiveHours: dialogMaxConsec == 0 ? null : dialogMaxConsec,
                    maxHoursPerDay: dialogMaxDaily == 0 ? null : dialogMaxDaily,
                  );
                  await _loadSubjects();
                  await _loadConstraints();
                  _showSuccess('Materia $newName aggiornata con successo!');
                } catch (e) {
                  _showError('Error: $e');
                }
              },
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteConstraint(int id) async {
    try {
      await ApiService.deleteClassSubjectConstraint(id);
      _showSuccess('Constraint removed!');
      _loadConstraints();
    } catch (e) {
      _showError('Error during constraint removal: $e');
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

  Widget _buildClassesPanel() {
    return _buildPanel(
       title: 'Classes',
       subtitle: 'Add and manage school classes (e.g., 1A, 2B)',
       controller: _classController,
       labelText: 'Class Name (e.g., 3C)',
       onAdd: _addClass,
       isLoading: _isLoadingClasses,
       itemsCount: _classes.length,
       itemBuilder: (context, index) {
         final c = _classes[index];
         return _buildItemRow(
           name: c.name,
           icon: Icons.meeting_room_outlined,
           onEdit: () => _editClass(c),
           onDelete: () => _deleteClass(c.id),
         );
       },
    );
  }

  Widget _buildSubjectsPanel() {
    return _buildPanel(
      title: 'Subjects',
      subtitle: 'Add and manage teaching subjects (e.g., Mathematics)',
      controller: _subjectController,
      labelText: 'Subject Name (e.g., Italian)',
      onAdd: _addSubject,
      isLoading: _isLoadingSubjects,
      itemsCount: _subjects.length,
      itemBuilder: (context, index) {
        final s = _subjects[index];
        final hasConsecLimit = s.maxConsecutiveHours != null;
        final hasDailyLimit = s.maxHoursPerDay != null;
        return _buildItemRow(
          name: s.name,
          icon: Icons.book_outlined,
          onEdit: () => _openSubjectSettings(s),
          onDelete: () => _deleteSubject(s.id),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasConsecLimit)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DesignSystem.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DesignSystem.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'max ${s.maxConsecutiveHours}h consec.',
                    style: const TextStyle(
                      color: DesignSystem.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (hasDailyLimit)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DesignSystem.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DesignSystem.secondary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'max ${s.maxHoursPerDay}h/day',
                    style: const TextStyle(
                      color: DesignSystem.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConstraintsPanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = DesignSystem.getTextColor(context);
    final subtitleColor = DesignSystem.getSubtitleColor(context);
    final mutedColor = DesignSystem.getMutedColor(context);
    final fieldBgColor = DesignSystem.getFieldColor(context);

    // Grouping constraints by Class Name
    final Map<String, List<ClassSubjectConstraint>> grouped = {};
    for (final sc in _constraints) {
      final className = sc.schoolClass?.name ?? 'No Class';
      grouped.putIfAbsent(className, () => []).add(sc);
    }
    final sortedClassNames = grouped.keys.toList()..sort();

    final List<dynamic> listItems = [];
    for (final className in sortedClassNames) {
      listItems.add(className); // Header
      listItems.addAll(grouped[className]!); // Constraint row
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Subject Hours',
            style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Set how many hours of a subject a class should have',
            style: TextStyle(color: subtitleColor, fontSize: 13),
          ),
          const SizedBox(height: 24),

          if (_classes.isEmpty || _subjects.isEmpty) ...[
            Expanded(
              child: Center(
                child: Text(
                  'Add classes and subjects first',
                  style: TextStyle(color: mutedColor),
                ),
              ),
            )
          ] else ...[
            // Multi-choice of Classes
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Class',
                      style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 12),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedClassIdsConstraint.addAll(_classes.map((c) => c.id));
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'All',
                            style: TextStyle(fontSize: 12, color: DesignSystem.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedClassIdsConstraint.clear();
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'None',
                            style: TextStyle(fontSize: 12, color: DesignSystem.error, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: fieldBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: DesignSystem.getBorder(context),
                  ),
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _classes.map((c) {
                        final isSelected = _selectedClassIdsConstraint.contains(c.id);
                        return ChoiceChip(
                          label: Text(
                            c.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : textColor,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: DesignSystem.primary,
                          backgroundColor: isDark ? DesignSystem.cardDark : Colors.grey.shade200,
                          checkmarkColor: Colors.white,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedClassIdsConstraint.add(c.id);
                              } else {
                                _selectedClassIdsConstraint.remove(c.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Subject Dropdown
            AppDropdown<Subject>(
              label: 'Subject',
              value: _selectedSubjectConstraint,
              items: _subjects,
              onChanged: (val) => setState(() => _selectedSubjectConstraint = val),
              itemAsString: (s) => s.name,
            ),
            const SizedBox(height: 12),

            // Hours Slider and Add Button Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hours: $_constraintHours h',
                        style: TextStyle(color: subtitleColor, fontSize: 13),
                      ),
                      Slider(
                        value: _constraintHours.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        activeColor: DesignSystem.primary,
                        inactiveColor: isDark ? Colors.white12 : Colors.black12,
                        onChanged: (val) => setState(() => _constraintHours = val.toInt()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppButton.primary(
                  padding: const EdgeInsets.all(16),
                  onPressed: _addConstraint,
                  child: const Icon(Icons.add, color: Colors.white),
                )
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06), height: 1),
            const SizedBox(height: 12),

            // Constraints List
            Expanded(
              child: _isLoadingConstraints
                  ? const Center(child: RepaintBoundary(child: CircularProgressIndicator(color: DesignSystem.primary)))
                  : _constraints.isEmpty
                      ? Center(
                          child: Text(
                            'No constraints set',
                            style: TextStyle(color: mutedColor),
                          ),
                        )
                      : ListView.builder(
                          itemCount: listItems.length,
                          itemBuilder: (context, index) {
                            final item = listItems[index];

                            if (item is String) {
                              // Render Class Header with total hours and soft feedback
                              final className = item;
                              final classConstraints = grouped[className] ?? [];
                              final int totalHours = classConstraints.fold(0, (sum, c) => sum + c.weeklyHours);
                              final int maxHours = (_schoolSettings?.daysPerWeek ?? 5) * (_schoolSettings?.hoursPerDay ?? 6);
                              final bool isOverLimit = totalHours > maxHours;

                              return Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 8, left: 8, right: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.meeting_room_outlined, size: 16, color: DesignSystem.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Class $className',
                                      style: const TextStyle(
                                        color: DesignSystem.primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isOverLimit
                                            ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                            : DesignSystem.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isOverLimit
                                              ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                                              : DesignSystem.primary.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Totale: ${totalHours}h / ${maxHours}h',
                                            style: TextStyle(
                                              color: isOverLimit ? const Color(0xFFD97706) : DesignSystem.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (isOverLimit) ...[
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.warning_amber_rounded,
                                              size: 15,
                                              color: Color(0xFFD97706),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '(+${totalHours - maxHours}h oltre il limite)',
                                              style: const TextStyle(
                                                color: Color(0xFFD97706),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final sc = item as ClassSubjectConstraint;
                            final rowBgColor = isDark ? DesignSystem.fieldDark.withValues(alpha: 0.2) : const Color(0xFFF1F5F9);
                            final rowBorderColor = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04);

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: rowBgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: rowBorderColor),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      sc.subject?.name ?? "Subject",
                                      style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: DesignSystem.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${sc.weeklyHours}h',
                                      style: const TextStyle(color: DesignSystem.primary, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: DesignSystem.error, size: 20),
                                    onPressed: () => _deleteConstraint(sc.id),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1200;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(DesignSystem.getPagePadding(context)),
        child: isDesktop
            ? Row(
                children: [
                  Expanded(child: _buildClassesPanel()),
                  SizedBox(width: DesignSystem.getGridGap(context)),
                  Expanded(child: _buildSubjectsPanel()),
                  SizedBox(width: DesignSystem.getGridGap(context)),
                  Expanded(child: _buildConstraintsPanel()),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 400, child: _buildClassesPanel()),
                    SizedBox(height: DesignSystem.getGridGap(context)),
                    SizedBox(height: 400, child: _buildSubjectsPanel()),
                    SizedBox(height: DesignSystem.getGridGap(context)),
                    SizedBox(height: 500, child: _buildConstraintsPanel()),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPanel({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required String labelText,
    required VoidCallback onAdd,
    required bool isLoading,
    required int itemsCount,
    required Widget? Function(BuildContext, int) itemBuilder,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = DesignSystem.getTextColor(context);
    final subtitleColor = DesignSystem.getSubtitleColor(context);
    final mutedColor = DesignSystem.getMutedColor(context);
    final fieldBgColor = DesignSystem.getFieldColor(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Text
          Text(
            title,
            style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: subtitleColor, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Form Row to add new item
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: TextStyle(color: textColor),
                  onSubmitted: (_) => onAdd(),
                  decoration: InputDecoration(
                    labelText: labelText,
                    labelStyle: TextStyle(color: mutedColor, fontSize: 14),
                    filled: true,
                    fillColor: fieldBgColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: DesignSystem.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AppButton.primary(
                padding: const EdgeInsets.all(16),
                onPressed: onAdd,
                child: const Icon(Icons.add, color: Colors.white),
              )
            ],
          ),

          const SizedBox(height: 24),
          Divider(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06), height: 1),
          const SizedBox(height: 12),

          // List
          Expanded(
            child: isLoading
                ? const Center(child: RepaintBoundary(child: CircularProgressIndicator(color: DesignSystem.primary)))
                : itemsCount == 0
                    ? Center(
                        child: Text(
                          'No elements found',
                          style: TextStyle(color: mutedColor),
                        ),
                      )
                    : ListView.builder(
                        itemCount: itemsCount,
                        itemBuilder: itemBuilder,
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow({
    required String name,
    required IconData icon,
    required VoidCallback onDelete,
    VoidCallback? onEdit,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowBgColor = isDark ? DesignSystem.fieldDark.withValues(alpha: 0.2) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04);
    final textColor = DesignSystem.getTextColor(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: rowBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: DesignSystem.primary.withValues(alpha: 0.8), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textColor, fontSize: 15),
            ),
          ),
          if (trailing != null) ...[
            trailing,
            const SizedBox(width: 6),
          ],
          if (onEdit != null) ...[
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.edit_outlined,
                color: isDark ? Colors.white70 : Colors.black54,
                size: 19,
              ),
              tooltip: 'Modifica',
              onPressed: onEdit,
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.delete_outline, color: DesignSystem.error, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
