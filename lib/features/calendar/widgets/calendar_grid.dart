import 'package:flutter/material.dart';

class CalendarGrid extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final Set<String> activeDates; // Dates with bookings/homework in "YYYY-M-D" format
  final ValueChanged<DateTime> onDateSelected;

  const CalendarGrid({
    super.key,
    required this.currentMonth,
    required this.selectedDate,
    required this.activeDates,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final days = _generateDays();
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildDaysOfWeek(theme),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 42,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final day = days[index];
            final isCurrentMonth = day.month == currentMonth.month;
            final isSelected = _isSameDay(day, selectedDate);
            final dateKey = '${day.year}-${day.month}-${day.day}';
            final hasEvents = activeDates.contains(dateKey);

            Color bgColor = Colors.transparent;
            Color textColor = theme.colorScheme.onSurface;
            FontWeight fontWeight = FontWeight.normal;

            if (isSelected) {
              bgColor = const Color(0xFF00C853); // A specific nice green color matching Android
              textColor = Colors.white;
              fontWeight = FontWeight.bold;
            } else {
              // No background color for just having events
              bgColor = Colors.transparent;
            }

            if (!isCurrentMonth) {
              textColor = textColor.withValues(alpha: 0.3);
            }

            return GestureDetector(
              onTap: () => onDateSelected(day),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle, // Using circle shape instead of rounded rect for the selected indicator
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: fontWeight,
                        fontSize: 14,
                      ),
                    ),
                    if (hasEvents && !isSelected) // Show dot if it has events and isn't selected
                      Positioned(
                        bottom: 4,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00C853),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDaysOfWeek(ThemeData theme) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days
            .map((day) => Text(
                  day,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ))
            .toList(),
      ),
    );
  }

  List<DateTime> _generateDays() {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    // In Dart, weekday is 1 (Mon) to 7 (Sun). We want 0 (Sun) to 6 (Sat)
    final firstDayOfWeek = firstDayOfMonth.weekday % 7; 
    
    final days = <DateTime>[];
    // Subtract daysBefore to start on Sunday
    var current = firstDayOfMonth.subtract(Duration(days: firstDayOfWeek));

    for (int i = 0; i < 42; i++) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
