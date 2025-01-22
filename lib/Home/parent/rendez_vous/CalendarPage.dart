import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:my_project/screens/onboding/api_constants.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  TextEditingController babyNameController = TextEditingController();
  TextEditingController doctorController = TextEditingController();
  TextEditingController appointmentObjectController = TextEditingController();
  String lastVisitDateTime = 'Aucune visite précédente';
  @override
  void initState() {
    super.initState();
    getLastVisitDateTime();
  }

  Future<void> getLastVisitDateTime() async {
    const storage = FlutterSecureStorage();
    final userId = await storage.read(key: 'userId');

    if (userId != null) {
      final apiUrl = '${ApiConstants.appointmentsUrl}?senderId=$userId';

      try {
        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data.isNotEmpty && data['appointments'].isNotEmpty) {
            setState(() {
              lastVisitDateTime = data['appointments'][0]['lastVisitDateTime'] ?? 'Aucune visite précédente';
            });
          } else {
            setState(() {
              lastVisitDateTime = 'Aucune visite précédente';
            });
          }
        } else {
          // Gérer les erreurs ici
          print('Failed to fetch last visit datetime from API. Status code: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
      } catch (e) {
        print('Error: $e');
      }
    } else {
      print('User ID not found in storage');
    }
  }




  Future<void> sendAppointmentRequest() async {
    const apiUrl = ApiConstants.appointmentsUrl;
    const storage = FlutterSecureStorage();

    try {
      // Récupérer l'identifiant de l'utilisateur depuis le stockage sécurisé
      final userId = await storage.read(key: 'userId');
      print("$userId");
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'babyName': babyNameController.text,
          'doctor': doctorController.text,
          'appointmentObject': appointmentObjectController.text,
          'lastVisitDateTime': lastVisitDateTime == 'Aucune visite précédente' ? null : lastVisitDateTime,
          'senderId': userId, // Inclure le senderId dans la demande de rendez-vous
        }),
      );

      if (response.statusCode == 201) {

        // La demande de rendez-vous a été envoyée avec succès
        print('Appointment request sent successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Demande de rendez-vous envoyée avec succès"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Gérer les erreurs ici
        print('Failed to send appointment request to API. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Nom du médecin non trouvé"),
            backgroundColor: Colors.red,
          ),
        );
        throw Exception('Failed to send appointment request to API');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Cette ligne supprime le bouton de retour
        title: const Padding(
        padding: EdgeInsets.only(left: 50.0),
         child: Text('Prise rendez-vous'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView( // Wrap with SingleChildScrollView
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Demande de rendez-vous',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: babyNameController,
                decoration: const InputDecoration(labelText: 'Nom du bébé'),
              ),
              TextField(
                controller: doctorController,
                decoration: const InputDecoration(labelText: 'Médecin'),
              ),
              TextField(
                controller: appointmentObjectController,
                decoration: const InputDecoration(labelText: 'Objet du rendez-vous'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: sendAppointmentRequest,
                child: const Text('Envoyer la demande de rendez-vous'),
              ),
              const SizedBox(height: 20),
              Text(
                'Dernière date et heure de visite: ${lastVisitDateTime != 'Aucune visite précédente' ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(lastVisitDateTime)) : 'Aucune visite précédente'}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

}