import 'package:my_project/main.dart';
import 'package:my_project/screens/onboding/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/Utilisateurs'));
    if (response.statusCode == 200) {
      setState(() {
        users = json.decode(response.body);
      });
    } else {
      print('Failed to fetch users');
    }
  }

  Future<void> deleteUser(String userId) async {
    final response = await http.delete(Uri.parse('${ApiConstants.baseUrl}/Utilisateurs/$userId'));
    if (response.statusCode == 200) {
      setState(() {
        users.removeWhere((user) => user['_id'] == userId);
      });
    } else {
      print('Failed to delete user');
    }
  }
  void _signOut(BuildContext context) {

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MyApp()),
    );
  }
  Future<void> toggleUserActivation(String userId, bool isActive) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/Utilisateurs/$userId/activate'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'isActive': !isActive}),
    );
    if (response.statusCode == 200) {
      setState(() {
        final index = users.indexWhere((user) => user['_id'] == userId);
        if (index != -1) {
          users[index]['isActive'] = !isActive;
        }
      });
    } else {
      print('Failed to update user activation');
    }
  }

  void logout(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login'); // Assuming '/login' is the route for the login or home page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Page'),
        automaticallyImplyLeading: false, // This line removes the back button
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchUsers,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            title: Text(user['usrname']),
            subtitle: Text(user['email']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.info),
                  onPressed: () {
                    showUserDetails(user);
                  },
                ),
                IconButton(
                  icon: Icon(user['isActive'] ? Icons.check_circle : Icons.cancel),
                  color: user['isActive'] ? Colors.green : Colors.red,
                  onPressed: () {
                    toggleUserActivation(user['_id'], user['isActive']);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  onPressed: () {
                    deleteUser(user['_id']);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Détails de l\'utilisateur'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID de l\'utilisateur: ${user['_id']}'),
              Text('Nom d\'utilisateur: ${user['usrname']}'),
              Text('Email: ${user['email']}'),
              Text('Téléphone: ${user['telephone']}'),
              Text('Type d\'utilisateur: ${user['usertype']}'),
              Text('Actif: ${user['isActive'] ? 'Oui' : 'Non'}'),
              if (user['bebe'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informations du bébé:'),
                    Text('ID du bébé: ${user['bebe']['_id']}'),
                    Text('Nom du bébé: ${user['bebe']['namebebe']}'),
                    Text('Nom complet: ${user['bebe']['fullname']}'),
                    Text('Date de naissance: ${user['bebe']['datenaissance']}'),
                    Text('Température du bébé: ${user['bebe']['bebe_temperature']}'),
                    Text('Température ambiante: ${user['bebe']['ambient_temperature']}'),
                    Text('Dernière SpO2: ${user['bebe']['last_spo2']}'),
                    Text('Dernières BPM: ${user['bebe']['last_bpm']}'),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

}
