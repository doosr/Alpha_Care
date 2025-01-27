// lib/pages/doctor_messenger.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_project/Home/medecin/mesengerr/ChatRoom.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../parent/messenger/chat_room.dart';

class DoctorMessenger extends StatefulWidget {
  const DoctorMessenger({Key? key}) : super(key: key);

  @override
  _DoctorMessengerState createState() => _DoctorMessengerState();
}

class _DoctorMessengerState extends State<DoctorMessenger> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> conversations = [];
  List<dynamic> unreadConversations = [];
  String? token;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadToken();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        final allConversations = json.decode(response.body);
        setState(() {
          conversations = allConversations;
          unreadConversations = allConversations.where((conv) => conv['unreadCount'] > 0).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur de chargement des conversations')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultations'),
        backgroundColor: Colors.blue,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Toutes (${conversations.length})',
            ),
            Tab(
              text: 'Non lus (${unreadConversations.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchConversations,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConversationList(conversations),
          _buildConversationList(unreadConversations),
        ],
      ),
    );
  }

  Widget _buildConversationList(List<dynamic> conversationList) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (conversationList.isEmpty) {
      return const Center(
        child: Text(
          'Aucune conversation',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: conversationList.length,
      itemBuilder: (context, index) {
        final conversation = conversationList[index];
        final parent = conversation['participants']
            .firstWhere((p) => p['usertype'] == 'Parent');
        final babyInfo = parent['bebe'] ?? {};

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    parent['usrname'][0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (conversation['unreadCount'] > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        conversation['unreadCount'].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              parent['usrname'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (babyInfo.isNotEmpty)
                  Text(
                    'Bébé: ${babyInfo['namebebe']} (${_calculateAge(babyInfo['datenaissance'])})',
                    style: const TextStyle(fontSize: 12),
                  ),
                Text(
                  conversation['lastMessage'] ?? 'Nouvelle conversation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontStyle: conversation['lastMessage'] == null
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
            trailing: Text(
              _formatDate(conversation['lastMessageDate']),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoom1(
                    conversationId: conversation['_id'],
                    otherParticipant: parent,
                    babyInfo: babyInfo,
                  ),
                ),
              ).then((_) => _fetchConversations());
            },
          ),
        );
      },
    );
  }

  String _calculateAge(String? birthDate) {
    if (birthDate == null) return '';

    final birth = DateTime.parse(birthDate);
    final now = DateTime.now();
    final months = (now.year - birth.year) * 12 + now.month - birth.month;

    if (months < 1) {
      final days = now.difference(birth).inDays;
      return '$days jours';
    } else if (months < 24) {
      return '$months mois';
    } else {
      final years = months ~/ 12;
      return '$years ans';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';

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
}