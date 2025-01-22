import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../notification_service.dart';
import '../../../screens/onboding/api_constants.dart';

class InvitationsPage extends StatefulWidget {
  const InvitationsPage({super.key});

  @override
  _InvitationsPageState createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  String token = '';
  List<dynamic> invitations = [];
  List<dynamic> allInvitations = []; // Backup of all invitations
  List<dynamic> acceptedInvitations = [];
  List<dynamic> rejectedInvitations = [];
  List<dynamic> pendingInvitations = [];
  late NotificationService notificationService;
  List<String> acceptedInvitationIds = [];
  TextEditingController searchController = TextEditingController(); // New search controller

  @override
  void initState() {
    super.initState();
    getToken();
    notificationService = NotificationService();
    notificationService.initialize();
    loadAcceptedInvitations();
  }

  @override
  void dispose() {
    super.dispose();
    searchController.dispose(); // Dispose of the search controller
  }

  Future<void> loadAcceptedInvitations() async {
    const storage = FlutterSecureStorage();
    String? acceptedInvitationsJson = await storage.read(key: 'acceptedInvitations');
    List<dynamic> acceptedInvitationsList = json.decode(acceptedInvitationsJson!);
    setState(() {
      acceptedInvitationIds = acceptedInvitationsList.cast<String>();
    });
    }

  Future<void> getToken() async {
    const storage = FlutterSecureStorage();
    token = await storage.read(key: 'token') ?? '';
    fetchInvitations();
  }
  void splitInvitationsByStatus() {
    acceptedInvitations.clear();
    rejectedInvitations.clear();
    pendingInvitations.clear();

    for (var invitation in invitations) {
      if (invitation['status'] == 'accepted') {
        acceptedInvitations.add(invitation);
      } else if (invitation['status'] == 'rejected') {
        rejectedInvitations.add(invitation);
      } else {
        pendingInvitations.add(invitation);
      }
    }
  }
  Future<void> fetchInvitations() async {
    final response = await http.get(
      Uri.parse(ApiConstants.invitationsUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData is List) {
        setState(() {
          invitations = responseData.cast<Map<String, dynamic>>();
          allInvitations = List.from(invitations); // Backup all invitations
          splitInvitationsByStatus(); // Split invitations by status

          fetchBabyNames();
        });
      } else {
        throw Exception('Invalid response format: Expected a list');
      }
    } else {
      throw Exception('Failed to fetch invitations');
    }
  }

  Future<void> fetchBabyNames() async {
    try {
      for (int i = 0; i < invitations.length; i++) {
        final invitation = invitations[i];
        final senderId = invitation['sender'];
        final response = await http.get(
          Uri.parse('${ApiConstants.babyDetailsUrl}/$senderId'),
        );

        if (response.statusCode == 200) {
          final babyDetails = json.decode(response.body);
          final babyName = babyDetails['namebebe'];
          final babyFullName = babyDetails['fullname'];
          final babyDateOfBirth = babyDetails['datenaissance'];
          if (mounted) {
            setState(() {
              invitations[i]['namebebe'] = babyName;
              invitations[i]['fullname'] = babyFullName;
              invitations[i]['datenaissance'] = babyDateOfBirth;
              invitations[i]['dateReceived'] = DateTime.now().toString();
            });
          }
        } else {
          throw Exception('Failed to fetch baby name');
        }
      }
    } catch (e) {
      print('Error fetching baby names: $e');
    }
  }

