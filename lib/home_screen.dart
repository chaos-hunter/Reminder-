import 'package:flutter/material.dart';
import 'all_reminders.dart';
import 'today_reminders.dart';
import 'scheduled_reminders.dart';
import 'completed_reminders.dart';
import 'add_reminder.dart';
import 'reminder.dart';
import 'reminder_data.dart';
import 'reminder_detail_page.dart';
import 'journal_services.dart';
import 'journal_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final List<Map<String, String>> fakeReminders = [
    {'title': 'All'},
    {'title': 'Today'},
    {'title': 'Scheduled'},
    {'title': 'Completed'},
  ];

  static final Map<String, Widget> routes = {
    'All': const AllRemindersPage(),
    'Today': const TodayRemindersPage(),
    'Scheduled': const ScheduledRemindersPage(),
    'Completed': const CompletedRemindersPage(),
    'AddReminder': const AddReminderPage(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good day',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Here are your reminders for today',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              // Home screen searches all reminders
              HomeSearchBar(reminders: ReminderData.reminders),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: fakeReminders.length,
                itemBuilder: (context, index) {
                  final item = fakeReminders[index];
                  return GestureDetector(
                    onTap: () {
                      final page = routes[item['title']] as Widget;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => page),
                      );
                    },
                    child: ReminderCategory(
                      title: item['title'] ?? '',
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const JournalPage()),
                  );
                },
                child: Container(
                  color: Colors.transparent, // Ensures the entire row is clickable
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Journal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const JournalPreviewCard(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final page = AddReminderPage() as Widget;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        backgroundColor: const Color(0xFF4FC3F7),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// HomeSearchBar — stateful, overlay-based dropdown
class HomeSearchBar extends StatefulWidget {
  final List<Reminder> reminders;

  const HomeSearchBar({super.key, required this.reminders});

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  OverlayEntry? _overlayEntry;
  List<Reminder> _results = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      _removeOverlay();
      return;
    }

    _results = widget.reminders
        .where((r) => r.title.toLowerCase().startsWith(query))
        .toList();

    if (_results.isEmpty) {
      _removeOverlay();
      return;
    }

    if (_overlayEntry == null) {
      _showOverlay();
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _controller.text.trim().isEmpty) {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(builder: (_) => _buildDropdown());
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _results = [];
  }

  void _dismiss() {
    _controller.clear();
    _focusNode.unfocus();
    _removeOverlay();
  }

  Widget _buildDropdown() {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _dismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 52),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final reminder = _results[index];
                  return InkWell(
                    onTap: () {
                      _dismiss();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReminderDetailPage(
                            reminder: reminder,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: index < _results.length - 1
                            ? const Border(
                                bottom: BorderSide(
                                  color: Color(0xFF2A2A2A),
                                  width: 1,
                                ),
                              )
                            : null,
                      ),
                      child: Text(
                        reminder.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.white70),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onTapOutside: (_) => _dismiss(),
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search reminders.',
                  hintStyle: TextStyle(color: Colors.white54),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (_, value, __) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: _dismiss,
                  child: const Icon(Icons.close,
                      color: Colors.white54, size: 18),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// I renamed this to ReminderCategory since I took the code and slightly modified it for the reminder pages. --Yousef
class ReminderCategory extends StatelessWidget {
  final String title;

  const ReminderCategory({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class JournalPreviewCard extends StatefulWidget {
  const JournalPreviewCard({super.key});

  @override
  State<JournalPreviewCard> createState() => _JournalPreviewCardState();
}

class _JournalPreviewCardState extends State<JournalPreviewCard> {
  late final TextEditingController _controller;
  bool _isFocused = false;
  final String _today = DateTime.now().toIso8601String().substring(0, 10); //toIso8601String is a formatted version of a date string commonly used for representing dates

  String _formattedDate() {
    final now = DateTime.now();
    const weekdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final entries = await JournalService.loadAll();
    setState(() {
      _controller.text = entries[_today] ?? '';
    });
  }

  void _onChanged(String text) {
    JournalService.save(_today, text);
  }

  Future<void> _clear() async {
    await JournalService.delete(_today);
    setState(() => _controller.clear());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused ? const Color(0xFF4FC3F7) : Colors.transparent,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formattedDate(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: _clear,
                child: const Icon(Icons.delete_outline,
                    color: Colors.white38, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Focus(
            onFocusChange: (focused) => setState(() => _isFocused = focused),
            child: TextField(
              controller: _controller,
              maxLines: null,
              onChanged: _onChanged,
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
              },
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Write your journal entry...',
                hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}