import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../notification_service.dart'; // Assurez-vous que le chemin d'importation est correct
import '../../../screens/onboding/api_constants.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<dynamic> medecins = [];
  late String token;
  late String senderId; // Ajouter la variable senderId
  late String receiverId; // Ajouter la variable senderId

  Set<String> invitationsSent = {}; // Utilisation d'un ensemble pour éviter les doublons
  late NotificationService notificationService; // Déclarer une variable de type NotificationService

  @override
  void initState() {
    super.initState();
    fetchMedecins();
    getToken();
    notificationService = NotificationService(); // Initialiser la variable notificationService
    notificationService.initialize(); // Initialiser le service de notifications
  }

  Future<void> fetchMedecins() async {
    final response = await http.get(Uri.parse(ApiConstants.TypesMedecinsUrl));

    if (response.statusCode == 200) {
      setState(() {
        medecins = json.decode(response.body);
      });
    } else {
      // Gestion des erreurs
      print('Failed to load medecins');
    }
  }

  Future<void> getToken() async {
    const storage = FlutterSecureStorage();
    token = await storage.read(key: 'token') ?? '';
    senderId = await storage.read(key: 'senderId') ?? ''; // Lire senderId
    receiverId= await storage.read(key: 'receiverId') ?? '';

  }
  void sendInvitation(String receiverId) async {
    if (token.isNotEmpty) {
      // Vérifie si une invitation a déjà été envoyée à ce médecin
      if (!invitationsSent.contains(receiverId)) {
        var requestBody = {
          'senderId': senderId,
          'receiverId': receiverId,
        };

        var headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };

        var response = await http.post(
          Uri.parse(ApiConstants.sendUrl),
          headers: headers,
          body: jsonEncode(requestBody),
        );

        if (response.statusCode == 200) {
          print('Invitation sent successfully');

          // Ajouter l'identifiant du médecin à la liste des invitations envoyées
          invitationsSent.add(receiverId);
          notificationService.showNotification(
            'Nouvelle Invitation',
            'Vous avez envoyé une invitation.',
          );
        } else {
          // Gestion des erreurs
          print('Error sending invitation');
        }
      } else {
        print('Invitation already sent to this doctor');
      }
    } else {
      // Gestion des erreurs
      print('JWT Token or SenderId missing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Cette ligne supprime le bouton de retour
        title: const Padding(
        padding: EdgeInsets.only(left: 50.0),
        child: Text('Recherche Medecin'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: medecins.isEmpty
                ? const Center(
              child: Text(
                'No doctors available',
              ),
            )
                : ListView.builder(
              itemCount: medecins.length,
              itemBuilder: (BuildContext context, int index) {
                final medecin = medecins[index];
                return ListTile(
                  title: Text(
                    medecin['nom'],
                    style: const TextStyle(fontSize: 25),
                  ),
                  subtitle: Text(medecin['type']),
                  trailing: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      if (medecin['id'] != null) {
                        sendInvitation(medecin['id']);
                      } else {
                        // Gestion des erreurs
                        print('Doctor ID not available');
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
