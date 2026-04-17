import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'reminder_data.dart';
import 'reminder.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Ensure background isolate runs safely.
  DartPluginRegistrant.ensureInitialized();
  
  // Initialize Firebase for the separate isolate!
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Await auth state hydration so ReminderData doesn't fetch zero reminders
  try {
    await FirebaseAuth.instance
        .authStateChanges()
        .firstWhere((user) => user != null)
        .timeout(const Duration(seconds: 5));
  } catch (_) {}
  
  // Must initialize notifications in the background memory!
  await LocationService._initNotifications();

  // Load initial reminders and keep background isolate synced perfectly via Stream
  ReminderData.remindersRef().snapshots().listen((snapshot) {
    ReminderData.reminders = snapshot.docs.map((doc) {
      return Reminder.fromMap(doc.data(), doc.id);
    }).toList();
  });

  LocationService.startBackgroundChecking(service);
}

class LocationService {
  static const double _radiusMetres = 100.0;
  static const Duration _checkInterval = Duration(seconds: 30);

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static final Set<String> _notifiedToday = {};
  static String _lastTrackedDay = '';

  static Future<void> init() async {
    if (kIsWeb) {
      // Background services and deep permission handlers are for mobile only.
      // Web just acts as a dashboard, so we skip this mobile initialization.
      return;
    }
    await _initNotifications();
    await _requestPermissions();
    await _initializeService();
  }

  static Future<void> _initializeService() async {
    final service = FlutterBackgroundService();

    // Create a special notification channel specifically for the foreground service requirement
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'location_reminders_bg', 
      'Background Tracking', 
      description: 'Keeps location checking alive when the app is closed', 
      importance: Importance.low, 
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'location_reminders_bg',
        initialNotificationTitle: 'Reminder+',
        initialNotificationContent: 'Monitoring locations for your reminders...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    service.startService();
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  static Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings);
  }

  static Future<void> _showNotification(Reminder reminder) async {
    const androidDetails = AndroidNotificationDetails(
      'location_reminders',
      'Location Reminders',
      channelDescription: 'Notifications when you arrive at a reminder location',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      reminder.id.hashCode,
      reminder.title,
      reminder.description.isNotEmpty
          ? reminder.description
          : 'You are near your reminder location!',
      details,
    );
  }

  static Future<void> _requestPermissions() async {
    // 1. Group the standard popups so Android queues them properly.
    await [
      Permission.notification,
      Permission.locationWhenInUse,
    ].request();

    // 2. Only after those are resolved, prompt for deep background access which redirects to Settings.
    if (await Permission.locationWhenInUse.isGranted) {
      await Permission.locationAlways.request();
    }

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // --- Functions below run inside the background Isolate ---

  static void startBackgroundChecking(ServiceInstance service) {
    _checkIsolate();
    Timer.periodic(_checkInterval, (_) {
      _checkIsolate();
    });
  }

  static Future<void> _checkIsolate() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (today != _lastTrackedDay) {
      _notifiedToday.clear();
      _lastTrackedDay = today;
      // Refresh the database load occasionally 
      try {
        await ReminderData.loadReminders();
      } catch (_) {}
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;

    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    Position current;
    try {
      current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) return;
        current = last;
      } catch (_) {
        return;
      }
    }

    for (final reminder in ReminderData.reminders) {
      if (reminder.latitude == null || reminder.longitude == null) continue;
      if (reminder.isCompleted) continue;
      if (_notifiedToday.contains(reminder.id)) continue;
      if (!_isToday(reminder.date)) continue;

      final distance = _distanceMetres(
        current.latitude,
        current.longitude,
        reminder.latitude!,
        reminder.longitude!,
      );

      if (distance <= _radiusMetres) {
        _notifiedToday.add(reminder.id);
        await _showNotification(reminder);
      }
    }
  }

  static bool _isToday(String dateStr) {
    if (dateStr.isEmpty) return false;
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
      if (parts.length < 3) return false;
      final month = months[parts[0]];
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (month == null || day == null || year == null) return false;

      final now = DateTime.now();
      return now.year == year && now.month == month && now.day == day;
    } catch (_) {
      return false;
    }
  }

  static double _distanceMetres(
      double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRad(double deg) => deg * pi / 180;
}