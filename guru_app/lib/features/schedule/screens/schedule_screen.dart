import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:table_calendar/table_calendar.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedSlot;
  final _noteController = TextEditingController();
  bool _isSubmitting = false;
  String? _noteError;

  static final _slots = [
    const TimeOfDay(hour: 7, minute: 0),
    const TimeOfDay(hour: 7, minute: 30),
    const TimeOfDay(hour: 8, minute: 0),
    const TimeOfDay(hour: 8, minute: 30),
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 9, minute: 30),
    const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 10, minute: 30),
    const TimeOfDay(hour: 11, minute: 0),
    const TimeOfDay(hour: 11, minute: 30),
    const TimeOfDay(hour: 14, minute: 0),
    const TimeOfDay(hour: 14, minute: 30),
    const TimeOfDay(hour: 15, minute: 0),
    const TimeOfDay(hour: 15, minute: 30),
    const TimeOfDay(hour: 16, minute: 0),
    const TimeOfDay(hour: 16, minute: 30),
    const TimeOfDay(hour: 17, minute: 0),
    const TimeOfDay(hour: 17, minute: 30),
    const TimeOfDay(hour: 18, minute: 0),
    const TimeOfDay(hour: 18, minute: 30),
  ];

  DateTime _toDateTime(DateTime day, TimeOfDay time) {
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }
    final noteErr = Validators.validateNote(_noteController.text.trim());
    if (noteErr != null) {
      setState(() => _noteError = noteErr);
      return;
    }
    if (!Validators.isValidFutureSlot(_selectedSlot!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please pick a slot at least 1 minute in the future')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _noteError = null;
    });

    try {
      final isTaken = await CallRequestService.instance
          .isSlotTaken(AppConstants.trainerAaravId, _selectedSlot!);
      if (isTaken) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'That slot is already booked. Please pick another time.')),
          );
        }
        return;
      }

      await CallRequestService.instance.createRequest(
        CallRequestModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          memberId: AppConstants.memberDkId,
          trainerId: AppConstants.trainerAaravId,
          requestedAt: DateTime.now(),
          scheduledFor: _selectedSlot!,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          status: 'pending',
          memberName: 'DK',
          trainerName: 'Aarav',
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Call requested. Waiting for trainer approval.')),
        );
        context.push('/requests');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lastDay = now.add(const Duration(days: 3));

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule a Call')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TableCalendar(
              firstDay: now,
              lastDay: lastDay,
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                  _selectedSlot = null;
                });
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: AppColors.guruPrimary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.guruPrimary.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
              child: Text('Available Slots', style: AppTextStyles.h3),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _slots.map((slot) {
                  final dt = _toDateTime(_selectedDay, slot);
                  final isPast = dt.isBefore(now);
                  final isSelected = _selectedSlot != null &&
                      isSameDay(_selectedSlot!, dt) &&
                      _selectedSlot!.hour == dt.hour &&
                      _selectedSlot!.minute == dt.minute;
                  return TimeChip(
                    label: slot.format(context),
                    isSelected: isSelected,
                    isDisabled: isPast,
                    onTap: () => setState(() => _selectedSlot = dt),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Note for Trainer (optional)',
                      style: AppTextStyles.label),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _noteController,
                    maxLength: 140,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'e.g. Focus on upper body',
                      errorText: _noteError,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (_) {
                      if (_noteError != null) {
                        setState(() => _noteError =
                            Validators.validateNote(_noteController.text));
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CtaButton(
                    label: 'Request Call',
                    onPressed: _submit,
                    isLoading: _isSubmitting,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
