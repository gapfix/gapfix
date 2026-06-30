import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:gapfix/core/theme.dart';

class AdaptiveUtils {
  static Future<DateTime?> showAdaptiveDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final ThemeData theme = Theme.of(context);
    if (theme.platform == TargetPlatform.iOS || theme.platform == TargetPlatform.macOS) {
      DateTime? selectedDate;
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext builderContext) {
          return Container(
            height: 250,
            padding: const EdgeInsets.only(top: 6.0),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        child: const Text('Done'),
                        onPressed: () {
                          selectedDate ??= initialDate;
                          Navigator.of(builderContext).pop();
                        },
                      )
                    ],
                  ),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: initialDate,
                      minimumDate: firstDate,
                      maximumDate: lastDate,
                      onDateTimeChanged: (DateTime newDate) {
                        selectedDate = newDate;
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      return selectedDate;
    } else {
      return showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: AppTheme.primary),
            ),
            child: child!,
          );
        },
      );
    }
  }

  static Future<TimeOfDay?> showAdaptiveTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
  }) async {
    final ThemeData theme = Theme.of(context);
    if (theme.platform == TargetPlatform.iOS || theme.platform == TargetPlatform.macOS) {
      DateTime? selectedTime;
      final initialDateTime = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day, initialTime.hour, initialTime.minute);
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext builderContext) {
          return Container(
            height: 250,
            padding: const EdgeInsets.only(top: 6.0),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        child: const Text('Done'),
                        onPressed: () {
                          selectedTime ??= initialDateTime;
                          Navigator.of(builderContext).pop();
                        },
                      )
                    ],
                  ),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: initialDateTime,
                      onDateTimeChanged: (DateTime newTime) {
                        selectedTime = newTime;
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      if (selectedTime != null) {
        return TimeOfDay(hour: selectedTime!.hour, minute: selectedTime!.minute);
      }
      return null;
    } else {
      return showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: AppTheme.primary),
            ),
            child: child!,
          );
        },
      );
    }
  }
}
