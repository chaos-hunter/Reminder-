import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'reminder.dart';
import 'reminder_data.dart';
import 'reminder_detail_page.dart';

class CompletedRemindersPage extends StatefulWidget {
  const CompletedRemindersPage({super.key});

  @override
  State<CompletedRemindersPage> createState() => _CompletedRemindersPageState();
}

class _CompletedRemindersPageState extends State<CompletedRemindersPage> {
  @override
  Widget build(BuildContext context) {
    final List<Reminder> completedReminders =
        ReminderData.reminders.where((r) => r.isCompleted).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: const Color(0xFF121212),
        title: const Text(
          'Completed',
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
                '${completedReminders.length} Completed Reminders.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              // Searches only within completed reminders
              HomeSearchBar(reminders: completedReminders),
              const SizedBox(height: 20),
              if (completedReminders.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      'No completed reminders yet.',
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
                  itemCount: completedReminders.length,
                  itemBuilder: (context, index) {
                    final item = completedReminders[index];
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

// ReminderCard — unchanged from your original
class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onTap,
    this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggleComplete,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: reminder.isCompleted
                        ? const Color(0xFF4FC3F7)
                        : Colors.white38,
                    width: 2,
                  ),
                  color: reminder.isCompleted
                      ? const Color(0xFF4FC3F7)
                      : Colors.transparent,
                ),
                child: reminder.isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.black)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reminder.title,
                style: TextStyle(
                  color: reminder.isCompleted ? Colors.white38 : Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  decoration: reminder.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: Colors.white38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}