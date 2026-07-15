import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

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
      _showError('Impossibile caricare i dati dei filtri: $e');
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
      _showError('Impossibile caricare l\'orario: $e');
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
        _showSuccess('Orario generato con successo!');
        _loadTimetable();
      } else {
        setState(() {
          _genErrorTitle = response.message;
          _genErrorDetails = response.errorDetails;
        });
      }
    } catch (e) {
      _showError('Errore durante la generazione dell\'orario: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _clearTimetable() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: Text('Cancella Orario', style: TextStyle(color: Colors.white)),
        content: Text('Sei sicuro di voler cancellare l\'orario generato? Dovrai rigenerarlo.', 
          style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annulla', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cancella', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ApiService.clearTimetable();
        _showSuccess('Orario cancellato!');
        _loadTimetable();
      } catch (e) {
        _showError('Impossibile cancellare l\'orario: $e');
      } finally {
        setState(() => _isLoading = false);
      }
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

  Future<void> _saveTimetable() async {
    if (_slots.isEmpty) {
      _showError('Nessun orario da salvare. Genera prima un orario.');
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final bgColor = isDark ? const Color(0xFF1E2235) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);
    final fieldBg = isDark ? const Color(0xFF2E334D) : const Color(0xFFF1F5F9);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Salva Orario', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20)),
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
                  labelText: 'Nome (es. Orario I Semestre)',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.5), fontSize: 13),
                  filled: true,
                  fillColor: fieldBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: TextStyle(color: textColor),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Commento (opzionale)',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.5), fontSize: 13),
                  filled: true,
                  fillColor: fieldBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annulla', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Salva', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result == true) {
      final name = nameController.text.trim();
      if (name.isEmpty) {
        _showError('Inserisci un nome per l\'orario.');
        return;
      }
      try {
        await ApiService.saveTimetable(
          name: name,
          description: descController.text.trim().isEmpty ? null : descController.text.trim(),
          slots: _slots,
          daysPerWeek: widget.schoolSettings.daysPerWeek,
          hoursPerDay: widget.schoolSettings.hoursPerDay,
        );
        _showSuccess('Orario "$name" salvato con successo!');
      } catch (e) {
        _showError('Errore durante il salvataggio: $e');
      }
    }
  }

  Future<void> _showHistory() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final bgColor = isDark ? const Color(0xFF1E2235) : Colors.white;
    final subtitleColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final rowBg = isDark ? const Color(0xFF2E334D).withOpacity(0.5) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05);

    List<SavedTimetable> timetables;
    try {
      timetables = await ApiService.getSavedTimetables();
    } catch (e) {
      _showError('Impossibile caricare lo storico: $e');
      return;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) => AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Storico Orari', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20)),
          content: SizedBox(
            width: 520,
            height: 380,
            child: timetables.isEmpty
                ? Center(
                    child: Text('Nessun orario salvato.', style: TextStyle(color: subtitleColor)),
                  )
                : ListView.builder(
                    itemCount: timetables.length,
                    itemBuilder: (_, i) {
                      final st = timetables[i];
                      final dateStr = '${st.createdAt.day.toString().padLeft(2, '0')}/${st.createdAt.month.toString().padLeft(2, '0')}/${st.createdAt.year}';
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                  Text(st.name, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(dateStr, style: TextStyle(color: const Color(0xFF6366F1), fontSize: 12)),
                                  if (st.description != null && st.description!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(st.description!, style: TextStyle(color: subtitleColor, fontSize: 12)),
                                  ],
                                ],
                              ),
                            ),
                            // Restore button
                            Tooltip(
                              message: 'Ripristina come orario attivo',
                              child: IconButton(
                                icon: const Icon(Icons.restore, color: Color(0xFF10B981)),
                                onPressed: () async {
                                  try {
                                    await ApiService.restoreSavedTimetable(st.id);
                                    Navigator.pop(ctx);
                                    _loadTimetable();
                                    _showSuccess('Orario "${st.name}" ripristinato!');
                                  } catch (e) {
                                    _showError('Errore nel ripristino: $e');
                                  }
                                },
                              ),
                            ),
                            // Delete button
                            Tooltip(
                              message: 'Elimina orario salvato',
                              child: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () async {
                                  try {
                                    await ApiService.deleteSavedTimetable(st.id);
                                    setStateDialog(() => timetables.removeAt(i));
                                    _showSuccess('Orario eliminato.');
                                  } catch (e) {
                                    _showError('Errore nell\'eliminazione: $e');
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
              child: Text('Chiudi', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
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
    final giorniNomi = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab'];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Toolbar: Action Buttons & Filter Selection
                  _buildTopToolbar(),
                  const SizedBox(height: 24),
                  
                  // Diagnostic Error box if solve failed
                  if (_genErrorTitle != null) ...[
                    _buildDiagnosticErrorBox(),
                    const SizedBox(height: 24),
                  ],

                  // Main Timetable Grid Card
                  Expanded(
                    child: _isGenerating
                        ? _buildGeneratingSpinner()
                        : _buildTimetableGrid(days, hours, giorniNomi),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTopToolbar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2235).withOpacity(0.8) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);
    final fieldBgColor = isDark ? const Color(0xFF2E334D).withOpacity(0.4) : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: fieldBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildToggleButton(label: 'Per Classe', active: _filterType == 'class', onTap: () {
                  setState(() {
                    _filterType = 'class';
                    if (_classes.isNotEmpty) _selectedFilterId = _classes.first.id;
                    else _selectedFilterId = null;
                  });
                  _loadTimetable();
                }),
                _buildToggleButton(label: 'Per Docente', active: _filterType == 'teacher', onTap: () {
                  setState(() {
                    _filterType = 'teacher';
                    if (_teachers.isNotEmpty) _selectedFilterId = _teachers.first.id;
                    else _selectedFilterId = null;
                  });
                  _loadTimetable();
                }),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          if (_filterType == 'class')
            _buildToolbarDropdown<SchoolClass>(
              value: _classes.any((c) => c.id == _selectedFilterId)
                  ? _classes.firstWhere((c) => c.id == _selectedFilterId)
                  : null,
              items: _classes,
              onChanged: (val) {
                setState(() => _selectedFilterId = val?.id);
                _loadTimetable();
              },
              itemAsString: (c) => c.name,
            )
          else
            _buildToolbarDropdown<Teacher>(
              value: _teachers.any((t) => t.id == _selectedFilterId)
                  ? _teachers.firstWhere((t) => t.id == _selectedFilterId)
                  : null,
              items: _teachers,
              onChanged: (val) {
                setState(() => _selectedFilterId = val?.id);
                _loadTimetable();
              },
              itemAsString: (t) => t.fullName,
            ),
            
          const Spacer(),

          // History button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              side: const BorderSide(color: Color(0xFF6366F1)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _showHistory,
            icon: const Icon(Icons.history),
            label: Text('Storico', style: TextStyle(fontWeight: FontWeight.bold)),
          ),

          const SizedBox(width: 12),

          // Save current timetable button (only when slots are present)
          if (_slots.isNotEmpty) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
                side: const BorderSide(color: Color(0xFF10B981)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveTimetable,
              icon: const Icon(Icons.save_outlined),
              label: Text('Salva Orario', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
          ],

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _clearTimetable,
            icon: const Icon(Icons.delete_sweep_outlined),
            label: Text('Cancella Orario', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          
          const SizedBox(width: 12),
          
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
              elevation: 4,
            ),
            onPressed: _isGenerating ? null : _generateTimetable,
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.autorenew),
            label: Text(
              _isGenerating ? 'Generazione...' : 'Genera Orario', 
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({required String label, required bool active, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarDropdown<T>({
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) itemAsString,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dropdownBgColor = isDark ? const Color(0xFF1E2235) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.black.withOpacity(0.06);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final fieldBgColor = isDark ? const Color(0xFF2E334D).withOpacity(0.4) : const Color(0xFFF1F5F9);

    return Container(
      width: 220,
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
          hint: Text('Seleziona...', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)),
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
    );
  }

  Widget _buildDiagnosticErrorBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _genErrorTitle ?? 'Generazione fallita',
                  style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  _genErrorDetails ?? 'Controlla che i vincoli orari o il carico orario complessivo non siano impossibili da soddisfare.',
                  style: TextStyle(color: Colors.red.shade900, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGeneratingSpinner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 5),
          ),
          const SizedBox(height: 24),
          Text(
            'Risoluzione del problema combinatorio...',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'OR-Tools sta calcolando il miglior orario che soddisfa tutti i vincoli.',
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableGrid(int days, int hours, List<String> giorniNomi) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2235).withOpacity(0.8) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final mutedColor = isDark ? Colors.white38 : Colors.black38;
    final tableHeaderBg = isDark ? const Color(0xFF2E334D).withOpacity(0.2) : const Color(0xFFF1F5F9);

    if (_selectedFilterId == null) {
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
          child: Text(
            'Seleziona una classe o un docente per visualizzare l\'orario',
            style: TextStyle(color: mutedColor, fontSize: 16),
          ),
        ),
      );
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _filterType == 'class' 
                    ? 'Orario delle lezioni' 
                    : 'Orario di servizio docente',
                style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Settimana scolastica di ${widget.schoolSettings.daysPerWeek} giorni',
                style: TextStyle(color: subtitleColor, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), width: 0.5),
                columnWidths: const {
                  0: FixedColumnWidth(80),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: tableHeaderBg,
                    ),
                    children: [
                      const TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(),
                        ),
                      ),
                      ...List.generate(days, (d) => TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            giorniNomi[d],
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24.0),
                              child: Text(
                                '${h + 1}° Ora',
                                style: TextStyle(color: subtitleColor, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        ...List.generate(days, (d) {
                          final slot = _slots.firstWhere(
                            (s) => s.day == d && s.hour == h,
                            orElse: () => TimetableSlot(
                              id: -1, day: d, hour: h, classId: -1, teacherId: -1, subjectId: -1,
                              schoolClass: SchoolClass(id: -1, name: ''),
                              teacher: Teacher(id: -1, firstName: ''),
                              subject: Subject(id: -1, name: ''),
                            ),
                          );

                          final isAssigned = slot.id != -1;
                          
                          return TableCell(
                            child: Container(
                              height: 80,
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isAssigned
                                    ? const Color(0xFF6366F1).withOpacity(0.08)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isAssigned
                                      ? const Color(0xFF6366F1).withOpacity(0.3)
                                      : (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)),
                                  width: isAssigned ? 1.5 : 0.5,
                                ),
                              ),
                              child: isAssigned
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          slot.subject.name,
                                          style: TextStyle(
                                            color: isDark ? Colors.white : const Color(0xFF6366F1), 
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _filterType == 'class'
                                              ? slot.teacher.fullName
                                              : 'Classe ${slot.schoolClass.name}',
                                          style: TextStyle(
                                            color: subtitleColor,
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    )
                                  : Center(
                                      child: Text(
                                        '-',
                                        style: TextStyle(color: mutedColor, fontSize: 16),
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
            ),
          ),
        ],
      ),
    );
  }
}
