import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:my_project/screens/onboding/api_constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;

import '../../../notification_service.dart';
import '../../../socket.dart';
import '../invitationn/invitationboutton.dart';

class NotificationPagemedecin extends StatefulWidget {
  const NotificationPagemedecin({super.key});

  @override
  _NotificationPagemedecinState createState() => _NotificationPagemedecinState();
}

class _NotificationPagemedecinState extends State<NotificationPagemedecin> {
  List<dynamic> invitation = [];
  late IO.Socket socket;
  final NotificationService notificationService = NotificationService();
  late String userId;
  String? _selectedInvitationId;
  final _seenInvitationIds = <String>{};

  @override
  void initState() {
    super.initState();
    initializeAsync();
    getSelectedInvitationId().then((value) {
      setState(() {
        _selectedInvitationId = value;
      });
    });
    loadSeenInvitations();
  }

  Future<void> initializeAsync() async {
    notificationService.initialize();
    const storage = FlutterSecureStorage();
    userId = await storage.read(key: 'userId') ?? '';

    SocketService.connect(userId);
    socket = SocketService.socket;
    getInvitationsByUserId(); // Appeler ici pour charger les invitations dès que la page est ouverte

    SocketService.invitation((data) {
      if (mounted) {
        setState(() {
          invitation.add(data);
          notificationService.showNotification(
            'Invitation reçue',
            'Vous avez reçu une nouvelle invitation',
          );
        });
        socket.emit("new invitation", data);

      }
    });
  }

  Future<void> getInvitationsByUserId() async {
    const storage = FlutterSecureStorage();
    userId = await storage.read(key: 'userId') ?? '';

    final url = Uri.parse(ApiConstants.invitationsWithReceiverUrl(userId));
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        invitation = json.decode(response.body).cast<Map<String, dynamic>>();
      });
      socket.emit("new invitation", userId);

    } else {
      throw Exception('Échec du chargement des invitations');
    }
  }


  Future<String?> getSelectedInvitationId() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: 'selectedInvitationId');
  }

  Future<void> saveSelectedInvitationId(String? invitationId) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'selectedInvitationId', value: invitationId);
  }

  Future<void> loadSeenInvitations() async {
    const storage = FlutterSecureStorage();
    final String? seenInvitationsJson = await storage.read(key: 'seenInvitations');
    if (seenInvitationsJson != null) {
      setState(() {
        _seenInvitationIds.addAll(json.decode(seenInvitationsJson).cast<String>());
      });
    }
  }

  Future<void> saveSeenInvitations() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'seenInvitations', value: json.encode(_seenInvitationIds.toList()));
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
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tri des invitations dans l'ordre décroissant des dates
    invitation.sort((a, b) => DateTime.parse(b['dateReceived'])
        .compareTo(DateTime.parse(a['dateReceived'])));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 50.0),
          child: Text('Notifications'),
        ),
      ),
      body: invitation.isEmpty
          ? const Center(
        child: Text('Aucune notification'),
      )
          : ListView.builder(
        itemCount: invitation.length,
        itemBuilder: (context, index) {
          final notification = invitation[index];
          final isInvitationSeen = _seenInvitationIds.contains(notification['_id']);
          return Dismissible(
            key: Key(notification['_id']),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              setState(() {
                invitation.removeAt(index);
                _seenInvitationIds.remove(notification['_id']);
                if (_selectedInvitationId == notification['_id']) {
                  _selectedInvitationId = null;
                  saveSelectedInvitationId(null);
                }
              });
              saveSeenInvitations();
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedInvitationId = notification['_id'];
                  _seenInvitationIds.add(notification['_id']);
                });
                saveSelectedInvitationId(notification['_id']);
                saveSeenInvitations();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const invitationboutton(),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isInvitationSeen ? Colors.white : (_selectedInvitationId == notification['_id'] ? Colors.white : Colors.grey.shade300),
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: ListTile(
                  title: FutureBuilder<Map<String, dynamic>>(
                    future: fetchBabyDetails(notification["sender"]),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Chargement...');
                      } else if (snapshot.hasError) {
                        return const Text('Erreur de chargement');
                      } else {
                        final babyDetails = snapshot.data!;
                        final babyName = babyDetails['namebebe'];
                        return Text('Vous avez reçu une invitation de $babyName',style: const TextStyle(fontFamily: "Poppins",fontSize: 15),);
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
            ),
          );
        },
      ),
    );
  }
}
