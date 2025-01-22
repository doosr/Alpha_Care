import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_project/screens/onboding/api_constants.dart';

class SendBabyIdPage extends StatefulWidget {
  const SendBabyIdPage({super.key});

  @override
  _SendBabyIdPageState createState() => _SendBabyIdPageState();
}

class _SendBabyIdPageState extends State<SendBabyIdPage> {
  final TextEditingController _emailController = TextEditingController();
  String _message = '';

  Future<void> _sendBabyId() async {
    String email = _emailController.text.trim();
    if (email.isNotEmpty) {
      final response = await http.post(
        Uri.parse(ApiConstants.sendBabyIdUrl),
        body: {'email': email},
      );
      if (response.statusCode == 200) {
        setState(() {
          _message = 'L\'identifiant de votre bébé a été envoyé par e-mail.';
        });
      } else {
        setState(() {
          _message = 'Erreur lors de l\'envoi de l\'identifiant du bébé par e-mail.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Envoyer l\'identifiant du bébé'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Adresse e-mail'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendBabyId,
              child: const Text('Envoyer l\'identifiant'),
            ),
            const SizedBox(height: 20),
            Text(_message),
          ],
        ),
      ),
    );
  }
}
