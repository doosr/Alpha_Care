import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import du package HTTP
import 'dart:convert';

import '../../api_constants.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage( {super.key, required this.isArabic, required this.isFrench});
final bool isArabic;
final bool isFrench;

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;

  void _resetPassword() async {
    setState(() {
      _isLoading = true;
    });

    String email = _emailController.text.trim();

    // Effectuer une requête HTTP POST vers votre serveur
    try {
      var response = await http.post(
        Uri.parse(ApiConstants.resetPasswordUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        // Succès de la réinitialisation du mot de passe
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title:  Text(
                widget.isArabic
                    ? "تمت إعادة الضبط بنجاح"
                    : widget.isFrench
                    ? "Réinitialisation réussiee"
                    : "Reset successful"),
            content: Text(widget.isArabic
                ? " تم إرسال كلمة المرور إلى $email "
                : widget.isFrench
                ? "Un e-mail de réinitialisation de mot de passe a été envoyé à $email."
                : "A word reset email password was sent to $email "),
            actions: <Widget>[
              TextButton(
                child:  Text(widget.isArabic
                    ? "نعم"
                    : widget.isFrench
                    ? "d'accord"
                    : "Ok"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      } else {
        // Échec de la réinitialisation du mot de passe
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title:  Text(widget.isArabic
                ? "خطأ"
                : widget.isFrench
                ? "Erreur"
                : "Error"),
            content:  Text(widget.isArabic
                ? "حدث خطأ أثناء إعادة تعيين كلمة المرور."
                : widget.isFrench
                ? "Une erreur est survenue lors de la réinitialisation du mot de passe."
                : "An error occurred while resetting the password."),
            actions: <Widget>[
              TextButton(
                child:  Text(widget.isArabic
                    ? "نعم"
                    : widget.isFrench
                    ? "d'accord"
                    : "Ok"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Gestion des erreurs lors de la requête
      print('Error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(
            widget.isArabic
                ? "إعادة تهيئة كلمة المرور"
                : widget.isFrench
                ? "Réinitialisation du mot de passe"
                : "Password reset",style: const TextStyle(fontSize: 18),),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration:  InputDecoration(labelText:
              widget.isArabic ?
              "بريد إلكتروني"
                  : widget.isFrench
              ? "Email"
                  : "Email"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetPassword,
              child:  Text( widget.isArabic ?
              "إعادة تعيين كلمة المرور "
                  : widget.isFrench
                  ? "Réinitialiser le mot de passe"
                  : "Reset password"),
            ),
          ],
        ),
      ),
    );
  }
}
