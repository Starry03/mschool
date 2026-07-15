import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

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
      _showError('Impossibile caricare i dati: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addAssignment() async {
    if (_selectedTeacher == null || _selectedSubject == null || _selectedClassIds.isEmpty) {
      _showError('Assicurati di aver selezionato il docente, la materia e almeno una classe.');
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
      _showSuccess('Cattedre assegnate con successo ($successCount classi)!');
      setState(() {
        _selectedClassIds.clear();
      });
      _loadAllData();
    } catch (e) {
      _showError('Errore durante l\'assegnazione: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAssignment(int id) async {
    try {
      await ApiService.deleteAssignment(id);
      _showSuccess('Assegnazione rimossa!');
      _loadAllData();
    } catch (e) {
      _showError('Errore durante la rimozione: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFF10B981)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading && _assignments.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  // Left column: Create assignment form
                  Expanded(
                    flex: isDesktop ? 4 : 5,
                    child: _buildCreateAssignmentCard(),
                  ),
                  
                  const SizedBox(width: 24),
                  
                  // Right column: Assignments list
                  Expanded(
                    flex: isDesktop ? 6 : 7,
                    child: _buildAssignmentsListCard(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCreateAssignmentCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2235).withOpacity(0.8) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final mutedColor = isDark ? Colors.white38 : Colors.black38;
    final fieldBgColor = isDark ? const Color(0xFF2E334D).withOpacity(0.4) : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: !isDark ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nuova Assegnazione Cattedra',
            style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Associa un docente a una classe per una determinata materia ed indica il monte ore settimanale.',
            style: TextStyle(color: mutedColor, fontSize: 12),
          ),
          const SizedBox(height: 32),
          
          if (_teachers.isEmpty || _classes.isEmpty || _subjects.isEmpty) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'Per assegnare una cattedra devi prima\ninserire docenti, classi e materie.',
                      style: TextStyle(color: subtitleColor, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          ] else ...[
            // 1. Choice of Teacher (Prof)
            _buildDropdown<Teacher>(
              label: 'Seleziona Docente',
              value: _selectedTeacher,
              items: _teachers,
              onChanged: (val) => setState(() => _selectedTeacher = val),
              itemAsString: (t) => t.fullName,
            ),
            const SizedBox(height: 20),
            
            // 2. Choice of Subject (Materia)
            _buildDropdown<Subject>(
              label: 'Seleziona Materia',
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
                      'Seleziona Classi',
                      style: TextStyle(color: subtitleColor, fontSize: 13),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedClassIds.addAll(_classes.map((c) => c.id));
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Tutte',
                            style: TextStyle(fontSize: 12, color: const Color(0xFF6366F1), fontWeight: FontWeight.bold),
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
                          child: Text(
                            'Nessuna',
                            style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  constraints: const BoxConstraints(maxHeight: 140),
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
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF6366F1),
                          backgroundColor: isDark ? const Color(0xFF1E2235) : Colors.grey.shade200,
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
              'Ore Settimanali: $_weeklyHours ore',
              style: TextStyle(color: subtitleColor, fontSize: 14),
            ),
            Slider(
              value: _weeklyHours.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              activeColor: const Color(0xFF6366F1),
              inactiveColor: isDark ? Colors.white12 : Colors.black12,
              onChanged: (val) => setState(() => _weeklyHours = val.toInt()),
            ),
            const Spacer(),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _addAssignment,
              child: Text(
                'Assegna Cattedre',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) itemAsString,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dropdownBgColor = isDark ? const Color(0xFF1E2235) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.black.withOpacity(0.06);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final fieldBgColor = isDark ? const Color(0xFF2E334D).withOpacity(0.4) : const Color(0xFFF1F5F9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(color: subtitleColor, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: fieldBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              onChanged: onChanged,
              dropdownColor: dropdownBgColor,
              icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white54 : Colors.black54),
              isExpanded: true,
              items: items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemAsString(item),
                    style: TextStyle(color: textColor),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentsListCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2235).withOpacity(0.8) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final mutedColor = isDark ? Colors.white38 : Colors.black38;

    // Grouping by Class Name
    final Map<String, List<Assignment>> grouped = {};
    for (final a in _assignments) {
      final className = a.schoolClass?.name ?? 'Senza Classe';
      grouped.putIfAbsent(className, () => []).add(a);
    }
    final sortedClassNames = grouped.keys.toList()..sort();
    
    final List<dynamic> listItems = [];
    for (final className in sortedClassNames) {
      listItems.add(className); // Header
      listItems.addAll(grouped[className]!); // Assignment row
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: !isDark ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Cattedre Assegnate',
              style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Divider(color: borderColor, height: 1),
          
          Expanded(
            child: _assignments.isEmpty
                ? Center(
                    child: Text(
                      'Nessuna cattedra assegnata',
                      style: TextStyle(color: mutedColor),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: listItems.length,
                    itemBuilder: (context, index) {
                      final item = listItems[index];
                      
                      if (item is String) {
                        // Render Class Header
                        return Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8, left: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.meeting_room_outlined, size: 16, color: Color(0xFF6366F1)),
                              const SizedBox(width: 8),
                              Text(
                                'Classe $item',
                                style: TextStyle(
                                  color: const Color(0xFF6366F1),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final a = item as Assignment;
                      final rowBgColor = isDark ? const Color(0xFF2E334D).withOpacity(0.2) : const Color(0xFFF1F5F9);
                      final rowBorderColor = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04);
                      final badgeBgColor = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04);

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                        a.subject?.name ?? 'Materia',
                                        style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Docente: ${a.teacher?.fullName ?? 'Sconosciuto'}',
                                    style: TextStyle(color: subtitleColor, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: badgeBgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${a.weeklyHours}h/sett',
                                style: TextStyle(color: subtitleColor, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
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
