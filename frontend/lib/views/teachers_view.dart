import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

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
      _showError('Impossibile caricare i docenti: $e');
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
      final newTeacher = await ApiService.createTeacher(
        _firstNameController.text.trim(),
        _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
        _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      );
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _showSuccess('Docente aggiunto con successo!');
      _loadTeachers();
    } catch (e) {
      _showError('Errore durante la creazione del docente: $e');
    }
  }

  Future<void> _deleteTeacher(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: Text('Elimina Docente', style: TextStyle(color: Colors.white)),
        content: Text('Sei sicuro di voler eliminare questo docente? Le assegnazioni collegate verranno rimosse.', 
          style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annulla', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Elimina', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteTeacher(id);
        _showSuccess('Docente eliminato!');
        setState(() {
          _selectedTeacher = null;
        });
        _loadTeachers();
      } catch (e) {
        _showError('Impossibile eliminare il docente: $e');
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
      _showSuccess('Vincoli e impostazioni salvati con successo!');
      _loadTeachers();
    } catch (e) {
      _showError('Errore durante il salvataggio: $e');
    } finally {
      setState(() => _isLoading = false);
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
      body: _isLoading && _teachers.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  // Sidebar: Teachers list
                  Expanded(
                    flex: isDesktop ? 3 : 4,
                    child: _buildTeachersListCard(),
                  ),
                  
                  const SizedBox(width: 24),
                  
                  // Main area: Constraints and settings
                  Expanded(
                    flex: isDesktop ? 7 : 8,
                    child: _selectedTeacher == null
                        ? _buildNoTeacherSelectedView()
                        : _buildTeacherDetailsView(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTeachersListCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2235).withOpacity(0.8) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final mutedColor = isDark ? Colors.white38 : Colors.black38;

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
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Elenco Docenti',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _showAddTeacherDialog,
                  icon: const Icon(Icons.add_circle, color: Color(0xFF6366F1), size: 30),
                  tooltip: 'Aggiungi Docente',
                ),
              ],
            ),
          ),
          Divider(color: borderColor, height: 1),
          
          Expanded(
            child: _teachers.isEmpty
                ? Center(
                    child: Text(
                      'Nessun docente inserito',
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
                          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF6366F1).withOpacity(0.4) : Colors.transparent,
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
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF6366F1) : textColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            t.email ?? 'Senza email',
                            style: TextStyle(color: subtitleColor, fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2235).withOpacity(0.6) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);
    final mutedColor = isDark ? Colors.white24 : Colors.black26;
    final textColor = isDark ? Colors.white38 : Colors.black38;

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
        ] : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, color: mutedColor, size: 80),
            const SizedBox(height: 16),
            Text(
              'Seleziona o aggiungi un docente',
              style: TextStyle(color: textColor, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherDetailsView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTeacherHeaderCard(_selectedTeacher!),
          const SizedBox(height: 24),
          
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
          
          const SizedBox(height: 24),
          
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
              elevation: 8,
            ),
            onPressed: _saveTeacherSettings,
            child: Text(
              'Salva Vincoli ed Impostazioni',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherHeaderCard(Teacher teacher) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final headerSubtitleColor = isDark ? Colors.white70 : const Color(0xFF475569);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF6366F1).withOpacity(0.2), const Color(0xFF8B5CF6).withOpacity(0.1)]
              : [const Color(0xFF6366F1).withOpacity(0.08), const Color(0xFF8B5CF6).withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
            child: Text(
              teacher.firstName[0].toUpperCase(),
              style: TextStyle(color: const Color(0xFF6366F1), fontSize: 30, fontWeight: FontWeight.bold),
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
                teacher.email ?? 'Nessun indirizzo email configurato',
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
    final cardColor = isDark ? const Color(0xFF1E2235).withOpacity(0.8) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF475569);

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
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Limiti Orario',
            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Max Ore Consecutive: $_maxConsecutive',
            style: TextStyle(color: subtitleColor, fontSize: 14),
          ),
          Slider(
            value: _maxConsecutive.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            activeColor: const Color(0xFF6366F1),
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
            'Max Ore Giornaliere: $_maxDaily',
            style: TextStyle(color: subtitleColor, fontSize: 14),
          ),
          Slider(
            value: _maxDaily.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            activeColor: const Color(0xFF8B5CF6),
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
                color: isDarkInner ? const Color(0xFF2E334D).withOpacity(0.4) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  'Preferisce ore consecutive',
                  style: TextStyle(color: isDarkInner ? Colors.white : const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Il solver cercherà di raggruppare le ore del docente nello stesso giorno',
                  style: TextStyle(color: subtitleColorInner, fontSize: 12),
                ),
                value: _preferConsecutive,
                activeColor: const Color(0xFF6366F1),
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
    final giorniNomi = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2235).withOpacity(0.8) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final mutedColor = isDark ? Colors.white38 : Colors.black38;
    final gridLineColor = isDark ? Colors.white12 : Colors.black12;

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
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Fasce di Indisponibilità',
            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Clicca sulle ore in cui il docente NON è disponibile.',
            style: TextStyle(color: mutedColor, fontSize: 12),
          ),
          const SizedBox(height: 24),
          
          Table(
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          '${h + 1}° Ora',
                          style: TextStyle(color: subtitleColor, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    
                    ...List.generate(days, (d) {
                      final key = '$d-$h';
                      final isBusy = _busySlots.contains(key);
                      final cellBgColor = isDark ? const Color(0xFF2E334D).withOpacity(0.4) : const Color(0xFFF1F5F9);
                      final cellBorderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);

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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.all(4),
                            height: 35,
                            decoration: BoxDecoration(
                              color: isBusy 
                                  ? Colors.redAccent.withOpacity(0.2) 
                                  : cellBgColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isBusy 
                                    ? Colors.redAccent.withOpacity(0.8) 
                                    : cellBorderColor,
                                width: isBusy ? 1.5 : 1,
                              ),
                              boxShadow: isBusy ? [
                                BoxShadow(
                                  color: Colors.redAccent.withOpacity(0.15),
                                  blurRadius: 8,
                                )
                              ] : null,
                            ),
                            child: Center(
                              child: isBusy 
                                  ? const Icon(Icons.block, color: Colors.redAccent, size: 16) 
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
        ],
      ),
    );
  }

  void _showAddTeacherDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E2235) : Colors.white;
    final inputColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final labelColor = isDark ? Colors.white54 : Colors.black54;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Nuovo Docente',
          style: TextStyle(color: inputColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _firstNameController,
              style: TextStyle(color: inputColor),
              decoration: InputDecoration(
                labelText: 'Nome *',
                labelStyle: TextStyle(color: labelColor),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black26)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              style: TextStyle(color: inputColor),
              decoration: InputDecoration(
                labelText: 'Cognome (opzionale)',
                labelStyle: TextStyle(color: labelColor),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black26)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: inputColor),
              decoration: InputDecoration(
                labelText: 'Email (opzionale)',
                labelStyle: TextStyle(color: labelColor),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black26)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
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
            child: Text('Annulla', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: () {
              Navigator.pop(context);
              _addTeacher();
            },
            child: Text('Salva', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
