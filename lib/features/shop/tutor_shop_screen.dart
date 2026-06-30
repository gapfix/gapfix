import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gapfix/models/tutor_model.dart';
import 'package:gapfix/features/shop/widgets/tutor_card.dart';
import 'package:gapfix/features/shop/widgets/tutor_filter_sheet.dart';
import 'package:gapfix/features/shop/tutor_profile_screen.dart';

class TutorShopScreen extends StatefulWidget {
  const TutorShopScreen({super.key});

  @override
  State<TutorShopScreen> createState() => _TutorShopScreenState();
}

class _TutorShopScreenState extends State<TutorShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<TutorModel> _allTutors = [];
  List<TutorModel> _filteredTutors = [];
  
  List<String> _studentPreferredSubjects = [];
  List<String> _filterSelectedSubjects = [];
  
  double _minPrice = 0;
  double _maxPrice = 200;
  String _searchQuery = "";
  
  bool _isLoading = true;
  StreamSubscription? _tutorsSub;

  @override
  void initState() {
    super.initState();
    _loadStudentPreferences();
    _fetchTutors();
  }

  @override
  void dispose() {
    _tutorsSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('Users/Student/${user.uid}/preferences')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final prefs = (snapshot.value as List).whereType<String>().toList();
        setState(() {
          _studentPreferredSubjects = prefs;
          _filterSelectedSubjects = List.from(prefs);
        });
      }
    } catch (e) {
      debugPrint("Error loading preferences: $e");
    }
  }

  void _fetchTutors() {
    _tutorsSub = FirebaseDatabase.instance
        .ref('Users/Tutor')
        .onValue
        .listen((event) {
      final List<TutorModel> loadedTutors = [];
      try {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          data.forEach((key, value) {
            if (value is Map) {
              try {
                loadedTutors.add(TutorModel.fromMap(key.toString(), value));
              } catch (e) {
                debugPrint('Error parsing tutor $key: $e');
              }
            }
          });
        }
      } catch (e) {
        debugPrint('Error loading tutors: $e');
      }

      if (mounted) {
        setState(() {
          _allTutors = loadedTutors;
          _isLoading = false;
          _applyFilters();
        });
      }
    }, onError: (error) {
      debugPrint('Firebase error: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _applyFilters() {
    final queryLower = _searchQuery.toLowerCase().trim();
    
    setState(() {
      _filteredTutors = _allTutors.where((tutor) {
        // 1. Name Filter
        bool matchesName = true;
        if (queryLower.isNotEmpty) {
          matchesName = tutor.name.toLowerCase().contains(queryLower);
        }
        if (!matchesName) return false;

        // 2. Subject & Price Filter
        bool matchesFilters = false;
        if (_filterSelectedSubjects.isEmpty) {
          if (_studentPreferredSubjects.isEmpty) {
            matchesFilters = true;
          }
        } else {
          for (var pref in tutor.preferences) {
            if (_filterSelectedSubjects.contains(pref.name)) {
              if (pref.price >= _minPrice && pref.price <= _maxPrice) {
                matchesFilters = true;
                break;
              }
            }
          }
        }

        return matchesFilters;
      }).toList();
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TutorFilterSheet(
        currentMinPrice: _minPrice,
        currentMaxPrice: _maxPrice,
        availableSubjects: _studentPreferredSubjects,
        selectedSubjects: _filterSelectedSubjects,
        onApply: (minPrice, maxPrice, selectedSubjects) {
          setState(() {
            _minPrice = minPrice;
            _maxPrice = maxPrice;
            _filterSelectedSubjects = List.from(selectedSubjects);
            _applyFilters();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // Header / Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search tutors by name...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = "";
                                        _applyFilters();
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFD8DDD9)),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.tune, color: theme.primaryColor),
                          onPressed: _showFilterSheet,
                          tooltip: 'Filter',
                        ),
                      ),
                    ],
                  ),
                ),
                
                // List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator.adaptive())
                      : _filteredTutors.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No tutors found matching your criteria.',
                                    style: TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 100), // padding for bottom nav
                              itemCount: _filteredTutors.length,
                              itemBuilder: (context, index) {
                                final tutor = _filteredTutors[index];
                                return TutorCard(
                                  tutor: tutor,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TutorProfileScreen(tutor: tutor),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
