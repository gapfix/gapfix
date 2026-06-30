import 'package:flutter/material.dart';
import 'package:gapfix/models/tutor_model.dart';
import 'package:gapfix/core/theme.dart';
import 'package:gapfix/core/toast_utils.dart';
import 'package:gapfix/core/adaptive_utils.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class BookingBottomSheet extends StatefulWidget {
  final TutorModel tutor;
  final bool isTrial;

  const BookingBottomSheet({
    super.key,
    required this.tutor,
    required this.isTrial,
  });

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  SubjectPreference? _selectedSubject;
  bool _isPackage = false;
  int _packageQuantity = 12;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  
  // Weekly slots for package mode: {dayIndex: TimeOfDay}
  final Map<int, TimeOfDay> _weeklySlots = {};
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  bool _agreedToPolicy = false;
  bool _isSubmitting = false;
  bool _isPro = false; // Placeholder for Pro status

  @override
  void initState() {
    super.initState();
    if (widget.tutor.preferences.isNotEmpty) {
      _selectedSubject = widget.tutor.preferences.first;
    }
    _checkProStatus();
  }

  Future<void> _checkProStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final snapshot = await FirebaseDatabase.instance.ref('Users/Student/$uid/isPro').get();
    if (mounted) {
      setState(() {
        _isPro = snapshot.value == true;
      });
    }
  }

  double get _subtotal {
    if (_selectedSubject == null) return 0;
    if (widget.isTrial) return 0;
    
    if (_isPackage) {
      return _selectedSubject!.price.toDouble() * _packageQuantity;
    } else {
      return _selectedSubject!.price.toDouble();
    }
  }

  double get _discount => _isPro ? (_subtotal * 0.05) : 0;
  double get _platformFee => (_subtotal - _discount) * 0.05;
  double get _total => _subtotal - _discount + _platformFee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              widget.isTrial ? 'Book Free Trial' : 'Book Lesson',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Subject Selection
            const Text('Select Subject', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.tutor.preferences.map((pref) {
                  final isSelected = _selectedSubject == pref;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(pref.name),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedSubject = pref);
                      },
                      selectedColor: theme.primaryColor.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? theme.primaryColor : secondaryTextColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Lesson Type Toggle (only if not trial)
            if (!widget.isTrial) ...[
              const Text('Lesson Type', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _toggleButton('Single Lesson', !_isPackage, () => setState(() => _isPackage = false)),
                    ),
                    Expanded(
                      child: _toggleButton('Package', _isPackage, () => setState(() => _isPackage = true)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (!_isPackage) _buildSingleLessonPicker(context, isDark, secondaryTextColor)
            else _buildPackagePicker(context, isDark, secondaryTextColor),

            const SizedBox(height: 32),

            // Order Summary
            _buildOrderSummary(theme, secondaryTextColor),

            const SizedBox(height: 24),

            // Cancellation Policy
            Row(
              children: [
                Checkbox(
                  value: _agreedToPolicy,
                  onChanged: (val) => setState(() => _agreedToPolicy = val ?? false),
                  activeColor: theme.primaryColor,
                ),
                Expanded(
                  child: Text(
                    'I agree to the 24-hour cancellation policy.',
                    style: TextStyle(fontSize: 13, color: secondaryTextColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Confirm Button
            ElevatedButton(
              onPressed: (_agreedToPolicy && !_isSubmitting) ? _handleBooking : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008253),
                minimumSize: const Size(double.infinity, 56),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Secure Payment & Confirm Booking'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _toggleButton(String label, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : (theme.brightness == Brightness.dark ? Colors.white60 : Colors.black54),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSingleLessonPicker(BuildContext context, bool isDark, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Date & Time', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _pickerBox(
                icon: Icons.calendar_today,
                label: DateFormat('MMM dd, yyyy').format(_selectedDate),
                onTap: () => _selectDate(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _pickerBox(
                icon: Icons.access_time,
                label: _selectedTime.format(context),
                onTap: () => _selectTime(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await AdaptiveUtils.showAdaptiveDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _selectTime(BuildContext context) async {
    final time = await AdaptiveUtils.showAdaptiveTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Widget _buildPackagePicker(BuildContext context, bool isDark, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Package Quantity', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            _counterButton(Icons.remove, () {
              if (_packageQuantity > 1) setState(() => _packageQuantity--);
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('$_packageQuantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            _counterButton(Icons.add, () => setState(() => _packageQuantity++)),
            const Spacer(),
            Text('Lessons', style: TextStyle(color: secondaryTextColor)),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Start Date', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _pickerBox(
          icon: Icons.calendar_today,
          label: DateFormat('MMM dd, yyyy').format(_selectedDate),
          onTap: () => _selectDate(context),
        ),
        const SizedBox(height: 24),
        const Text('Weekly Slots', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Select the days and times you want to have lessons every week.', style: TextStyle(fontSize: 12, color: secondaryTextColor)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (index) {
            final isSelected = _weeklySlots.containsKey(index);
            return GestureDetector(
              onTap: () => _toggleWeeklyDay(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.transparent),
                ),
                child: Column(
                  children: [
                    Text(
                      _days[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 4),
                      Text(
                        _weeklySlots[index]!.format(context),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  void _toggleWeeklyDay(int index) async {
    if (_weeklySlots.containsKey(index)) {
      setState(() => _weeklySlots.remove(index));
    } else {
      final time = await AdaptiveUtils.showAdaptiveTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
      );
      if (time != null) {
        setState(() => _weeklySlots[index] = time);
      }
    }
  }

  Widget _pickerBox({required IconData icon, required String label, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _counterButton(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        foregroundColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildOrderSummary(ThemeData theme, Color secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', '\$${_subtotal.toStringAsFixed(2)}', secondaryTextColor),
          if (_isPro) ...[
            const SizedBox(height: 8),
            _summaryRow('Pro Discount (5%)', '-\$${_discount.toStringAsFixed(2)}', Colors.green),
          ],
          const SizedBox(height: 8),
          _summaryRow('Platform Fees (5%)', '\$${_platformFee.toStringAsFixed(2)}', secondaryTextColor),
          const Divider(height: 24),
          _summaryRow('Total', '\$${_total.toStringAsFixed(2)}', theme.colorScheme.onSurface, isBold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Future<void> _handleBooking() async {
    if (_selectedSubject == null) return;
    
    if (_isPackage && _weeklySlots.isEmpty) {
      ToastUtils.show(context, 'Please select at least one weekly slot for the package.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final studentSnap = await FirebaseDatabase.instance.ref('Users/Student/${user.uid}').get();
      final studentData = studentSnap.value as Map?;
      final studentName = studentData?['name'] ?? 'Unknown Student';

      final Map<String, dynamic> updates = {};
      final String packageId = FirebaseDatabase.instance.ref().push().key!;

      if (_isPackage) {
        int lessonsGenerated = 0;
        DateTime currentDate = _selectedDate;

        while (lessonsGenerated < _packageQuantity) {
          final dayIndex = currentDate.weekday - 1; // DateTime.weekday is 1 (Mon) to 7 (Sun), _weeklySlots is 0 (Mon) to 6 (Sun)
          if (_weeklySlots.containsKey(dayIndex)) {
            final time = _weeklySlots[dayIndex]!;
            final sessionTime = DateTime(
              currentDate.year,
              currentDate.month,
              currentDate.day,
              time.hour,
              time.minute,
            );

            final bookingId = FirebaseDatabase.instance.ref('Bookings').push().key!;
            updates['Bookings/$bookingId'] = {
              'id': bookingId,
              'studentId': user.uid,
              'studentName': studentName,
              'tutorId': widget.tutor.id,
              'tutorName': widget.tutor.name,
              'subject': _selectedSubject!.name,
              'status': 'pending',
              'isFree': false,
              'isPackage': true,
              'packageId': packageId,
              'packageTotalLessons': _packageQuantity,
              'timestamp': sessionTime.millisecondsSinceEpoch,
              'duration': _selectedSubject!.duration,
              'price': _selectedSubject!.price,
              'totalAmount': _total / _packageQuantity,
            };
            lessonsGenerated++;
          }
          currentDate = currentDate.add(const Duration(days: 1));
        }
      } else {
        final bookingId = FirebaseDatabase.instance.ref('Bookings').push().key!;
        final startDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        updates['Bookings/$bookingId'] = {
          'id': bookingId,
          'studentId': user.uid,
          'studentName': studentName,
          'tutorId': widget.tutor.id,
          'tutorName': widget.tutor.name,
          'subject': _selectedSubject!.name,
          'status': widget.isTrial ? 'free_trial_pending' : 'pending',
          'isFree': widget.isTrial,
          'isPackage': false,
          'timestamp': startDateTime.millisecondsSinceEpoch,
          'duration': _selectedSubject!.duration,
          'price': _selectedSubject!.price,
          'totalAmount': _total,
        };
      }

      await FirebaseDatabase.instance.ref().update(updates);

      if (widget.isTrial) {
        await FirebaseDatabase.instance
            .ref('FreeLessonsUsed/${user.uid}/${widget.tutor.id}/${_selectedSubject!.name}')
            .set(true);
      }

      // Send Notification
      await FirebaseDatabase.instance.ref('Notifications/${widget.tutor.id}').push().set({
        'title': 'New Booking Request',
        'message': '$studentName has requested a ${_isPackage ? 'package' : 'lesson'} for ${_selectedSubject!.name}.',
        'timestamp': ServerValue.timestamp,
        'read': false,
      });

      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        Navigator.pop(context); // Back to shop
        ToastUtils.show(context, 'Booking confirmed!');
      }
    } catch (e) {
      debugPrint('Booking error: $e');
      if (mounted) {
        ToastUtils.show(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
