
// lib/pages/parent_messenger.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat_room.dart';

class ParentMessenger extends StatefulWidget {
  const ParentMessenger({Key? key}) : super(key: key);

  @override
  _ParentMessengerState createState() => _ParentMessengerState();
}

class _ParentMessengerState extends State<ParentMessenger> {
  List<dynamic> conversations = [];
  String? token;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    if (token != null) {
      _fetchConversations();
    }
  }

  Future<void> _fetchConversations() async {
    try {
      final response = await http.get(
        Uri.parse('https://node-xfev.onrender.com/api/conversations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          conversations = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de chargement des conversations')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchConversations,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : conversations.isEmpty
          ? const Center(
        child: Text(
          'Aucune conversation',
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          final otherParticipant = conversation['participants']
              .firstWhere((p) => p['userId'] != token);

          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  otherParticipant['usrname'][0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                otherParticipant['usrname'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: conversation['lastMessage'] != null
                  ? Text(
                conversation['lastMessage'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
                  : const Text(
                'Nouvelle conversation',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatDate(conversation['lastMessageDate']),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (conversation['unreadCount'] > 0)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        conversation['unreadCount'].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRoom(
                      conversationId: conversation['_id'],
                      otherParticipant: otherParticipant, babyInfo: null,
                    ),
                  ),
                ).then((_) => _fetchConversations());
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewMessageDialog();
        },
        child: const Icon(Icons.message),
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}';
    }
  }

  void _showNewMessageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nouvelle conversation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choisissez un médecin pour démarrer une conversation'),
              FutureBuilder<List<dynamic>>(
                future: _fetchDoctors(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (!snapshot.hasData) {
                    return const Text('Aucun médecin disponible');
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final doctor = snapshot.data![index];
                      return ListTile(
                        title: Text(doctor['usrname']),
                        onTap: () {
                          _createConversation(doctor['_id']);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<dynamic>> _fetchDoctors() async {
    try {
      final response = await http.get(
        Uri.parse('http://votre-api.com/api/doctors'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _createConversation(String doctorId) async {
    try {
      final response = await http.post(
        Uri.parse('http://votre-api.com/api/conversations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'participantId': doctorId,
        }),
      );

      if (response.statusCode == 201) {
        final conversation = json.decode(response.body);
        _fetchConversations();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la création de la conversation'),
        ),
      );
    }
  }
}