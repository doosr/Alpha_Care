import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../../main.dart';
import '../../../screens/entryPoint/components/baby_measurement_chart.dart';
import '../../../screens/onboding/api_constants.dart';
import '../../../socket.dart';
import '../../parent/abc.dart';
import 'package:my_project/notification_service.dart';

class AcceptedInvitationsPage extends StatefulWidget {
  const AcceptedInvitationsPage({super.key});

  @override
  _AcceptedInvitationsPageState createState() => _AcceptedInvitationsPageState();
}

class _AcceptedInvitationsPageState extends State<AcceptedInvitationsPage> {
  late List<dynamic> acceptedInvitations = [];
  late String token;
  final NotificationService notificationService = NotificationService();
  Timer? _timer;
  @override
  void initState() {
    super.initState();

    getTokenAndFetchInvitations();
    _startTokenExpirationTimer();
  }
  void _stopNotifications() {
    notificationService.cancelAllNotifications();
    print('Notifications stopped');
  }
  void _startTokenExpirationTimer() {
    _timer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _checkTokenExpiration();
    });
  }
  Future<void> _checkTokenExpiration() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final expiryDateStr = await storage.read(key: 'expiryDate');

    if (token == null || expiryDateStr == null) {
      _showTokenExpiredDialog();
      return;
    }

    final expiryDate = DateTime.parse(expiryDateStr);
    if (DateTime.now().isAfter(expiryDate)) {
      _showTokenExpiredDialog();
    }
  }

  void _showTokenExpiredDialog() {

    SocketService.disconnect();
    _stopNotifications();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Session expirée"),
        content: const Text("Votre session a expiré. Veuillez vous reconnecter."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MyApp()),
                    (Route<dynamic> route) => false,
              );
            },
            child: const Text("Se connecter"),
          ),
        ],
      ),
    );
  }
  Future<void> getTokenAndFetchInvitations() async {
    await getToken();
    if (token.isNotEmpty) {
      await fetchAcceptedInvitations();
    } else {
      print('Token not available');
    }
  }

  Future<void> getToken() async {
    const storage = FlutterSecureStorage();
    token = await storage.read(key: 'token') ?? '';
  }

  Future<void> fetchAcceptedInvitations() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.acceptedInvitationsUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is List) {
          setState(() {
            acceptedInvitations = responseData;
          });
        } else {
          throw Exception('Response data is not a list');
        }
      } else {
        throw Exception('Failed to fetch accepted invitations');
      }
    } catch (error) {
      print('Error fetching accepted invitations: $error');
    }
  }

  Future<void> deleteInvitation(String invitationId) async {
    bool shouldDelete = await showConfirmationDialog(context);

    if (shouldDelete) {
      try {
        final response = await http.delete(
          Uri.parse('${ApiConstants.deleteInvitationUrl}/$invitationId'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          // Invitation deleted successfully, update UI
          await fetchAcceptedInvitations();
          setState(() {
            acceptedInvitations.removeWhere((invitation) => invitation['_id'] == invitationId);
          });
          print('Invitation deleted successfully');
        } else {
          throw Exception('Failed to delete invitation');
        }
      } catch (error) {
        print('Error deleting invitation: $error');
      }
    }
  }

  Future<bool> showConfirmationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Êtes-vous sûr de vouloir supprimer cette invitation ?'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Cette ligne supprime le bouton de retour
        title: const Padding(
          padding: EdgeInsets.only(left: 50.0),
          child: Text('Listes bébés'),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                refreshInvitations();
              }),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/Backgrounds/img_1.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: acceptedInvitations.isEmpty
            ? const Center(child: Text('No accepted invitations'))
            : ListView.builder(
          itemCount: acceptedInvitations.length,
          itemBuilder: (BuildContext context, int index) {
            final invitation = acceptedInvitations[index];
            return ListTile(
              title: FutureBuilder(
                future: fetchBabyDetails(invitation['sender']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      final babyDetails = snapshot.data as Map<String, dynamic>;
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7), // Couleur avec opacité
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nom complet du bébé: ${babyDetails['fullname']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Prénom du bébé: ${babyDetails['namebebe']}',
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Date de naissance: ${babyDetails['datenaissance']}',
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    if (invitation != null && invitation.containsKey('_id')) {
                                      deleteInvitation(invitation['_id']);
                                    } else {
                                      print('Invitation is null or does not contain an ID.');
                                    }
                                  },
                                  child: const Text('Delete'),
                                ),
                                // ElevatedButton(
                                //   onPressed: () {
                                //     Navigator.push(
                                //       context,
                                //       MaterialPageRoute(builder: (context) => BabyHealthMonitorPage()),
                                //     );
                                //   },
                                //   child: Text('Mesure'),
                                // ),
                                ElevatedButton(
                                  onPressed: () {
                                    final babyId = babyDetails['babyId'];
                                    if (babyId != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => BabyHealthMonitorPage(babyId: babyId)),
                                      );
                                    } else {
                                      print('babyId is null');
                                    }
                                  },
                                  child: const Text('Mesure'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (babyDetails['babyId'] != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => BabyMeasurementPage(baby_id: babyDetails['babyId'])),
                                      );
                                    } else {
                                      print('babyId is null');
                                    }
                                  },
                                  child: const Text('History'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
  // Fonction pour actualiser les invitations
  void refreshInvitations() {
    setState(() {
      // Réinitialiser la liste des invitations pour recharger les nouvelles invitations
      acceptedInvitations.clear();
    });
    // Appeler la fonction fetchInvitations pour charger les nouvelles invitations
    fetchAcceptedInvitations();
  }

  Future<Map<String, dynamic>> fetchBabyDetails(String senderId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.babyDetailsUrl}/$senderId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch baby details');
      }
    } catch (error) {
      // print('Error fetching baby details: $error');
      rethrow;
    }
  }
  @override
  void dispose() {
    _stopNotifications();
    _timer?.cancel();
    super.dispose();
  }
}
