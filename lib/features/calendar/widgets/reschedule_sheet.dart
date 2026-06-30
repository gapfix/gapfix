import 'package:flutter/material.dart';
import 'package:gapfix/models/booking_model.dart';
import 'package:gapfix/core/adaptive_utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class RescheduleSheet extends StatefulWidget {
  final BookingModel booking;
  final List<BookingModel> allBookings;
  final bool isStudent;

  const RescheduleSheet({
    super.key,
    required this.booking,
    required this.allBookings,
    required this.isStudent,
  });

  @override
  State<RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<RescheduleSheet> {
  late bool _isPackage;
  bool _isPatternChange = true;
  BookingModel? _selectedLesson;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  String? _sourceDay;
  String? _destDay;
  
  final TextEditingController _messageController = TextEditingController();

  final List<String> _daysOfWeek = [
    'Mondays', 'Tuesdays', 'Wednesdays', 'Thursdays', 'Fridays', 'Saturdays', 'Sundays'
  ];
  List<String> _sourceDaysOfWeek = [];

  @override
  void initState() {
    super.initState();
    _isPackage = widget.booking.isPackage && widget.booking.packageId != null;
    _selectedLesson = widget.booking;
    
    if (_isPackage) {
      final dt = DateTime.fromMillisecondsSinceEpoch(widget.booking.timestamp);
      _sourceDay = '${DateFormat('EEEE').format(dt)}s';
      _destDay = _sourceDay;
      
      final lessons = widget.allBookings
          .where((b) => b.isPackage && b.packageId == widget.booking.packageId)
          .toList();
      final Set<String> pDays = {};
      for (var l in lessons) {
        final lDt = DateTime.fromMillisecondsSinceEpoch(l.timestamp);
        pDays.add('${DateFormat('EEEE').format(lDt)}s');
      }
      _sourceDaysOfWeek = pDays.toList();
      if (_sourceDaysOfWeek.isEmpty) {
        _sourceDaysOfWeek = _daysOfWeek;
      }
    }
    
    final dt = DateTime.fromMillisecondsSinceEpoch(widget.booking.timestamp);
    _selectedDate = dt;
    _selectedTime = TimeOfDay.fromDateTime(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reschedule Session', style: theme.textTheme.h4),
            const SizedBox(height: 4),
            Text(
              _isPackage 
                ? 'Propose a new schedule for this package' 
                : 'Choose a new date and time for this lesson',
              style: theme.textTheme.muted,
            ),
            const SizedBox(height: 16),
            
            // Info Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  ShadAvatar(
                    '',
                    placeholder: Text(
                      (widget.isStudent 
                          ? (widget.booking.tutorName ?? 'U') 
                          : (widget.booking.studentName ?? 'U'))[0],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isStudent ? (widget.booking.tutorName ?? 'Tutor') : (widget.booking.studentName ?? 'Student'),
                          style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(widget.booking.subject, style: theme.textTheme.small),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (_isPackage) ...[
              Text('Scope', style: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ShadRadioGroup<bool>(
                initialValue: _isPatternChange,
                onChanged: (v) => setState(() => _isPatternChange = v ?? true),
                items: [
                  ShadRadio(value: true, label: const Text('Move Entire Pattern')),
                  ShadRadio(value: false, label: const Text('Specific Lesson Only')),
                ],
              ),
              const SizedBox(height: 24),
            ],

            if (!_isPackage || !_isPatternChange) 
              _buildSingleLessonFields(theme)
            else
              _buildPatternFields(theme),

            const SizedBox(height: 24),
            
            Text('Message (Optional)', style: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ShadInput(
              controller: _messageController,
              placeholder: const Text('Add a note about the change...'),
              maxLines: 3,
            ),
            
            const SizedBox(height: 32),
            
            ShadButton(
              width: double.infinity,
              onPressed: _submitProposal,
              child: const Text('SUBMIT PROPOSAL'),
            ),
            const SizedBox(height: 8),
            ShadButton.ghost(
              width: double.infinity,
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleLessonFields(ShadThemeData theme) {
    final dateStr = _selectedDate != null ? DateFormat('MMM dd, yyyy').format(_selectedDate!) : 'Select Date';
    final timeStr = _selectedTime != null ? _selectedTime!.format(context) : 'Select Time';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isPackage) ...[
          Text('Select Lesson', style: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildLessonSelect(theme),
          const SizedBox(height: 16),
        ],
        Text('New Date & Time', style: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ShadButton.outline(
                onPressed: _pickDate,
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 16),
                    const SizedBox(width: 8),
                    Text(dateStr, style: theme.textTheme.small),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ShadButton.outline(
                onPressed: _pickTime,
                child: Row(
                  children: [
                    const Icon(LucideIcons.clock, size: 16),
                    const SizedBox(width: 8),
                    Text(timeStr, style: theme.textTheme.small),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPatternFields(ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Change From', style: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ShadSelect<String>(
          initialValue: _sourceDay,
          onChanged: (v) => setState(() => _sourceDay = v),
          options: _sourceDaysOfWeek.map((day) => ShadOption(value: day, child: Text(day))).toList(),
          placeholder: const Text('Select Current Day'),
          selectedOptionBuilder: (context, value) => Text(value),
        ),
        const SizedBox(height: 16),
        Text('To New Schedule', style: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: ShadSelect<String>(
                initialValue: _destDay,
                onChanged: (v) => setState(() => _destDay = v),
                options: _daysOfWeek.map((day) => ShadOption(value: day, child: Text(day))).toList(),
                placeholder: const Text('Select New Day'),
                selectedOptionBuilder: (context, value) => Text(value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ShadButton.outline(
                onPressed: _pickTime,
                child: Text(_selectedTime?.format(context) ?? 'Time'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLessonSelect(ShadThemeData theme) {
    final lessons = widget.allBookings
        .where((b) => b.isPackage && b.packageId == widget.booking.packageId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return ShadSelect<BookingModel>(
      initialValue: _selectedLesson,
      onChanged: (v) => setState(() => _selectedLesson = v),
      options: lessons.asMap().entries.map((entry) {
        final i = entry.key;
        final b = entry.value;
        final dt = DateTime.fromMillisecondsSinceEpoch(b.timestamp);
        return ShadOption(
          value: b, 
          child: Text('Lesson ${i+1}: ${DateFormat('MMM dd, HH:mm').format(dt)}'),
        );
      }).toList(),
      placeholder: const Text('Choose a lesson'),
      selectedOptionBuilder: (context, value) {
        final dt = DateTime.fromMillisecondsSinceEpoch(value.timestamp);
        return Text('Lesson: ${DateFormat('MMM dd, HH:mm').format(dt)}');
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await AdaptiveUtils.showAdaptiveDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await AdaptiveUtils.showAdaptiveTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _submitProposal() async {
    if (_selectedTime == null || (_selectedDate == null && !_isPatternChange)) {
      ShadToaster.of(context).show(
        const ShadToast(
          description: Text('Please select date and time'),
        ),
      );
      return;
    }

    final String messagePrefix = widget.isStudent ? 'Student proposed: ' : 'Tutor proposed: ';
    final String message = '$messagePrefix${_messageController.text}';

    final ref = FirebaseDatabase.instance.ref('Bookings');
    
    if (!_isPackage || !_isPatternChange) {
      final newDt = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _selectedTime!.hour, _selectedTime!.minute
      );
      
      await ref.child(_selectedLesson!.id).update({
        'status': 'suggestion_pending',
        'suggestedTimestamp': newDt.millisecondsSinceEpoch,
        'suggestedSourceDay': _isPackage ? 'This Lesson' : null,
        'suggestionMessage': message,
        'lastSuggestedBy': widget.isStudent ? 'student' : 'tutor',
      });
    } else {
      await ref.child(widget.booking.id).update({
        'status': 'suggestion_pending',
        'suggestedSourceDay': _sourceDay,
        'suggestedDestDay': _destDay,
        'suggestedTime': '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        'suggestionMessage': message,
        'lastSuggestedBy': widget.isStudent ? 'student' : 'tutor',
      });
    }

    if (mounted) {
      Navigator.pop(context);
      ShadToaster.of(context).show(
        const ShadToast(
          description: Text('Reschedule proposal sent!'),
        ),
      );
    }
  }
}
