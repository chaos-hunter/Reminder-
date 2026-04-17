import 'dart:convert'; //uses jsonEncode and jsonDecode
import 'package:shared_preferences/shared_preferences.dart'; //used for data persistence

class JournalService {
  static const key = 'journal_entries';

    //stores journal data as a Map<String, String>, essentially a hashtable that maps a string (date) to a string (journal entry)
    //this function loads the users journal data upon opening the app
  static Future<Map<String, String>> loadAll() async {
    final data = await SharedPreferences.getInstance();
    final raw = data.getString(key);
    if (raw == null) {
        return {};
    }
    return Map<String, String>.from(jsonDecode(raw));
  }

    //this function saves users journal data
  static Future<void> save(String date, String text) async {
    final data = await SharedPreferences.getInstance();
    final entries = await loadAll();
    entries[date] = text;
    await data.setString(key, jsonEncode(entries));
  }

    //this function is used in clearing a specific journal entry
  static Future<void> delete(String date) async {
    final data = await SharedPreferences.getInstance();
    final entries = await loadAll();
    entries.remove(date);
    await data.setString(key, jsonEncode(entries));
  }
}
