import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:my_project/notification_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;

import '../../../screens/onboding/api_constants.dart';
import '../../../socket.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> invitation = [];
  late IO.Socket socket;
  bool _invitationsLoaded = false;

  final NotificationService notificationService = NotificationService();
  late String userId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    if (!_invitationsLoaded) {
      initializeAsync();
    }
  }

  Future<void> initializeAsync() async {
    notificationService.initialize();
    const storage = FlutterSecureStorage();
    userId = await storage.read(key: 'userId') ?? '';

    SocketService.connect(userId);
    socket = SocketService.socket;

    await getInvitationsByUserId(); // Appeler ici pour charger les invitations dès que la page est ouverte

    SocketService.invitationRejected((data) {
      if (mounted) {
        setState(() {
          invitation.add(data);

          notificationService.showNotification(
            'Invitation rejetée',
            'Vous avez reçu un rejet d\'invitation',
          );
        });
        socket.emit("invitationRejected", data);
      }
    });

    SocketService.invitationAccepted((data) {
      if (mounted) {
        setState(() {
          invitation.add(data);

          notificationService.showNotification(
            'Invitation acceptée',
            'Vous avez reçu une invitation acceptée',
          );
        });
        socket.emit("invitationAccepted", data);
      }
    });
  }

  Future<void> getInvitationsByUserId() async {
    const storage = FlutterSecureStorage();
    userId = await storage.read(key: 'userId') ?? '';

    final url = Uri.parse(ApiConstants.invitationsWithUserUrl(userId));
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        invitation = json.decode(response.body).cast<Map<String, dynamic>>();
        _invitationsLoaded = true; // Marquez les invitations comme chargées
      });
      socket.emit("invitationAccepted", userId);
      socket.emit("invitationRejected", userId);
    } else {
      throw Exception('Échec du chargement des invitations');
    }
  }

  Future<Map<String, dynamic>> fetchMedecinDetails(String medecinId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.TypesMedecinsUrl),
      );
      if (response.statusCode == 200) {
        final typesMedecins = json.decode(response.body);
        final medecinDetails = typesMedecins.firstWhere(
              (medecin) => medecin['id'] == medecinId,
          orElse: () => null,
        );
        return medecinDetails ?? {};
      } else {
        throw Exception('Failed to fetch medecin details');
      }
    } catch (error) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    invitation.sort((a, b) => DateTime.parse(b['dateReceived'])
        .compareTo(DateTime.parse(a['dateReceived'])));

    final invitationList = List<Map<String, dynamic>>.from(invitation.where(
            (notification) =>
        notification['status'] == 'accepted' ||
            notification['status'] == 'rejected'));

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 50.0),
          child: Text('Notifications'),
        ),
      ),
      body: invitationList.isEmpty
          ? const Center(
        child: Text('Aucune notification'),
      )
          : ListView.separated(
        itemCount: invitationList.length,
        separatorBuilder: (context, index) => const SizedBox(
            height: 8.0), // Espace vertical entre les notifications
        itemBuilder: (context, index) {
          final notification = invitationList[index];
          final invitationIndex = invitation.indexWhere(
                  (item) => item['_id'] == notification['_id']);
          return Dismissible(
            key: Key(notification['_id']),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              setState(() {
                invitation.removeAt(invitationIndex);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Notification supprimée'),
                  action: SnackBarAction(
                    label: 'Annuler',
                    onPressed: () {
                      setState(() {
                        invitation.insert(invitationIndex, notification);
                      });
                    },
                  ),
                ),
              );
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListTile(
                title: FutureBuilder<Map<String, dynamic>>(
                  future: fetchMedecinDetails(notification["receiver"]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Text('Chargement...');
                    } else if (snapshot.hasError) {
                      return const Text('Erreur de chargement');
                    } else {
                      final medecinDetails = snapshot.data!;
                      final medecinName = medecinDetails['nom'];
                      final isAccepted =
                          notification['status'] == 'accepted';
                      final isRejected =
                          notification['status'] == 'rejected';

                      return Text(
                        isAccepted
                            ? 'Votre invitation a été acceptée par $medecinName'
                            : 'Votre invitation a été rejetée par $medecinName',
                        style: const TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 15,
                        ),
                      );
                    }
                  },
                ),
                subtitle: Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(
                    DateTime.parse(notification["dateReceived"]),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}