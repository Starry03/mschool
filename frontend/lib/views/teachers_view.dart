import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/design_system.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';

class TeachersView extends StatefulWidget {
  final SchoolSettings schoolSettings;
  const TeachersView({super.key, required this.schoolSettings});

  @override
  State<TeachersView> createState() => _TeachersViewState();
}

class _TeachersViewState extends State<TeachersView> {
  List<Teacher> _teachers = [];
  Teacher? _selectedTeacher;
  bool _isLoading = false;

  // Controllers for adding/editing teacher
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  // Settings for selected teacher
  int _maxConsecutive = 3;
  int _maxDaily = 5;
  bool _preferConsecutive = false;

  // Selected teacher's busy slots (day, hour)
  Set<String> _busySlots = {};

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.getTeachers();
      setState(() {
        _teachers = list;
        if (_selectedTeacher != null) {
          // Refresh selected teacher
          _selectedTeacher = list.firstWhere(
            (t) => t.id == _selectedTeacher!.id,
            orElse: () => list.first,
          );
          _loadTeacherData(_selectedTeacher!);
        } else if (list.isNotEmpty) {
          _selectedTeacher = list.first;
          _loadTeacherData(list.first);
        }
      });
    } catch (e) {
      _showError('Unable to load teachers: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadTeacherData(Teacher teacher) {
    setState(() {
      _maxConsecutive = teacher.settings?.maxConsecutiveHours ?? 3;
      _maxDaily = teacher.settings?.maxHoursPerDay ?? 5;
      _preferConsecutive = teacher.settings?.preferConsecutive ?? false;
      _busySlots = teacher.constraints
          .map((c) => '${c.day}-${c.hour}')
          .toSet();
    });
  }

  Future<void> _addTeacher() async {
    if (_firstNameController.text.trim().isEmpty) return;
    try {
      await ApiService.createTeacher(
        _firstNameController.text.trim(),
        _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
        _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      );
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _showSuccess('Teacher added successfully!');
      _loadTeachers();
    } catch (e) {
      _showError('Error during teacher creation: $e');
    }
  }

  Future<void> _deleteTeacher(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignSystem.cardDark,
        title: const Text('Delete Teacher', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this teacher? Connected assignments will be removed.', 
          style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: DesignSystem.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteTeacher(id);
        _showSuccess('Teacher deleted!');
        setState(() {
          _selectedTeacher = null;
        });
        _loadTeachers();
      } catch (e) {
        _showError('Unable to delete teacher: $e');
      }
    }
  }

  Future<void> _saveTeacherSettings() async {
    if (_selectedTeacher == null) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.updateTeacherSettings(_selectedTeacher!.id, _maxConsecutive, _maxDaily, preferConsecutive: _preferConsecutive);

      // Convert busy slots back to list of maps
      List<Map<String, int>> constraintsIn = _busySlots.map((slot) {
        final parts = slot.split('-');
        return {
          'day': int.parse(parts[0]),
          'hour': int.parse(parts[1]),
        };
      }).toList();

      await ApiService.syncTeacherConstraints(_selectedTeacher!.id, constraintsIn);
      _showSuccess('Constraints and settings saved successfully!');
      _loadTeachers();
    } catch (e) {
      _showError('Error during saving: $e');
    } finally {
      setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1050;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading && _teachers.isEmpty
          ? const Center(child: CircularProgressIndicator(color: DesignSystem.primary))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: isDesktop
                  ? Row(
                      children: [
                        // Sidebar: Teachers list
                        Expanded(
                          flex: 3,
                          child: _buildTeachersListCard(),
                        ),
                        const SizedBox(width: 24),
                        // Main area: Constraints and settings
                        Expanded(
                          flex: 7,
                          child: _selectedTeacher == null
                              ? _buildNoTeacherSelectedView()
                              : _buildTeacherDetailsView(),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 350,
                            child: _buildTeachersListCard(),
                          ),
                          const SizedBox(height: 24),
                          _selectedTeacher == null
                              ? _buildNoTeacherSelectedView()
                              : _buildTeacherDetailsView(),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildTeachersListCard() {
    final textColor = DesignSystem.getTextColor(context);
    final subtitleColor = DesignSystem.getSubtitleColor(context);
    final mutedColor = DesignSystem.getMutedColor(context);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Teachers List',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: _showAddTeacherDialog,
                  icon: const Icon(Icons.add_circle, color: DesignSystem.primary, size: 30),
                  tooltip: 'Add Teacher',
                ),
              ],
            ),
          ),
          Divider(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black.withOpacity(0.06), height: 1),

          Expanded(
            child: _teachers.isEmpty
                ? Center(
                    child: Text(
                      'No teachers added',
                      style: TextStyle(color: mutedColor),
                    ),
                  )
                : ListView.builder(
                    itemCount: _teachers.length,
                    itemBuilder: (context, index) {
                      final t = _teachers[index];
                      final isSelected = _selectedTeacher?.id == t.id;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? DesignSystem.primary.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? DesignSystem.primary.withOpacity(0.4) : Colors.transparent,
                          ),
                        ),
                        child: ListTile(
                          onTap: () {
                            setState(() {
                              _selectedTeacher = t;
                              _loadTeacherData(t);
                            });
                          },
                          title: Text(
                            t.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected ? DesignSystem.primary : textColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            t.email ?? 'No email',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: subtitleColor, fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: DesignSystem.error, size: 20),
                            onPressed: () => _deleteTeacher(t.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTeacherSelectedView() {
    final mutedColor = DesignSystem.getMutedColor(context);
    final textColor = DesignSystem.getTextColor(context).withOpacity(0.38);

    return AppCard(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, color: mutedColor, size: 80),
            const SizedBox(height: 16),
            Text(
              'Select or add a teacher',
              style: TextStyle(color: textColor, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherDetailsView() {
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width > 1050;
    final bool stackDetails = width < 1200;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTeacherHeaderCard(_selectedTeacher!),
        const SizedBox(height: 24),

        if (stackDetails) ...[
          _buildTeacherLimitsCard(),
          const SizedBox(height: 24),
          _buildConstraintsGridCard(),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: _buildTeacherLimitsCard(),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 6,
                child: _buildConstraintsGridCard(),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),

        AppButton.primary(
          onPressed: _saveTeacherSettings,
          child: const Text(
            'Save Constraints and Settings',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );

    if (isDesktop) {
      return SingleChildScrollView(
        child: content,
      );
    } else {
      return content;
    }
  }

  Widget _buildTeacherHeaderCard(Teacher teacher) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerTextColor = DesignSystem.getTextColor(context);
    final headerSubtitleColor = DesignSystem.getSubtitleColor(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [DesignSystem.primary.withOpacity(0.2), DesignSystem.secondary.withOpacity(0.1)]
              : [DesignSystem.primary.withOpacity(0.08), DesignSystem.secondary.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignSystem.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: DesignSystem.primary.withOpacity(0.2),
            child: Text(
              teacher.firstName[0].toUpperCase(),
              style: const TextStyle(color: DesignSystem.primary, fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                teacher.fullName,
                style: TextStyle(color: headerTextColor, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                teacher.email ?? 'No email address configured',
                style: TextStyle(color: headerSubtitleColor, fontSize: 14),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTeacherLimitsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = DesignSystem.getTextColor(context);
    final subtitleColor = DesignSystem.getSubtitleColor(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Timetable Limits',
            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          Text(
            'Max Consecutive Hours: $_maxConsecutive',
            style: TextStyle(color: subtitleColor, fontSize: 14),
          ),
          Slider(
            value: _maxConsecutive.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            activeColor: DesignSystem.primary,
            inactiveColor: isDark ? Colors.white12 : Colors.black12,
            onChanged: (val) {
              setState(() {
                _maxConsecutive = val.toInt();
                if (_maxDaily < _maxConsecutive) {
                  _maxDaily = _maxConsecutive;
                }
              });
            },
          ),
          const SizedBox(height: 16),

          Text(
            'Max Daily Hours: $_maxDaily',
            style: TextStyle(color: subtitleColor, fontSize: 14),
          ),
          Slider(
            value: _maxDaily.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            activeColor: DesignSystem.secondary,
            inactiveColor: isDark ? Colors.white12 : Colors.black12,
            onChanged: (val) {
              setState(() {
                _maxDaily = val.toInt();
                if (_maxConsecutive > _maxDaily) {
                  _maxConsecutive = _maxDaily;
                }
              });
            },
          ),
          const SizedBox(height: 24),

          // Toggle: Preferisce ore consecutive
          Builder(builder: (context) {
            final isDarkInner = Theme.of(context).brightness == Brightness.dark;
            final subtitleColorInner = isDarkInner ? Colors.white60 : const Color(0xFF64748B);
            return Container(
              decoration: BoxDecoration(
                color: DesignSystem.getFieldColor(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  'Prefers consecutive hours',
                  style: TextStyle(color: isDarkInner ? Colors.white : const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'The solver will try to group the teacher\'s hours on the same day',
                  style: TextStyle(color: subtitleColorInner, fontSize: 12),
                ),
                value: _preferConsecutive,
                activeThumbColor: DesignSystem.primary,
                onChanged: (val) => setState(() => _preferConsecutive = val),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConstraintsGridCard() {
    final days = widget.schoolSettings.daysPerWeek;
    final hours = widget.schoolSettings.hoursPerDay;
    final giorniNomi = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = DesignSystem.getTextColor(context);
    final subtitleColor = DesignSystem.getSubtitleColor(context);
    final mutedColor = DesignSystem.getMutedColor(context);
    final gridLineColor = isDark ? Colors.white12 : Colors.black12;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Unavailability Slots',
            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Click on the hours when the teacher is NOT available.',
            style: TextStyle(color: mutedColor, fontSize: 12),
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final double minWidth = 100.0 + (days * 90.0);
              final double widthToUse = constraints.maxWidth > minWidth
                  ? constraints.maxWidth
                  : minWidth;
              final bool needsScroll = constraints.maxWidth < minWidth;

              Widget tableWidget = SizedBox(
                width: widthToUse,
                child: Table(
                  border: TableBorder.symmetric(
                    inside: BorderSide(color: gridLineColor, width: 0.5),
                  ),
                  children: [
                    TableRow(
                      children: [
                        const SizedBox(height: 30),
                        ...List.generate(days, (d) => Center(
                          child: Text(
                            giorniNomi[d],
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                          ),
                        )),
                      ],
                    ),

                    ...List.generate(hours, (h) {
                      return TableRow(
                        children: [
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: Center(
                              child: Text(
                                'Hour ${h + 1}',
                                style: TextStyle(color: subtitleColor, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          ...List.generate(days, (d) {
                            final key = '$d-$h';
                            final isBusy = _busySlots.contains(key);
                            final cellBgColor = isBusy 
                                ? DesignSystem.error.withOpacity(0.08) 
                                : Colors.transparent;
                            final cellBorderColor = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04);
                            
                            return TableCell(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isBusy) {
                                      _busySlots.remove(key);
                                    } else {
                                      _busySlots.add(key);
                                    }
                                  });
                                },
                                child: Container(
                                  height: 48,
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: cellBgColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isBusy 
                                          ? DesignSystem.error.withOpacity(0.8) 
                                          : cellBorderColor,
                                      width: isBusy ? 1.5 : 1,
                                    ),
                                    boxShadow: isBusy ? [
                                      BoxShadow(
                                        color: DesignSystem.error.withOpacity(0.15),
                                        blurRadius: 8,
                                      )
                                    ] : null,
                                  ),
                                  child: Center(
                                    child: isBusy 
                                        ? const Icon(Icons.block, color: DesignSystem.error, size: 16) 
                                        : null,
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
          ),
        ],
      ),
    );
  }

  void _showAddTeacherDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? DesignSystem.cardDark : Colors.white;
    final inputColor = DesignSystem.getTextColor(context);
    final labelColor = isDark ? Colors.white54 : Colors.black54;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'New Teacher',
          style: TextStyle(color: inputColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _firstNameController,
              style: TextStyle(color: inputColor),
              decoration: InputDecoration(
                labelText: 'First Name *',
                labelStyle: TextStyle(color: labelColor),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black26)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: DesignSystem.primary)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              style: TextStyle(color: inputColor),
              decoration: InputDecoration(
                labelText: 'Last Name (optional)',
                labelStyle: TextStyle(color: labelColor),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black26)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: DesignSystem.primary)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: inputColor),
              decoration: InputDecoration(
                labelText: 'Email (optional)',
                labelStyle: TextStyle(color: labelColor),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black26)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: DesignSystem.primary)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _firstNameController.clear();
              _lastNameController.clear();
              _emailController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          AppButton.primary(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            onPressed: () {
              Navigator.pop(context);
              _addTeacher();
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
