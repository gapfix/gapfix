import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../models/subject_model.dart';

class TutorSubjectsScreen extends ConsumerStatefulWidget {
  const TutorSubjectsScreen({super.key});

  @override
  ConsumerState<TutorSubjectsScreen> createState() => _TutorSubjectsScreenState();
}

class _TutorSubjectsScreenState extends ConsumerState<TutorSubjectsScreen> {
  final List<String> _allSubjects = [];
  final List<SubjectModel> _mySubjects = [];
  String? _selectedSubject;
  String _currency = 'USD';
  String? _teachMode;
  
  final _priceController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final ref = FirebaseDatabase.instance.ref('Subjects');
    final snapshot = await ref.get();
    if (snapshot.exists) {
      final data = snapshot.value;
      if (data is List) {
        setState(() {
          _allSubjects.addAll(data.whereType<String>());
          _allSubjects.sort();
          _isLoading = false;
        });
      } else if (data is Map) {
         setState(() {
          data.forEach((key, value) {
            if (value is String) {
              _allSubjects.add(value);
            } else if (value is Map) {
              _allSubjects.add(value['en'] ?? key);
            }
          });
          _allSubjects.sort();
          _isLoading = false;
        });
      }
    }
  }

  void _addSubject() {
    if (_selectedSubject == null || _priceController.text.isEmpty || _durationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final price = double.tryParse(_priceController.text);
    final duration = int.tryParse(_durationController.text);

    if (price == null || price <= 0 || duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid price or duration')));
      return;
    }

    setState(() {
      _mySubjects.add(SubjectModel(
        name: _selectedSubject!,
        price: price,
        currency: _currency,
        duration: duration,
      ));
      _selectedSubject = null;
      _priceController.clear();
      _durationController.text = '60';
    });
  }

  Future<void> _save() async {
    if (_mySubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one subject')));
      return;
    }
    if (_teachMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a teaching mode')));
      return;
    }

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user != null) {
      final dbRef = FirebaseDatabase.instance.ref('Users/Tutor/${user.uid}');
      await dbRef.update({
        'preferences': _mySubjects.map((s) => s.toMap()).toList(),
        'teachMode': _teachMode,
        'earnedMoney': 0,
        'lessonsCount': 0,
      });
      if (mounted) context.go('/add-certificates');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutor Profile Setup')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  Card(
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Set Your Rates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedSubject,
                            hint: const Text('Select Subject'),
                            items: _allSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) => setState(() => _selectedSubject = v),
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: 'Price', labelText: 'Price'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _currency,
                                  items: ['USD', 'AMD', 'EUR'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  onChanged: (v) => setState(() => _currency = v!),
                                  decoration: const InputDecoration(hintText: 'Curr'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _durationController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: 'Mins', labelText: 'Mins'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _addSubject, child: const Text('ADD TO LIST')),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(alignment: Alignment.centerLeft, child: Text('MY TEACHING LIST', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _mySubjects.length,
                    itemBuilder: (context, index) {
                      final s = _mySubjects[index];
                      return ListTile(
                        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${s.price} ${s.currency} / ${s.duration} mins'),
                        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _mySubjects.removeAt(index))),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('How do you want to teach?', style: TextStyle(color: AppTheme.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                  RadioListTile<String>.adaptive(
                    title: const Text('Online'),
                    value: 'Online',
                    groupValue: _teachMode,
                    activeColor: AppTheme.primary,
                    onChanged: (v) => setState(() => _teachMode = v),
                  ),
                  RadioListTile<String>.adaptive(
                    title: const Text('In-Person (Offline)'),
                    value: 'Offline',
                    groupValue: _teachMode,
                    activeColor: AppTheme.primary,
                    onChanged: (v) => setState(() => _teachMode = v),
                  ),
                  RadioListTile<String>.adaptive(
                    title: const Text('Both'),
                    value: 'Both',
                    groupValue: _teachMode,
                    activeColor: AppTheme.primary,
                    onChanged: (v) => setState(() => _teachMode = v),
                  ),
                ],
              ),
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _save,
          child: const Text('CONFIRM AND SAVE ALL'),
        ),
      ),
    );
  }
}
