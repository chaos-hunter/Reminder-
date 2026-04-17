// reminder model

class Reminder {
  String id;
  String title;
  String description;
  String date;
  String time;
  String location;
  bool isCompleted;
  double? latitude;
  double? longitude;
  String? placeId;

  Reminder({
    this.id = '',
    required this.title,
    required this.description,
    required this.time,
    required this.date,
    required this.location,
    this.isCompleted = false,
    this.latitude,
    this.longitude,
    this.placeId,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'location': location,
      'isCompleted': isCompleted,
      // lat/lng and placeId are now persisted so location checking works
      // after the app is restarted.
      'latitude': latitude,
      'longitude': longitude,
      'placeId': placeId,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map, [String documentId = '']) {
    return Reminder(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      location: map['location'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      placeId: map['placeId'] as String?,
    );
  }
}