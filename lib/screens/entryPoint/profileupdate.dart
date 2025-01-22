import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_project/screens/onboding/api_constants.dart';

class UpdateProfilePage extends StatefulWidget {
  final FlutterSecureStorage storage;

  const UpdateProfilePage({super.key, required this.storage});

  @override
  _UpdateProfilePageState createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  TextEditingController usrnameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController telephoneController = TextEditingController();
  TextEditingController namebebeController = TextEditingController();
  TextEditingController fullnameController = TextEditingController();
  TextEditingController datenaissanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final token = await widget.storage.read(key: 'token');
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
        usrnameController.text = responseData['usrname'] ?? '';
        emailController.text = responseData['email'] ?? '';
        telephoneController.text = responseData['telephone'] ?? '';

        // Vérifier si l'utilisateur est un médecin
        if (responseData['type'] == 'medecin') {
          // Si c'est un médecin, masquer les champs spécifiques au bébé
          namebebeController.text = '';
          fullnameController.text = '';
          datenaissanceController.text = '';
        } else {
          // Si c'est un parent ou un autre type d'utilisateur, afficher les données du bébé
          namebebeController.text = responseData['namebebe'] ?? '';
          fullnameController.text = responseData['fullname'] ?? '';
          datenaissanceController.text = responseData['datenaissance'] ?? '';
        }
      });
    } else {
      // Gérer l'erreur
    }
  }

  Future<void> _updateProfile() async {
    final token = await widget.storage.read(key: 'token');
    final response = await http.put(
      Uri.parse(ApiConstants.updateprofilUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'usrname': usrnameController.text,
        'email': emailController.text,
        'telephone': telephoneController.text,
        'namebebe': namebebeController.text,
        'fullname': fullnameController.text,
        'datenaissance': datenaissanceController.text,
      }),
    );

    if (response.statusCode == 200) {
      // Afficher un message de succès à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profil mis à jour avec succès'),
      ));

      // Mettre à jour localement les données du profil dans Flutter
      _fetchUserData();

      // Retourner à la page précédente avec les données mises à jour
      Navigator.pop(context, {
        'usrname': usrnameController.text,
        'email': emailController.text,
        'telephone': telephoneController.text,
        'namebebe': namebebeController.text,
        'fullname': fullnameController.text,
        'datenaissance': datenaissanceController.text,
      });
    } else {
      // Gérer l'erreur
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erreur lors de la mise à jour du profil'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: usrnameController,
                decoration: const InputDecoration(
                    labelText: 'Nom d\'utilisateur'),
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: telephoneController,
                decoration: const InputDecoration(labelText: 'Téléphone'),
              ),
              if (namebebeController.text.isNotEmpty &&
                  fullnameController.text.isNotEmpty &&
                  datenaissanceController.text.isNotEmpty) ...[
                TextFormField(
                  controller: namebebeController,
                  decoration: const InputDecoration(labelText: 'Nom bébé'),
                ),
                TextFormField(
                  controller: fullnameController,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                ),
                TextFormField(
                  controller: datenaissanceController,
                  decoration: const InputDecoration(
                      labelText: 'Date de naissance'),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                child: const Text('Enregistrer les modifications'),
              ),
            ],
          ),
        ),
      ),
    );
  }

}