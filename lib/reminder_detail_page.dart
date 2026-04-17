import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'reminder.dart';
import 'reminder_data.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReminderDetailPage extends StatefulWidget {
  final Reminder reminder;

  const ReminderDetailPage({super.key, required this.reminder});

  @override
  State<ReminderDetailPage> createState() => _ReminderDetailPageState();
}

class _ReminderDetailPageState extends State<ReminderDetailPage> {
  bool _isEditing = false;

  Timer? _debounce;

  List<dynamic> places = [];

  // Controllers for edit mode, initialized with current reminder values
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _titleController       = TextEditingController(text: widget.reminder.title);
    _descriptionController = TextEditingController(text: widget.reminder.description);
    _dateController        = TextEditingController(text: widget.reminder.date);
    _timeController        = TextEditingController(text: widget.reminder.time);
    _locationController    = TextEditingController(text: widget.reminder.location);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Date picker with dark theme and custom color scheme to match the app's style
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4FC3F7),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF121212),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            '${_weekdayName(picked.weekday)}, ${_monthName(picked.month)} ${picked.day}, ${picked.year}';
      });
    }
  }

  // Time picker with 12-hour format and AM/PM, also dark themed to match the date picker
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
            ),
            dialogBackgroundColor: const Color(0xFF121212),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final hour   = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
        final minute = picked.minute.toString().padLeft(2, '0');
        final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
        _timeController.text = '$hour:$minute $period';
      });
    }
  }

  String _weekdayName(int weekday) {
    const names = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return names[weekday - 1];
  }

  String _monthName(int month) {
    const names = ['January','February','March','April','May','June',
                   'July','August','September','October','November','December'];
    return names[month - 1];
  }

  // Edit mode
  void _startEditing() => setState(() => _isEditing = true);

  // Cancel and restore original values and exit edit mode 
  void _cancelEditing() {
    setState(() {
      _titleController.text       = widget.reminder.title;
      _descriptionController.text = widget.reminder.description;
      _dateController.text        = widget.reminder.date;
      _timeController.text        = widget.reminder.time;
      _locationController.text    = widget.reminder.location;
      _isEditing = false;
    });
  }

  Future<void> _saveEditing() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Title cannot be empty',
            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Color.fromARGB(255, 42, 42, 42),
        ),
      );
      return;
    }

    // Write updated values back onto the shared Reminder object
    widget.reminder.title       = _titleController.text.trim();
    widget.reminder.description = _descriptionController.text.trim();
    widget.reminder.date        = _dateController.text.trim();
    widget.reminder.time        = _timeController.text.trim();
    widget.reminder.location    = _locationController.text.trim();

    await ReminderData.updateReminder(widget.reminder);

    if (!mounted) return;
    setState(() => _isEditing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Reminder updated',
          style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Color.fromARGB(255, 42, 42, 42),
      ),
    );
  }

  // Delete the reminder and pop back to the list page with a "true" result to trigger refresh
  Future<void> _deleteReminder() async {
    await ReminderData.deleteReminder(widget.reminder);
    if (context.mounted) Navigator.of(context).pop(true);
  }

  Widget _viewField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(value.isNotEmpty ? value : 'Not set.',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }

  Widget _editTextField(String label, TextEditingController controller, {String hint = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 16),
            filled: true,
            fillColor: const Color.fromARGB(255, 42, 42, 42),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _editPickerField(String label, TextEditingController controller,
      IconData icon, VoidCallback onTap, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
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
                    builder: (_, value, __) => Text(
                      value.text.isEmpty ? hint : value.text,
                      style: TextStyle(
                        color: value.text.isEmpty ? Colors.white38 : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
          'Reminder Details',
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white70),
              onPressed: _startEditing,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isEditing)
                _editTextField('Title', _titleController, hint: 'Reminder title')
              else
                Text(
                  widget.reminder.title.isNotEmpty ? widget.reminder.title : 'No Title',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),

              const SizedBox(height: 20),

              if (_isEditing)
                _editTextField('Description', _descriptionController,
                    hint: 'Enter description')
              else
                _viewField('Description', widget.reminder.description.isNotEmpty
                    ? widget.reminder.description
                    : 'No description available.'),

              const SizedBox(height: 20),

              if (_isEditing)
                _editPickerField('Date', _dateController,
                    Icons.calendar_today, _pickDate, 'Select date')
              else
                _viewField('Date', widget.reminder.date),

              const SizedBox(height: 20),

              if (_isEditing)
                _editPickerField('Time', _timeController,
                    Icons.access_time, _pickTime, 'Select time')
              else
                _viewField('Time', widget.reminder.time),

              const SizedBox(height: 20),

              if (_isEditing)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationController,
                      onChanged: onSearchChanged, 
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter location',
                        filled: true,
                        fillColor: const Color.fromARGB(255, 42, 42, 42),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (places.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: places.length,
                          itemBuilder: (context, index) {
                            final item = places[index];
                            final text = item['description'];
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
                                  _locationController.text = description;
                                  places.clear();
                                  if (coords != null) {
                                    widget.reminder.placeId = placeId;
                                    widget.reminder.latitude = coords['lat'];
                                    widget.reminder.longitude = coords['lng'];
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Location',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white70),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.reminder.location.isNotEmpty
                                  ? widget.reminder.location
                                  : 'No location set.',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 40),

              if (_isEditing)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4FC3F7),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _saveEditing,
                          child: const Text('Save',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 42, 42, 42),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _cancelEditing,
                          child: const Text('Cancel',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B0000),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _deleteReminder,
                    child: const Text('Delete Reminder',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}