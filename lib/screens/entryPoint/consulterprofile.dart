import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_project/main.dart';
import 'package:my_project/screens/entryPoint/components/pick_image.dart';
import 'package:my_project/screens/entryPoint/profileupdate.dart';
import 'package:my_project/screens/onboding/api_constants.dart';
import '../../socket.dart';
import 'package:my_project/notification_service.dart';

class ProfilePage extends StatefulWidget {
  final FlutterSecureStorage storage;

  const ProfilePage({super.key, required this.storage});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage> {
  String usrname = '';
  String email = '';
  String telephone = '';
  String datenaissance = '';
  String namebebe = '';
  String fullname = '';
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchUserData();

  }
  Future<void> _fetchUserData() async {
    final token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse(ApiConstants.profilUrl),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      setState(() {
        usrname = responseData['usrname'] ?? '';
        email = responseData['email'] ?? '';
        telephone = responseData['telephone'] ?? '';
        namebebe = responseData['namebebe'] ?? '';
        fullname = responseData['fullname'] ?? '';
        datenaissance = responseData['datenaissance'] ?? '';
      });
    } else {
      // Gérer l'erreur
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _signOut(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            imageSection,
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Username : ',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                Text(
                  usrname,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Email :',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                Text(
                  email,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 10),
                const Text(
                  'telephone : ',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                Text(
                  telephone,
                  style: const TextStyle(fontSize: 20),
                ),
                if (namebebe.isNotEmpty && fullname.isNotEmpty && datenaissance.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'nom et prenom bebe :',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$namebebe $fullname',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    ' date de naissance:',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    datenaissance,
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateProfilePage(storage: widget.storage),
                  ),
                );

                if (result != null && result is Map<String, String>) {
                  setState(() {
                    usrname = result['usrname'] ?? usrname;
                    email = result['email'] ?? email;
                    telephone = result['telephone'] ?? telephone;
                    namebebe = result['namebebe'] ?? namebebe;
                    fullname = result['fullname'] ?? fullname;
                    datenaissance = result['datenaissance'] ?? datenaissance;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }


}

Widget imageSection = const SizedBox(
  height: 150,
  child: PickImage(),
);
final NotificationService notificationService = NotificationService();

void _stopNotifications() {
  notificationService.cancelAllNotifications();
  print('Notifications stopped');
}
void _signOut(BuildContext context) {
  SocketService.disconnect();

  _stopNotifications();
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const MyApp()),
  );
}