  Future<void> acceptInvitation(String? invitationId) async {
    if (invitationId == null) {
      print('Invitation ID is null');
      return;
    }

    final response = await http.post(
      Uri.parse(ApiConstants.acceptInvitationUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'invitationId': invitationId}),
    );
    if (response.statusCode == 200) {
      print('Invitation accepted');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invitation acceptée"),
          backgroundColor: Colors.green,
        ),
      );

      final index = invitations.indexWhere((invitation) => invitation['_id'] == invitationId);
      if (index != -1) {
        setState(() {
          invitations[index]['status'] = 'accepted';
        });
      }

      setState(() {
        acceptedInvitationIds.add(invitationId);
      });
      saveAcceptedInvitations();

      notificationService.showNotification(
        'Invitation Acceptée',
        'Vous avez accepté une nouvelle invitation',
      );
    } else {
      print('Error accepting invitation');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de l'acceptation de l'invitation"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> saveAcceptedInvitations() async {
    const storage = FlutterSecureStorage();
    await storage.write(
        key: 'acceptedInvitations', value: json.encode(acceptedInvitationIds));
  }

  Future<void> rejectInvitation(String? invitationId) async {
    if (invitationId == null) {
      print('Invitation ID is null');
      return;
    }

    final response = await http.post(
      Uri.parse(ApiConstants.rejectInvitationUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'invitationId': invitationId}),
    );
    if (response.statusCode == 200) {
      print('Invitation rejetée');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invitation rejetée"),
          backgroundColor: Colors.green,
        ),
      );
      notificationService.showNotification(
        'Un invitation a été supprimée',
        'Vous avez accepté une nouvelle invitation',
      );
    }
    if (response.statusCode != 200) {
      print('Error rejecting invitation');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error rejecting invitation"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildActionButtons(invitation) {
    if (invitation['status'] == 'accepted' || invitation['status'] == 'rejected') {
      return const SizedBox.shrink();
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              acceptInvitation(invitation['_id']);
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              rejectInvitation(invitation['_id']);
              setState(() {
                invitations.removeWhere((element) => element['_id'] == invitation['_id']);
              });
            },
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Cette ligne supprime le bouton de retour
        title: const Padding(
        padding: EdgeInsets.only(left: 50.0),
         child:  Text('Invitations'),),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              refreshInvitations();
            },
          ),
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () {
              makeButtonsVisible();
            },
          ),
        ],
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        invitations = List.from(allInvitations);
                        splitInvitationsByStatus();
                      });
                    },
                    child: Text('Toutes (${allInvitations.length})'),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        invitations = List.from(acceptedInvitations);
                        splitInvitationsByStatus();
                      });
                    },
                    child: Text('Acceptées (${acceptedInvitations.length})'),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        invitations = List.from(rejectedInvitations);
                        splitInvitationsByStatus();
                      });
                    },
                    child: Text('Rejetées (${rejectedInvitations.length})'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher par nom de bébé',
              ),
              onChanged: (value) {
                filterInvitations(value);
              },
            ),
          ),
          Expanded(
            child: invitations.isEmpty
                ? const Center(child: Text('Aucune invitation'))
                : ListView.builder(
              itemCount: invitations.length,
              itemBuilder: (BuildContext context, int index) {
                final invitation = invitations[index];
                final dateReceived = invitation['dateReceived'] ?? 'Non disponible';
                final dateReceivedText = 'Date de réception: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(dateReceived))}';

                Color boxColor = Colors.grey;

                if (invitation['status'] == 'rejected') {
                  boxColor = Colors.redAccent;
                } else if (invitation['status'] == 'accepted') {
                  boxColor = Colors.green;
                }

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: boxColor,
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(
                      'Prenom Bébé: ${invitation['fullname']} \n Nom du bébé: ${invitation['namebebe']}\nDate de naissance: ${invitation['datenaissance']}\n$dateReceivedText',
                    ),
                    subtitle: Text(invitation['status'] == 'rejected'
                        ? 'invitation rejetée'
                        : invitation['status'] == 'accepted'
                        ? 'invitation acceptée'
                        : 'Accepter ou rejeter l\'invitation?'),
                    trailing: buildActionButtons(invitation),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  void makeButtonsVisible() {
    setState(() {
      for (int i = 0; i < invitations.length; i++) {
        if (invitations[i]['status'] == 'accepted' || invitations[i]['status'] == 'rejected') {
          invitations[i]['status'] = 'pending';
        }
      }
    });
  }

  void refreshInvitations() {
    setState(() {
      invitations.clear();
    });
    fetchInvitations();
  }

  // Function to filter invitations based on baby name
  void filterInvitations(String query) {
    if (query.isEmpty) {
      setState(() {
        invitations = List.from(allInvitations); // Restore all invitations
      });
    } else {
      List<dynamic> filteredInvitations = allInvitations.where((invitation) {
        String babyName = invitation['namebebe'].toString().toLowerCase();
        return babyName.contains(query.toLowerCase());
      }).toList();
      setState(() {
        invitations = filteredInvitations;
      });
    }
  }
}
