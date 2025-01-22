import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:my_project/screens/onboding/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  List<dynamic>? appointments;
  DateTime? lastVisitDateTime;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
    _loadLastVisitDateTime();
  }

  Future<void> deleteAppointment(String appointmentId) async {
    bool shouldDelete = await showConfirmationDialog(context);

    if (shouldDelete) {
      final url = Uri.parse('${ApiConstants.appointmentsUrl}/$appointmentId');
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        print('Appointment deleted successfully');
        setState(() {
          appointments!.removeWhere((appointment) =>
          appointment['_id'] == appointmentId);
        });
      } else {
        print('Failed to delete appointment: ${response.statusCode}');
      }
    }
  }

  Future<bool> showConfirmationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Êtes-vous sûr de vouloir supprimer ce rendez-vous ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Non'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Oui'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchAppointments() async {
    const storage = FlutterSecureStorage();
    final userId = await storage.read(key: 'userId');

    if (userId != null) {
      final apiUrl = '${ApiConstants.appointmentsUrl}?doctor=$userId';

      try {
        final response = await http.get(Uri.parse(apiUrl));
        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          setState(() {
            appointments =
                List.from(jsonData['appointments']); // Make a copy of the list
            // Remplacez la ligne dans la fonction _fetchAppointments qui trie la liste appointments par :
            appointments!.sort((a, b) {
              final aDateTime = a['lastVisitDateTime'] != null ? DateTime.parse(a['lastVisitDateTime']) : DateTime.now();
              final bDateTime = b['lastVisitDateTime'] != null ? DateTime.parse(b['lastVisitDateTime']) : DateTime.now();
              return aDateTime.compareTo(bDateTime);
            });

            lastVisitDateTime = jsonData['lastVisitDateTime'] != null
                ? DateTime.parse(jsonData['lastVisitDateTime'])
                : null;
          });
        } else {
          throw Exception('Failed to load appointments');
        }
      } catch (e) {
        print('Error: $e');
      }
    }
  }

  Future<void> _loadLastVisitDateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastVisitDateTimeString = prefs.getString('last_visit_datetime');
    if (lastVisitDateTimeString != null) {
      setState(() {
        lastVisitDateTime = DateTime.parse(lastVisitDateTimeString);
      });
    } else {
      lastVisitDateTime = null;
    }
  }

  Future<void> _saveLastVisitDateTime(DateTime dateTime,
      String appointmentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_visit_datetime', dateTime.toIso8601String());

    // Mettre à jour la dernière date et heure de visite dans la collection des rendez-vous
    await _updateLastVisitDateTime(dateTime, appointmentId);
  }

  Future<void> _updateLastVisitDateTime(DateTime dateTime,
      String appointmentId) async {
    final url = Uri.parse('${ApiConstants.appointmentsUrl}/$appointmentId');
    final body = json.encode({'lastVisitDateTime': dateTime.toIso8601String()});
    final response = await http.put(
        url, headers: {'Content-Type': 'application/json'}, body: body);
    if (response.statusCode == 200) {
      print('Last visit date and time updated successfully');
    } else {
      print(
          'Failed to update last visit date and time: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // Cette ligne supprime le bouton de retour
        title: const Padding(
          padding: EdgeInsets.only(left: 50.0),
          child: Text('Liste de rendez-vous'),
        ),
      ),
      body: appointments == null
          ? const Center(child: CircularProgressIndicator())
          : appointments!.isEmpty
          ? const Center(child: Text('Aucun Rendez-vous'))
          : ListView.builder(
        itemCount: appointments!.length,
        itemBuilder: (context, index) {
          final appointment = appointments![index];
          final hasSelectedDateTime = appointment['selectedDateTime'] != null;
          return Card(
            color: hasSelectedDateTime ? Colors.green[200] : Colors.grey[200],
            child: ListTile(
              title: Text(
                appointment['babyName'],
                style: const TextStyle(fontFamily: "Poppins"),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appointment['appointmentObject']),
                  Text(
                    appointment['lastVisitDateTime'] != null &&
                        appointment['lastVisitDateTime'] is String
                        ? 'Dernière visite: ${DateFormat('yyyy-MM-dd HH:mm')
                        .format(
                        DateTime.parse(appointment['lastVisitDateTime']))}'
                        : 'Aucune visite précédente',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () =>
                        selectDateTime(context, appointment, index),
                    icon: const Icon(Icons
                        .calendar_today), // Remplacez cet icône par celui que vous préférez
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      deleteAppointment(appointment['_id']);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> selectDateTime(BuildContext context, dynamic appointment,
      int index) async {
    final selectedDateTime = await showDateTimePicker(
      context: context,
      initialDateTime: appointment['selectedDateTime'] != null
          ? DateTime.parse(appointment['selectedDateTime'])
          : DateTime.now(),
    );

    if (selectedDateTime != null) {
      setState(() {
        appointments![index]['selectedDateTime'] =
            selectedDateTime.toIso8601String();
        appointments![index]['lastVisitDateTime'] =
            selectedDateTime.toIso8601String();
      });

      print('Selected Date & Time: $selectedDateTime');
      _saveLastVisitDateTime(selectedDateTime, appointments![index]['_id']);
    }
  }


  Future<DateTime?> showDateTimePicker({
    required BuildContext context,
    required DateTime initialDateTime,
  }) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) {
      return null;
    }

    DateTime? finalDateTime;

    while (finalDateTime == null) {
      final selectedTime = await showCustomTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDateTime),
      );

      if (selectedTime == null) {
        return null;
      }

      if (selectedTime.hour < 8 || selectedTime.hour > 18) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Invalid Time'),
              content: const Text('Please select a time between 8 AM and 4 PM.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        finalDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
      }
    }

    return finalDateTime;
  }
  Future<TimeOfDay?> showCustomTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
  }) async {
    TimeOfDay? selectedTime;
    int selectedHour = initialTime.hour;
    int selectedMinute = initialTime.minute;

    // Sélectionner l'heure
    final hour = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Heure'),
          content: SizedBox(
            height: 300,
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(10, (index) {
                  final hour = 8 + index;
                  return ListTile(
                    title: Text('$hour:00'),
                    onTap: () {
                      Navigator.of(context).pop(hour);
                    },
                  );
                }),
              ),
            ),
          ),
        );
      },
    );

    if (hour == null) return null;

    selectedHour = hour;

    // Sélectionner les minutes à partir de 5 minutes
    final minute = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Minute'),
          content: SizedBox(
            height: 300,
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(12, (index) { // 12 minutes, car 60 minutes / 5 minutes = 12
                  final minute = index * 5; // Starting from 0 to 55 by steps of 5
                  return ListTile(
                    title: Text(minute.toString().padLeft(2, '0')),
                    onTap: () {
                      Navigator.of(context).pop(minute);
                    },
                  );
                }),
              ),
            ),
          ),
        );
      },
    );

    if (minute == null) return null;

    selectedMinute = minute;

    selectedTime = TimeOfDay(hour: selectedHour, minute: selectedMinute);

    return selectedTime;
  }

}