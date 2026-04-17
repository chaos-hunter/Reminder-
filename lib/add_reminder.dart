import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'reminder.dart';
import 'reminder_data.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AddReminderPage extends StatefulWidget {
  const AddReminderPage({super.key});

  @override
  State<AddReminderPage> createState() => _AddReminderPageState();
}


class _AddReminderPageState extends State<AddReminderPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  double? selectedLat;
  double? selectedLng;
  String? selectedPlaceId;

  Timer? _debounce;

  List<dynamic> places = [];


  @override
  void dispose(){
    _debounce?.cancel();
    titleController.dispose();
    descriptionController.dispose();
    dateController.dispose();
    timeController.dispose();
    locationController.dispose();
    super.dispose();
  }

  // Opens the date picker dialog and populates dateController
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4FC3F7),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF121212)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Format: "Monday, March 19, 2026"
        dateController.text =
            '${_weekdayName(picked.weekday)}, ${_monthName(picked.month)} ${picked.day}, ${picked.year}';
      });
    }
  }

  // Opens the time picker dialog and populates timeController
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4FC3F7),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF121212)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Format: "8:05 AM"
        final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
        final minute = picked.minute.toString().padLeft(2, '0');
        final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
        timeController.text = '$hour:$minute $period';
      });
    }
  }

  String _weekdayName(int weekday) {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[weekday - 1];
  }

  String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month - 1];
  }

  //saving reminders requires at least a title for now
  Future<void> saveReminder() async{
    if (titleController.text.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar
        (
          content:
            Text(
              'Please enter a reminder title',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            duration: Duration(seconds: 1),
            backgroundColor: Color.fromARGB(255, 42, 42, 42),
        ),
      );
      return;
    }

    Reminder newReminder = Reminder(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      date: dateController.text.trim(),
      time: timeController.text.trim(),
      location: locationController.text.trim(),
      latitude: selectedLat,
      longitude: selectedLng,
      placeId: selectedPlaceId,
    );

    await ReminderData.addReminder(newReminder);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Saved',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Color.fromARGB(255, 42, 42, 42),
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }


  // Called whenever the user types in the location field. Fetches google maps autocomplete predictions.
  Future<void> fetchPlaces(String input) async {
    final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(input)}&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        places = data['predictions'] ?? [];
      });
    }
  }

  void onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (value.trim().isEmpty) {
        setState(() {
          places = [];
        });
        return;
      }
      fetchPlaces(value);
    });
  }

// Fetches the latitude and longitude for a given location on Google Maps.
  Future<Map<String, double>?> getLocationCoords(String placeId) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final loc = data['result']['geometry']['location'];

      return {
        'lat': loc['lat'],
        'lng': loc['lng'],
      };
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: const Color(0xFF121212),
        title: const Text(
          'Add Reminder',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create a new reminder.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Reminder title.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              ReminderTextField(
                hintText: 'Enter Reminder title',
                controller: titleController,

              ),

              const SizedBox(height: 20),
              const Text(
                'Reminder Description',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ReminderTextField(
                hintText: 'Enter reminder description',
                controller: descriptionController,
              ),

              const SizedBox(height: 20),
              const Text(
                'Date',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              // Tappable date picker — replaces ReminderTextField
              PickerDisplayField(
                controller: dateController,
                hintText: 'Select date',
                icon: Icons.calendar_today,
                onTap: _pickDate,
              ),

              const SizedBox(height: 20),
              const Text(
                'Time',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              // Tappable time picker — replaces ReminderTextField
              PickerDisplayField(
                controller: timeController,
                hintText: 'Select time',
                icon: Icons.access_time,
                onTap: _pickTime,
              ),

              const SizedBox(height: 20),
              const Text(
                'Location',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ReminderTextField(
                hintText: 'Enter location',
                controller: locationController,
                onChanged: onSearchChanged,
              ),
              if (places.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 30, 30, 30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: places.length,
                    itemBuilder: (context, index) {
                      final item = places[index];
                      final text = item['description'] ?? '';
                      return ListTile(
                        title: Text(
                          text,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () async {
                          final placeId = item['place_id'];
                          final description = item['description'];
                          final coords = await getLocationCoords(placeId);
                          setState(() {
                            locationController.text = description;
                            places.clear();
                            selectedPlaceId = placeId;
                            if (coords != null) {
                              selectedLat = coords['lat'];
                              selectedLng = coords['lng'];
                            }
                          });
                        },
                      );
                    },
                  ),
                ),

              const SizedBox(height: 30),


              //bottom area for the save and cancel buttons

              Row(
                children: [
                  Expanded(

                    //box for save
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 42, 42, 42),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),

                        onPressed: saveReminder,

                        child: const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),
                  Expanded(
                    //box for cancel
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 42, 42, 42),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// Read-only tappable field for date/time pickers.
class PickerDisplayField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final VoidCallback onTap;

  const PickerDisplayField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 42, 42, 42),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  return Text(
                    value.text.isEmpty ? hintText : value.text,
                    style: TextStyle(
                      color: value.text.isEmpty ? Colors.white38 : Colors.white,
                      fontSize: 16,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReminderTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final Function(String)? onChanged;

  const ReminderTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      onTapOutside: (_) {
        FocusScope.of(context).unfocus();
      },
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.white38,
          fontSize: 16,
        ),
        filled: true,
        fillColor: const Color.fromARGB(255, 42, 42, 42),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

      ),
    );
  }
}