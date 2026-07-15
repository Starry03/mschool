import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class DataManagementView extends StatefulWidget {
  const DataManagementView({super.key});

  @override
  State<DataManagementView> createState() => _DataManagementViewState();
}

class _DataManagementViewState extends State<DataManagementView> {
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

  // For subject detail editing (max consecutive hours)
  // State is managed locally within the dialog via StatefulBuilder

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
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
      _showError('Impossibile caricare le classi: $e');
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
      _showError('Impossibile caricare le materie: $e');
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
        // Aggiorna le selezioni dei dropdown se necessario
        if (_subjects.isNotEmpty && (_selectedSubjectConstraint == null || !_subjects.contains(_selectedSubjectConstraint))) {
          _selectedSubjectConstraint = _subjects.first;
        }
      });
    } catch (e) {
      _showError('Impossibile caricare i vincoli ore materia: $e');
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
      _showSuccess('Classe aggiunta!');
      await _loadClasses();
      await _loadConstraints();
    } catch (e) {
      _showError('Errore durante la creazione della classe: $e');
    }
  }

  Future<void> _addSubject() async {
    final name = _subjectController.text.trim();
    if (name.isEmpty) return;
    try {
      await ApiService.createSubject(name);
      _subjectController.clear();
      _showSuccess('Materia aggiunta!');
      await _loadSubjects();
      await _loadConstraints();
    } catch (e) {
      _showError('Errore durante la creazione della materia: $e');
    }
  }

  Future<void> _addConstraint() async {
    if (_selectedSubjectConstraint == null || _selectedClassIdsConstraint.isEmpty) {
      _showError('Seleziona la materia e almeno una classe prima di aggiungere il vincolo.');
      return;
    }
    
    try {
      int successCount = 0;
      for (final classId in _selectedClassIdsConstraint) {
        // Verifica se esiste già un vincolo per questa classe e materia
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
      _showSuccess('Aggiunti $successCount vincoli ore materia!');
      setState(() {
        _selectedClassIdsConstraint.clear();
      });
      _loadConstraints();
    } catch (e) {
      _showError('Errore durante l\'aggiunta del vincolo: $e');
    }
  }

  Future<void> _deleteClass(int id) async {
    try {
      await ApiService.deleteClass(id);
      _showSuccess('Classe eliminata!');
      _selectedClassIdsConstraint.remove(id);
      await _loadClasses();
      await _loadConstraints();
    } catch (e) {
      _showError('Errore durante la cancellazione della classe: $e');
    }
  }

  Future<void> _deleteSubject(int id) async {
    try {
      await ApiService.deleteSubject(id);
      _showSuccess('Materia eliminata!');
      if (_selectedSubjectConstraint?.id == id) {
        _selectedSubjectConstraint = null;
      }
      await _loadSubjects();
      await _loadConstraints();
    } catch (e) {
      _showError('Errore durante la cancellazione della materia: $e');
    }
  }

  Future<void> _openSubjectSettings(Subject subject) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final bgColor = isDark ? const Color(0xFF1E2235) : Colors.white;
    final subtitleColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final fieldBg = isDark ? const Color(0xFF2E334D) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05);

    int currentMax = subject.maxConsecutiveHours ?? 0; // 0 = nessun limite
    int dialogMax = currentMax;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) => AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            subject.name,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                        dialogMax == 0
                            ? 'Max ore consecutive: Nessun limite'
                            : 'Max ore consecutive: $dialogMax',
                        style: TextStyle(
                          color: subtitleColor, fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Slider(
                        value: dialogMax.toDouble(),
                        min: 0,
                        max: 6,
                        divisions: 6,
                        activeColor: const Color(0xFF6366F1),
                        inactiveColor: isDark ? Colors.white12 : Colors.black12,
                        label: dialogMax == 0 ? 'Nessun limite' : '$dialogMax',
                        onChanged: (val) => setStateDialog(() => dialogMax = val.toInt()),
                      ),
                      Text(
                        dialogMax == 0
                            ? 'Nessun vincolo di consecutività per questa materia'
                            : 'Massimo $dialogMax ${dialogMax == 1 ? "ora" : "ore"} consecutive per classe',
                        style: TextStyle(color: subtitleColor.withOpacity(0.7), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Annulla', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ApiService.updateSubject(
                    subject.id,
                    maxConsecutiveHours: dialogMax == 0 ? null : dialogMax,
                  );
                  await _loadSubjects();
                  _showSuccess('Vincolo aggiornato per ${subject.name}!');
                } catch (e) {
                  _showError('Errore: $e');
                }
              },
              child: Text('Salva', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteConstraint(int id) async {
    try {
      await ApiService.deleteClassSubjectConstraint(id);
      _showSuccess('Vincolo rimosso!');
      _loadConstraints();
    } catch (e) {
      _showError('Errore durante la rimozione del vincolo: $e');
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

  Widget _buildClassesPanel() {
    return _buildPanel(
      title: 'Classi',
      subtitle: 'Aggiungi e gestisci le classi della scuola (es: 1A, 2B)',
      controller: _classController,
      labelText: 'Nome Classe (es. 3C)',
      onAdd: _addClass,
      isLoading: _isLoadingClasses,
      itemsCount: _classes.length,
      itemBuilder: (context, index) {
        final c = _classes[index];
        return _buildItemRow(
          name: c.name,
          icon: Icons.meeting_room_outlined,
          onDelete: () => _deleteClass(c.id),
        );
      },
    );
  }

  Widget _buildSubjectsPanel() {
    return _buildPanel(
      title: 'Materie',
      subtitle: 'Aggiungi e gestisci le materie di insegnamento (es: Matematica)',
      controller: _subjectController,
      labelText: 'Nome Materia (es. Italiano)',
      onAdd: _addSubject,
      isLoading: _isLoadingSubjects,
      itemsCount: _subjects.length,
      itemBuilder: (context, index) {
        final s = _subjects[index];
        final hasLimit = s.maxConsecutiveHours != null;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return _buildItemRow(
          name: s.name,
          icon: Icons.book_outlined,
          onDelete: () => _deleteSubject(s.id),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasLimit)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                  ),
                  child: Text(
                    'max ${s.maxConsecutiveHours}h cons.',
                    style: TextStyle(
                      color: const Color(0xFF6366F1),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              IconButton(
                icon: Icon(
                  Icons.tune,
                  color: isDark ? Colors.white38 : Colors.black38,
                  size: 18,
                ),
                tooltip: 'Imposta ore consecutive max',
                onPressed: () => _openSubjectSettings(s),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConstraintsPanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2235).withOpacity(0.8) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final mutedColor = isDark ? Colors.white38 : Colors.black38;
    final fieldBgColor = isDark ? const Color(0xFF2E334D).withOpacity(0.4) : const Color(0xFFF1F5F9);

    // Grouping constraints by Class Name
    final Map<String, List<ClassSubjectConstraint>> grouped = {};
    for (final sc in _constraints) {
      final className = sc.schoolClass?.name ?? 'Senza Classe';
      grouped.putIfAbsent(className, () => []).add(sc);
    }
    final sortedClassNames = grouped.keys.toList()..sort();
    
    final List<dynamic> listItems = [];
    for (final className in sortedClassNames) {
      listItems.add(className); // Header
      listItems.addAll(grouped[className]!); // Constraint row
    }

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
            'Ore Materia',
            style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Imposta quante ore di una materia deve fare una classe',
            style: TextStyle(color: subtitleColor, fontSize: 13),
          ),
          const SizedBox(height: 24),
          
          if (_classes.isEmpty || _subjects.isEmpty) ...[
            Expanded(
              child: Center(
                child: Text(
                  'Aggiungi prima classi e materie',
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
                      'Classe',
                      style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
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
                          child: Text(
                            'Tutte',
                            style: TextStyle(fontSize: 12, color: const Color(0xFF6366F1), fontWeight: FontWeight.bold),
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
                          child: Text(
                            'Nessuna',
                            style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
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
                    border: Border.all(color: borderColor),
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
                          selectedColor: const Color(0xFF6366F1),
                          backgroundColor: isDark ? const Color(0xFF1E2235) : Colors.grey.shade200,
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
            _buildDropdownField<Subject>(
              label: 'Materia',
              value: _selectedSubjectConstraint,
              items: _subjects,
              onChanged: (val) => setState(() => _selectedSubjectConstraint = val),
              itemAsString: (s) => s.name,
              isDark: isDark,
              textColor: textColor,
              borderColor: borderColor,
              fieldBgColor: fieldBgColor,
              dropdownBgColor: isDark ? const Color(0xFF1E2235) : Colors.white,
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
                        'Ore: $_constraintHours h',
                        style: TextStyle(color: subtitleColor, fontSize: 13),
                      ),
                      Slider(
                        value: _constraintHours.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        activeColor: const Color(0xFF6366F1),
                        inactiveColor: isDark ? Colors.white12 : Colors.black12,
                        onChanged: (val) => setState(() => _constraintHours = val.toInt()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _addConstraint,
                  child: const Icon(Icons.add, color: Colors.white),
                )
              ],
            ),
            
            const SizedBox(height: 16),
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 12),
            
            // Constraints List
            Expanded(
              child: _isLoadingConstraints
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                  : _constraints.isEmpty
                      ? Center(
                          child: Text(
                            'Nessun vincolo impostato',
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
                            
                            final sc = item as ClassSubjectConstraint;
                            final rowBgColor = isDark ? const Color(0xFF2E334D).withOpacity(0.2) : const Color(0xFFF1F5F9);
                            final rowBorderColor = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04);
                            
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
                                      sc.subject?.name ?? "Materia",
                                      style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${sc.weeklyHours}h',
                                      style: TextStyle(color: const Color(0xFF6366F1), fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
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

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) itemAsString,
    required bool isDark,
    required Color textColor,
    required Color borderColor,
    required Color fieldBgColor,
    required Color dropdownBgColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1000;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: isDesktop
            ? Row(
                children: [
                  Expanded(child: _buildClassesPanel()),
                  const SizedBox(width: 24),
                  Expanded(child: _buildSubjectsPanel()),
                  const SizedBox(width: 24),
                  Expanded(child: _buildConstraintsPanel()),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 400, child: _buildClassesPanel()),
                    const SizedBox(height: 24),
                    SizedBox(height: 400, child: _buildSubjectsPanel()),
                    const SizedBox(height: 24),
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
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onAdd,
                child: const Icon(Icons.add, color: Colors.white),
              )
            ],
          ),
          
          const SizedBox(height: 24),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 12),
          
          // List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : itemsCount == 0
                    ? Center(
                        child: Text(
                          'Nessun elemento presente',
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
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowBgColor = isDark ? const Color(0xFF2E334D).withOpacity(0.2) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: rowBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6366F1).withOpacity(0.8), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: TextStyle(color: textColor, fontSize: 16),
            ),
          ),
          if (trailing != null) trailing,
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
