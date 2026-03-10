import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../../core/notifications/desktop_island.dart';
import '../domain/reminder.dart';

enum _ReminderFilter { all, active, done, overdue }

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  List<Reminder> _reminders = const [];
  bool _loading = true;
  int _pendingCount = 0;
  _ReminderFilter _filter = _ReminderFilter.all;
  Timer? _autoSyncTimer;

  @override
  void initState() {
    super.initState();
    _reload();
    _autoSyncTimer = Timer.periodic(
      const Duration(seconds: 25),
      (_) => _reload(silent: true),
    );
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshPendingCount() async {
    final count = await AppDI.syncManager.pendingCount();
    if (!mounted) return;
    setState(() => _pendingCount = count);
  }

  Future<void> _reload({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      try {
        await AppDI.syncManager.syncOnce();
      } catch (_) {}
      final reminders = await AppDI.reminderRepo.list();
      if (!mounted) return;
      setState(() => _reminders = reminders);
      await _refreshPendingCount();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load reminders')),
      );
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _forceSync() async {
    setState(() => _loading = true);
    try {
      await AppDI.syncManager.forceFullSync();
      await _reload(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full sync completed')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full sync failed')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showCreateReminderDialog() async {
    final titleCtrl = TextEditingController(text: 'Drink water');
    final minutesCtrl = TextEditingController(text: '15');

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 14,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 32,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0D0D8),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'New Reminder',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: minutesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'After minutes'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Create'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (ok != true) return;

    final minutes = int.tryParse(minutesCtrl.text.trim()) ?? 15;
    final dueAt = DateTime.now().add(Duration(minutes: minutes.clamp(1, 720)));
    final reminder = await AppDI.reminderRepo.create(
      title: titleCtrl.text.trim().isEmpty ? 'Reminder' : titleCtrl.text.trim(),
      dueAt: dueAt,
      repeatRule: 'none',
    );
    if (!mounted) return;
    if (reminder.id.startsWith('local-reminder-')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved offline, sync queued')),
      );
    }
    await DesktopIsland.show(
      title: reminder.title,
      body: 'Reminder created',
    );
    await _reload();
  }

  Future<void> _markDone(Reminder reminder) async {
    await AppDI.reminderRepo.done(reminder.id);
    if (!mounted) return;
    await DesktopIsland.show(
      title: 'Marked done',
      body: reminder.title,
    );
    await _reload();
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    await AppDI.reminderRepo.remove(reminder.id);
    if (!mounted) return;
    await _reload();
  }

  Widget _pendingChip() {
    final hasPending = _pendingCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: hasPending ? const Color(0xFFFFEEE6) : const Color(0xFFEAF8EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        hasPending ? 'Pending $_pendingCount' : 'Synced',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: hasPending ? const Color(0xFFB54708) : const Color(0xFF027A48),
        ),
      ),
    );
  }

  List<Reminder> get _visibleReminders {
    final now = DateTime.now();
    return _reminders.where((r) {
      final isDone = r.status == 'done';
      final isOverdue = !isDone && r.dueAt.toLocal().isBefore(now);
      return switch (_filter) {
        _ReminderFilter.all => true,
        _ReminderFilter.active => !isDone,
        _ReminderFilter.done => isDone,
        _ReminderFilter.overdue => isOverdue,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Stack(
        children: [
          Positioned(
            top: -110,
            left: -90,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0x2E7AD7FF), Color(0x067AD7FF)],
                ),
              ),
            ),
          ),
          Positioned(
            top: -70,
            right: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0x268CE5B4), Color(0x068CE5B4)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Reminders',
                          style: TextStyle(
                              fontSize: 34, fontWeight: FontWeight.w800),
                        ),
                      ),
                      _pendingChip(),
                      IconButton(
                        onPressed: _reload,
                        icon: const Icon(CupertinoIcons.refresh_thick),
                      ),
                      IconButton(
                        onPressed: _forceSync,
                        icon: const Icon(CupertinoIcons.arrow_2_circlepath),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: CupertinoSlidingSegmentedControl<_ReminderFilter>(
                    groupValue: _filter,
                    onValueChanged: (v) {
                      if (v == null) return;
                      setState(() => _filter = v);
                    },
                    children: const {
                      _ReminderFilter.all: Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text('All'),
                      ),
                      _ReminderFilter.active: Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text('Active'),
                      ),
                      _ReminderFilter.done: Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text('Done'),
                      ),
                      _ReminderFilter.overdue: Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text('Overdue'),
                      ),
                    },
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _visibleReminders.isEmpty
                          ? const Center(child: Text('No reminders yet'))
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 6, 16, 120),
                              itemCount: _visibleReminders.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final reminder = _visibleReminders[i];
                                final done = reminder.status == 'done';
                                final overdue = !done &&
                                    reminder.dueAt.toLocal().isBefore(
                                      DateTime.now(),
                                    );
                                return Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 14, 10, 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.84),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.96)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            done
                                                ? CupertinoIcons
                                                    .check_mark_circled_solid
                                                : CupertinoIcons.bell_fill,
                                            color: done
                                                ? const Color(0xFF34C759)
                                                : const Color(0xFF007AFF),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              reminder.title,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: done
                                                  ? const Color(0xFFEAF8EF)
                                                  : const Color(0xFFE9F2FF),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              done ? 'Done' : 'Active',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: done
                                                    ? const Color(0xFF027A48)
                                                    : const Color(0xFF004FBA),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        overdue
                                            ? 'Overdue: ${reminder.dueAt.toLocal()}'
                                            : 'Due: ${reminder.dueAt.toLocal()}',
                                        style: TextStyle(
                                          color: overdue
                                              ? const Color(0xFFB42318)
                                              : const Color(0xFF4D4D57),
                                          fontWeight: overdue
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          _miniAction(
                                            icon: CupertinoIcons.timer,
                                            label: 'Snooze',
                                            onTap: () async {
                                              await AppDI.reminderRepo
                                                  .snooze(reminder.id, 10);
                                              if (!mounted) return;
                                              await DesktopIsland.show(
                                                title: 'Snoozed 10 minutes',
                                                body: reminder.title,
                                              );
                                              await _reload();
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          _miniAction(
                                            icon: CupertinoIcons.check_mark,
                                            label: 'Done',
                                            onTap: done
                                                ? null
                                                : () => _markDone(reminder),
                                          ),
                                          const SizedBox(width: 8),
                                          _miniAction(
                                            icon: CupertinoIcons.delete,
                                            label: 'Delete',
                                            danger: true,
                                            onTap: () =>
                                                _deleteReminder(reminder),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateReminderDialog,
        label: const Text('New Reminder'),
        icon: const Icon(CupertinoIcons.add),
      ),
    );
  }

  Widget _miniAction({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool danger = false,
  }) {
    final fg = danger ? const Color(0xFFFF3B30) : const Color(0xFF007AFF);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: danger ? const Color(0xFFFFEBEA) : const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
