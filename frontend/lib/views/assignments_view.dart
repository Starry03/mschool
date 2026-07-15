import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/design_system.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_dropdown.dart';

class AssignmentsView extends StatefulWidget {
  const AssignmentsView({super.key});

  @override
  State<AssignmentsView> createState() => _AssignmentsViewState();
}

class _AssignmentsViewState extends State<AssignmentsView> {
  List<Assignment> _assignments = [];
  List<Teacher> _teachers = [];
  List<SchoolClass> _classes = [];
  List<Subject> _subjects = [];

  bool _isLoading = false;

  // Selected values for new assignment
  Teacher? _selectedTeacher;
  final Set<int> _selectedClassIds = {};
  Subject? _selectedSubject;
  int _weeklyHours = 4;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final teachers = await ApiService.getTeachers();
      final classes = await ApiService.getClasses();
      final subjects = await ApiService.getSubjects();
      final assignments = await ApiService.getAssignments();

      setState(() {
        _teachers = teachers;
        _classes = classes;
        _subjects = subjects;
        _assignments = assignments;

        // Set defaults if lists are not empty
        if (teachers.isNotEmpty) _selectedTeacher = teachers.first;
        if (subjects.isNotEmpty) _selectedSubject = subjects.first;
      });
    } catch (e) {
      _showError('Unable to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addAssignment() async {
    if (_selectedTeacher == null ||
        _selectedSubject == null ||
        _selectedClassIds.isEmpty) {
      _showError(
        'Make sure you have selected the teacher, subject, and at least one class.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      int successCount = 0;
      for (final classId in _selectedClassIds) {
        await ApiService.createAssignment(
          _selectedTeacher!.id,
          classId,
          _selectedSubject!.id,
          _weeklyHours,
        );
        successCount++;
      }
      _showSuccess('Chairs assigned successfully ($successCount classes)!');
      setState(() {
        _selectedClassIds.clear();
      });
      _loadAllData();
    } catch (e) {
      _showError('Error during assignment: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAssignment(int id) async {
    try {
      await ApiService.deleteAssignment(id);
      _showSuccess('Assignment removed!');
      _loadAllData();
    } catch (e) {
      _showError('Error during removal: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: DesignSystem.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignSystem.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading && _assignments.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: DesignSystem.primary),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: isDesktop
                  ? Row(
                      children: [
                        // Left column: Create assignment form
                        Expanded(
                          flex: 4,
                          child: _buildCreateAssignmentCard(),
                        ),
                        const SizedBox(width: 24),
                        // Right column: Assignments list
                        Expanded(
                          flex: 6,
                          child: _buildAssignmentsListCard(),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildCreateAssignmentCard(),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 450,
                            child: _buildAssignmentsListCard(),
                          ),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildCreateAssignmentCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = DesignSystem.getTextColor(context);
    final mutedColor = DesignSystem.getMutedColor(context);
    final fieldBgColor = DesignSystem.getFieldColor(context);

    return AppCard(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New Chair Assignment',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Assign a teacher to teach a subject to one or more classes.',
              style: TextStyle(color: mutedColor, fontSize: 12),
            ),
            const SizedBox(height: 32),

            if (_teachers.isEmpty || _classes.isEmpty || _subjects.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orangeAccent,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'To assign a chair, you must first\nenter teachers, classes, and subjects.',
                        style: TextStyle(color: mutedColor, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // 1. Choice of Teacher (Prof)
              AppDropdown<Teacher>(
                label: 'Select Teacher',
                value: _selectedTeacher,
                items: _teachers,
                onChanged: (val) => setState(() => _selectedTeacher = val),
                itemAsString: (t) => t.fullName,
              ),
              const SizedBox(height: 20),

              // 2. Choice of Subject (Materia)
              AppDropdown<Subject>(
                label: 'Select Subject',
                value: _selectedSubject,
                items: _subjects,
                onChanged: (val) => setState(() => _selectedSubject = val),
                itemAsString: (s) => s.name,
              ),
              const SizedBox(height: 20),

              // 3. Multi-choice of Classes
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Classes',
                        style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedClassIds.addAll(
                                  _classes.map((c) => c.id),
                                );
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'All',
                              style: TextStyle(
                                fontSize: 12,
                                color: DesignSystem.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedClassIds.clear();
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'None',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: DesignSystem.error,
                                  fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: fieldBgColor,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                      border: DesignSystem.getBorder(context),
                    ),
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _classes.map((c) {
                          final isSelected = _selectedClassIds.contains(c.id);
                          return ChoiceChip(
                            label: Text(
                              c.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : textColor,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: DesignSystem.primary,
                            backgroundColor: isDark
                                ? DesignSystem.cardDark
                                : Colors.grey.shade200,
                            checkmarkColor: Colors.white,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedClassIds.add(c.id);
                                } else {
                                  _selectedClassIds.remove(c.id);
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
              const SizedBox(height: 20),

              // 4. Weekly Hours
              Text(
                'Weekly Hours: $_weeklyHours hours',
                style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13),
              ),
              Slider(
                value: _weeklyHours.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: DesignSystem.primary,
                inactiveColor: isDark ? Colors.white12 : Colors.black12,
                label: '$_weeklyHours hours',
                onChanged: (val) => setState(() => _weeklyHours = val.toInt()),
              ),
              const SizedBox(height: 24),

              AppButton.primary(
                onPressed: _addAssignment,
                child: const Text(
                  'Assign Chair',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsListCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = DesignSystem.getTextColor(context);
    final subtitleColor = DesignSystem.getSubtitleColor(context);
    final mutedColor = DesignSystem.getMutedColor(context);

    // Group assignments by class
    final Map<String, List<Assignment>> grouped = {};
    for (final a in _assignments) {
      final className = a.schoolClass?.name ?? 'No Class';
      grouped.putIfAbsent(className, () => []).add(a);
    }
    final sortedClassNames = grouped.keys.toList()..sort();

    final List<dynamic> listItems = [];
    for (final className in sortedClassNames) {
      listItems.add(className); // Header
      listItems.addAll(grouped[className]!); // Assignment row
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Assigned Chairs',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06), height: 1),

          Expanded(
            child: _assignments.isEmpty
                ? Center(
                    child: Text(
                      'No chairs assigned',
                      style: TextStyle(color: mutedColor),
                    ),
                  )
                : ListView.builder(
                    itemCount: listItems.length,
                    itemBuilder: (context, index) {
                      final item = listItems[index];

                      if (item is String) {
                        // Render Class Header
                        return Padding(
                          padding: const EdgeInsets.only(
                            top: 16,
                            bottom: 8,
                            left: 8,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.meeting_room_outlined,
                                size: 16,
                                color: DesignSystem.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Class $item',
                                style: const TextStyle(
                                  color: DesignSystem.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final a = item as Assignment;
                      final rowBgColor = isDark
                          ? DesignSystem.fieldDark.withOpacity(0.2)
                          : const Color(0xFFF1F5F9);
                      final rowBorderColor = isDark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.black.withOpacity(0.04);
                      final badgeBgColor = isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.04);

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: rowBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: rowBorderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        a.subject?.name ?? 'Subject',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    a.teacher?.fullName ?? 'Unknown',
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: badgeBgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${a.weeklyHours}h/week',
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: DesignSystem.error,
                                size: 20,
                              ),
                              onPressed: () => _deleteAssignment(a.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
