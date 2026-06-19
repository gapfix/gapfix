import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';

class StudentPreferencesScreen extends ConsumerStatefulWidget {
  const StudentPreferencesScreen({super.key});

  @override
  ConsumerState<StudentPreferencesScreen> createState() => _StudentPreferencesScreenState();
}

class _StudentPreferencesScreenState extends ConsumerState<StudentPreferencesScreen> {
  final List<String> _allSubjects = [];
  final List<String> _selectedSubjects = [];
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredSubjects = [];
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
          _filteredSubjects = List.from(_allSubjects);
          _isLoading = false;
        });
      } else if (data is Map) {
         // Handle map structure if needed (translations)
         setState(() {
          data.forEach((key, value) {
            if (value is String) _allSubjects.add(value);
            else if (value is Map) _allSubjects.add(value['en'] ?? key);
          });
          _allSubjects.sort();
          _filteredSubjects = List.from(_allSubjects);
          _isLoading = false;
        });
      }
    }
  }

  void _filterSubjects(String query) {
    setState(() {
      _filteredSubjects = _allSubjects
          .where((s) => s.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _toggleSubject(String subject) {
    setState(() {
      if (_selectedSubjects.contains(subject)) {
        _selectedSubjects.remove(subject);
      } else {
        _selectedSubjects.add(subject);
      }
    });
  }

  Future<void> _save() async {
    if (_selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one subject')),
      );
      return;
    }

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user != null) {
      final dbRef = FirebaseDatabase.instance.ref('Users/Student/${user.uid}');
      await dbRef.update({
        'preferences': _selectedSubjects,
        'isComplete': true,
      });
      if (mounted) context.go('/home'); // TODO: implement Home
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Interests'),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What would you like to learn?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select subjects that interest you to help us personalize your experience.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _searchController,
                    onChanged: _filterSubjects,
                    decoration: InputDecoration(
                      hintText: 'Search subjects...',
                      prefixIcon: const Icon(Icons.search),
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedSubjects.map((s) => Chip(
                      label: Text(s),
                      onDeleted: () => _toggleSubject(s),
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      labelStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                      deleteIconColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    )).toList(),
                  ),
                  const Divider(height: 32),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredSubjects.length,
                      itemBuilder: (context, index) {
                        final s = _filteredSubjects[index];
                        final isSelected = _selectedSubjects.contains(s);
                        return ListTile(
                          title: Text(s),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primary) : null,
                          onTap: () => _toggleSubject(s),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('CONTINUE'),
                  ),
                ],
              ),
            ),
    );
  }
}
