import 'package:flutter/material.dart';
import 'journal_services.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  Map<String, String> _entries = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final allEntries = await JournalService.loadAll();
    // Filter out completely empty entries
    final validEntries = Map<String, String>.fromEntries(
      allEntries.entries.where((e) => e.value.trim().isNotEmpty),
    );
    setState(() {
      _entries = validEntries;
      _isLoading = false;
    });
  }

  String _formattedDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length != 3) return dateStr;
      
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  void _deleteEntry(String date) async {
    await JournalService.delete(date);
    _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    // Sort dates descending (newest first)
    final sortedDates = _entries.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Journal History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : sortedDates.isEmpty 
          ? const Center(
              child: Text(
                'No journal entries yet.',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final text = _entries[date]!;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formattedDate(date),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _deleteEntry(date),
                            child: const Icon(Icons.delete_outline,
                                color: Colors.white38, size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        text,
                        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
