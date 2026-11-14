import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/toast_utils.dart';
import '../../models/subject_model.dart';

/// Port of Android TutorSubjectFragment (+ TutorSubjectAdapter): the tutor
/// edits the subjects they teach (name, price, currency, duration). Saving
/// replaces Users/Tutor/<uid>/preferences, same as Android.
class TutorSubjectManagementScreen extends ConsumerStatefulWidget {
  const TutorSubjectManagementScreen({super.key});

  @override
  ConsumerState<TutorSubjectManagementScreen> createState() =>
      _TutorSubjectManagementScreenState();
}

class _TutorSubjectManagementScreenState
    extends ConsumerState<TutorSubjectManagementScreen> {
  static const _currencies = ['USD', 'AMD', 'EUR'];

  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  final List<SubjectModel> _subjects = [];
  // canonical (English) name -> name in the current language, and back.
  final Map<String, String> _canonicalToTranslated = {};
  final Map<String, String> _translatedToCanonical = {};
  List<String> _available = [];

  String? _selectedSubject; // translated name shown in the dropdown
  String _currency = 'USD';
  bool _loading = true;
  bool _saving = false;
  String? _loadedLang;

  DatabaseReference? get _tutorRef {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    return uid == null
        ? null
        : ref.read(databaseProvider).ref('Users/Tutor/$uid');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (_loadedLang != lang) {
      _loadedLang = lang;
      _loadAvailableSubjects(lang);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentSubjects();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  /// Port of loadAvailableSubjectsFromFirebase: /Subjects entries are either
  /// plain strings or {en, ru, hy, ...} translation maps.
  Future<void> _loadAvailableSubjects(String lang) async {
    final snapshot = await ref.read(databaseProvider).ref('Subjects').get();
    if (!mounted) return;
    final available = <String>[];
    _canonicalToTranslated.clear();
    _translatedToCanonical.clear();
    for (final child in snapshot.children) {
      final value = child.value;
      String? canonical;
      String? translated;
      if (value is String) {
        canonical = value;
        translated = value;
      } else if (value is Map) {
        canonical = value['en'] as String?;
        translated = (value[lang] as String?) ?? canonical;
      }
      if (canonical != null && translated != null) {
        available.add(translated);
        _canonicalToTranslated[canonical] = translated;
        _translatedToCanonical[translated] = canonical;
      }
    }
    available.sort();
    setState(() {
      _available = available;
      if (!available.contains(_selectedSubject)) _selectedSubject = null;
    });
  }

  Future<void> _loadCurrentSubjects() async {
    final tutorRef = _tutorRef;
    if (tutorRef == null) {
      setState(() => _loading = false);
      return;
    }
    final snapshot = await tutorRef.child('preferences').get();
    if (!mounted) return;
    final loaded = <SubjectModel>[];
    for (final child in snapshot.children) {
      if (child.value is Map) {
        loaded.add(SubjectModel.fromMap(child.value as Map));
      }
    }
    setState(() {
      _subjects
        ..clear()
        ..addAll(loaded);
      _loading = false;
    });
  }

  void _addSubject() {
    final sub = _selectedSubject;
    final priceStr = _priceController.text.trim();
    final durationStr = _durationController.text.trim();
    if (sub == null || sub.isEmpty || priceStr.isEmpty || durationStr.isEmpty) {
      ToastUtils.show(
          context, 'Please fill all fields (Subject, Price, Duration)',
          isError: true);
      return;
    }
    final price = double.tryParse(priceStr);
    final duration = int.tryParse(durationStr);
    if (price == null || duration == null) {
      ToastUtils.show(context, 'Invalid number format', isError: true);
      return;
    }
    final canonical = _translatedToCanonical[sub] ?? sub;
    setState(() {
      _subjects.add(SubjectModel(
        name: canonical,
        price: price,
        currency: _currency,
        duration: duration,
      ));
      _selectedSubject = null;
      _priceController.clear();
      _durationController.clear();
    });
  }

  Future<void> _saveAll() async {
    final tutorRef = _tutorRef;
    if (tutorRef == null || _subjects.isEmpty) {
      ToastUtils.show(context, 'Please add at least one subject',
          isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await tutorRef
          .child('preferences')
          .set(_subjects.map((s) => s.toMap()).toList());
      if (!mounted) return;
      ToastUtils.show(context, 'Subjects saved successfully!');
    } catch (_) {
      if (!mounted) return;
      ToastUtils.show(context, 'Failed to save subjects', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Subjects')),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedSubject,
                  key: ValueKey('subject-${_available.length}-$_selectedSubject'),
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  items: _available
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSubject = v),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(labelText: 'Price'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _currency,
                        decoration:
                            const InputDecoration(labelText: 'Currency'),
                        items: _currencies
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _currency = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Duration (minutes)'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _addSubject,
                  icon: const Icon(Icons.add),
                  label: const Text('ADD SUBJECT'),
                ),
                const SizedBox(height: 24),
                for (var i = 0; i < _subjects.length; i++)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        _canonicalToTranslated[_subjects[i].name] ??
                            _subjects[i].name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                          '${_subjects[i].currency} '
                          '${_subjects[i].price.toStringAsFixed(0)} / '
                          '${_subjects[i].duration} mins'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () =>
                            setState(() => _subjects.removeAt(i)),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: _saving
                      ? const Center(child: CircularProgressIndicator())
                      : OutlinedButton(
                          onPressed: _saveAll,
                          style: OutlinedButton.styleFrom(
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero),
                            side: const BorderSide(
                                color: AppTheme.primary, width: 2),
                          ),
                          child: const Text('SAVE ALL',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                ),
              ],
            ),
    );
  }
}
