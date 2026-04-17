import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'completed_reminders.dart';
import 'reminder.dart';
import 'reminder_data.dart';
import 'reminder_detail_page.dart';

class ScheduledRemindersPage extends StatefulWidget {
  const ScheduledRemindersPage({super.key});

  @override
  State<ScheduledRemindersPage> createState() => _ScheduledRemindersPageState();
}

class _ScheduledRemindersPageState extends State<ScheduledRemindersPage> {
  DateTime? _parseDate(String dateStr) {
    try {
      const months = {
        'January': 1, 'February': 2, 'March': 3, 'April': 4,
        'May': 5, 'June': 6, 'July': 7, 'August': 8,
        'September': 9, 'October': 10, 'November': 11, 'December': 12,
      };
      final withoutWeekday = dateStr.contains(', ')
          ? dateStr.substring(dateStr.indexOf(', ') + 2)
          : dateStr;
      final parts = withoutWeekday.replaceAll(',', '').split(' ');
      if (parts.length < 3) return null;
      final month = months[parts[0]];
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (month == null || day == null || year == null) return null;
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<Reminder> scheduledReminders = ReminderData.reminders.where((r) {
      if (r.isCompleted) return false;
      final date = _parseDate(r.date);
      if (date == null) return false;
      return date.isAfter(today);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: const Color(0xFF121212),
        title: const Text(
          'Scheduled',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${scheduledReminders.length} Scheduled Reminders.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              // Searches only within scheduled reminders
              HomeSearchBar(reminders: scheduledReminders),
              const SizedBox(height: 20),
              if (scheduledReminders.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      'No scheduled reminders.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 6),
                  itemCount: scheduledReminders.length,
                  itemBuilder: (context, index) {
                    final item = scheduledReminders[index];
                    return ReminderCard(
                      reminder: item,
                      onToggleComplete: () async {
                        setState(() {
                          item.isCompleted = !item.isCompleted;
                        });
                        await ReminderData.updateReminder(item);
                      },
                      onTap: () async {
                        final deleted = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReminderDetailPage(reminder: item),
                          ),
                        );
                        if (deleted == true) setState(() {});
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}