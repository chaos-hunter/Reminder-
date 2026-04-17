import 'reminder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReminderData {
  static List<Reminder> reminders = [];

  //open reminders collection
  static CollectionReference<Map<String, dynamic>> remindersRef() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('no user');
    }

    return FirebaseFirestore.instance.collection('users').doc(user.uid).collection('reminders');
  }

  static Future<void> loadReminders() async {
    final snapshot = await remindersRef().get();

    reminders = snapshot.docs.map((doc) {
      return Reminder.fromMap(doc.data(), doc.id);
    }).toList();

  }

  static Future<void> addReminder(Reminder reminder) async {
    final docRef = await remindersRef().add(reminder.toMap());
    reminder.id = docRef.id;
    reminders.add(reminder);
  }

  static Future<void> updateReminder(Reminder reminder) async {
    if (reminder.id.isEmpty) return;

    await remindersRef().doc(reminder.id).update(reminder.toMap());
  }

  static Future<void> deleteReminder(Reminder reminder) async {
    if (reminder.id.isEmpty) return;
    await remindersRef().doc(reminder.id).delete();
    reminders.removeWhere((r) => r.id == reminder.id);
  }

}