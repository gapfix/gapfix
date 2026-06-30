import 'package:flutter/material.dart';
import 'package:gapfix/core/theme.dart';

class TutorFilterSheet extends StatefulWidget {
  final double currentMinPrice;
  final double currentMaxPrice;
  final List<String> availableSubjects;
  final List<String> selectedSubjects;
  final Function(double minPrice, double maxPrice, List<String> selectedSubjects) onApply;

  const TutorFilterSheet({
    super.key,
    required this.currentMinPrice,
    required this.currentMaxPrice,
    required this.availableSubjects,
    required this.selectedSubjects,
    required this.onApply,
  });

  @override
  State<TutorFilterSheet> createState() => _TutorFilterSheetState();
}

class _TutorFilterSheetState extends State<TutorFilterSheet> {
  late double _minPrice;
  late double _maxPrice;
  final List<String> _selectedSubjects = [];

  @override
  void initState() {
    super.initState();
    _minPrice = widget.currentMinPrice;
    _maxPrice = widget.currentMaxPrice;
    _selectedSubjects.addAll(widget.selectedSubjects);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = isDark ? AppTheme.textLight : AppTheme.textDark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Filter Tutors',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),

          // Price Range Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price Range (Hourly)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                '\$${_minPrice.toInt()} - \$${_maxPrice.toInt()}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: 200,
            divisions: 40,
            activeColor: primaryColor,
            inactiveColor: primaryColor.withValues(alpha: 0.2),
            labels: RangeLabels('\$${_minPrice.toInt()}', '\$${_maxPrice.toInt()}'),
            onChanged: (RangeValues values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),
          
          const SizedBox(height: 24),

          // Subjects Section
          Text(
            'Subjects',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.availableSubjects.isEmpty)
            Text(
              'You have no preferred subjects set.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: widget.availableSubjects.map((subject) {
                final isSelected = _selectedSubjects.contains(subject);
                return FilterChip(
                  label: Text(subject),
                  selected: isSelected,
                  selectedColor: primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: primaryColor,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  labelStyle: TextStyle(
                    color: isSelected ? primaryColor : textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? primaryColor : Colors.transparent,
                    ),
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedSubjects.add(subject);
                      } else {
                        _selectedSubjects.remove(subject);
                      }
                    });
                  },
                );
              }).toList(),
            ),

          const SizedBox(height: 40),
          SafeArea(
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_minPrice, _maxPrice, _selectedSubjects);
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
