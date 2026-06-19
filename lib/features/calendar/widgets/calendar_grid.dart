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

    return Column(
      children: [
        _buildDaysOfWeek(),
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
            final isToday = _isSameDay(day, DateTime.now());
            final dateKey = '${day.year}-${day.month}-${day.day}';
            final hasEvents = activeDates.contains(dateKey);

            return GestureDetector(
              onTap: () => onDateSelected(day),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : isToday
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isCurrentMonth
                                ? (isToday ? Theme.of(context).primaryColor : Colors.black87)
                                : Colors.grey,
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (hasEvents && !isSelected)
                      Positioned(
                        bottom: 6,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
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

  Widget _buildDaysOfWeek() {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days
            .map((day) => Text(
                  day,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
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
