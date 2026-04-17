import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'completed_reminders.dart';
import 'reminder_detail_page.dart';
import 'reminder.dart';
import 'reminder_data.dart';


class AllRemindersPage extends StatefulWidget {
  const AllRemindersPage({super.key});

  @override
  State<AllRemindersPage> createState() => _AllRemindersPageState();
}

class _AllRemindersPageState extends State<AllRemindersPage> {
  @override
  Widget build(BuildContext context) {
    final List<Reminder> allReminders = ReminderData.reminders;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: const Color(0xFF121212),
        title: const Text(
          'All',
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
                '${allReminders.length} Total Reminders.',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 20),
              HomeSearchBar(reminders: allReminders),
              const SizedBox(height: 20),
              if (allReminders.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      'No reminders yet.',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemCount: allReminders.length,
                  itemBuilder: (context, index) {
                    final item = allReminders[index];
                    return ReminderCard(
                      reminder: item,
                      onToggleComplete: () async {
                        setState(() => item.isCompleted = !item.isCompleted);
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