import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:my_project/Home/medecin/liste%20bebe/medecin.dart';
import 'package:my_project/notification_service.dart';

import 'dart:convert'; // Importez la bibliothèque pour travailler avec JSON

import 'package:rive/rive.dart';
import 'package:http/http.dart' as http;
import '../../../../AdminPage.dart';
import '../../../../socket.dart';
import '../../../entryPoint/entry_point.dart';
import '../../api_constants.dart';


class SignInForm extends StatefulWidget {
  const SignInForm({super.key, required this.isArabic, required this.isFrench});

  final bool isArabic;
  final bool isFrench;
  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isSignInDialogShown = true;
  bool isShowLoading = false;
  bool isShowConfetti = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late SMITrigger check;
  late SMITrigger error;
  late SMITrigger reset;
  late SMITrigger confetti;

  final NotificationService notificationService = NotificationService();
  bool _isPasswordVisible = false;

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }
  @override
  void initState() {
    super.initState();
    // Initialize notification service
    notificationService.initialize();
  }
  void _onCheckRiveInit(Artboard artboard) {
    StateMachineController? controller =
    StateMachineController.fromArtboard(artboard, 'State Machine 1');

    artboard.addController(controller!);
    error = controller.findInput<bool>('Error') as SMITrigger;
    check = controller.findInput<bool>('Check') as SMITrigger;
    reset = controller.findInput<bool>('Reset') as SMITrigger;
  }

  void _onConfettiRiveInit(Artboard artboard) {
    StateMachineController? controller =
    StateMachineController.fromArtboard(artboard, "State Machine 1");
    artboard.addController(controller!);
    confetti = controller.findInput<bool>("Trigger explosion") as SMITrigger;
  }

  void signIn(BuildContext context) {
    setState(() {
      isShowLoading = true;
      isShowConfetti = true;
    });
    Future.delayed(const Duration(seconds: 1), () async {

      final String email = _emailController.text;
      final String password = _passwordController.text;
      const storage = FlutterSecureStorage();

// Replace with your server URL

      try {
        final token = await storage.read(key: 'token'); // Récupérer le token du stockage sécurisé

        // Vérifier si le token existe déjà dans le stockage sécurisé

        final response = await http.post(
          Uri.parse(ApiConstants.loginUrl),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'authorization': 'Bearer $token',
          },
          body: json.encode({'email': email, 'password': password}),
        );

        if (response.statusCode == 200) {

          final  responseData = json.decode(response.body);
          final newToken = responseData['token'] ?? ''; // Fournir une valeur par défaut en cas de null
          final String userType = responseData['userType'] ?? '';
          final String userId = responseData['userId'] ?? '';
          final bool isAdmin = responseData['isAdmin'] ?? false;
          if (responseData['isAdmin'] ?? false) {
            // L'utilisateur est un administrateur
            await storage.write(key: 'token', value: newToken);
            await storage.write(key: 'userId', value: userId);
            SocketService.connect(userId);
            check.fire();
            Future.delayed(const Duration(seconds: 2), () async {
              setState(() {
                isShowLoading = false;
              });
              confetti.fire();
              Future.delayed(const Duration(seconds: 1), () async {
                // Redirection vers la page d'administration
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminPage(), // Remplacez AdminPage par votre page d'administration
                  ),
                );
              });
            });
            return;
          }

          if (userType == 'Parent') {
            // Récupérer l'ID du bébé de la réponse
            final String babyId = responseData['bebeId'];

            // Stocker l'ID du bébé dans le stockage sécurisé
            await storage.write(key: 'baby_id', value: babyId);


          }
          await storage.write(key: 'userId', value: userId);

          await storage.write(key: 'token', value: newToken);

          print('Token saved: $storage');// Stocker le nouveau token
          // Connectez-vous au service de socket après une connexion réussie
          SocketService.connect(userId);

          // Écoutez les notifications
          SocketService.invitation((data) async {

            if (data is Map<String, dynamic>) {
              // Handle notifications
              notificationService.showNotification(
                'Invitation reçu',
                'Vous avez reçu une nouvelle invitation',
              );

            } else {
              print('Received data is not in the expected format: $data');
            }
          });
          SocketService.invitationAccepted((data) async {

            if (data is Map<String, dynamic>) {
              // Handle notifications
              notificationService.showNotification(
                'Acceptation reçu',
                'Vous avez reçu une Acceptation',
              );

            } else {
              print('Received data is not in the expected format: $data');
            }
          });
          SocketService.demande((data) async {

            if (data is Map<String, dynamic>) {
              // Handle notifications
              notificationService.showNotification(
                'Demande reçu',
                'Vous avez reçu une demande de rendez-vous',
              );

            } else {
              print('Received data is not in the expected format: $data');
            }
          });
          SocketService.updateAppointment((data) async {

            if (data is Map<String, dynamic>) {
              // Handle notifications
              notificationService.showNotification(
                'Date rendez vous',
                'Vous avez reçu une date de rendez-vous',
              );

            } else {
              print('Received data is not in the expected format: $data');
            }
          });

          SocketService.invitationRejected((data) async {

            if (data is Map<String, dynamic>) {
              // Handle notifications
              notificationService.showNotification(
                'Invitation rejetée',
                'Vous avez reçu un rejet d\'invitation',
              );

            } else {
              print('Received data is not in the expected format: $data');
            }
          });
          // Assurez-vous de déconnecter le socket après avoir terminé

          check.fire();
          Future.delayed(const Duration(seconds: 2), () async {
            setState(() {
              isShowLoading = false;
            });

            confetti.fire();
            Future.delayed(const Duration(seconds: 1), () async {


              // Successful login
              print('Successful login');
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Successful login"),backgroundColor: Colors.green,
                  ));
              if (userType == 'Medecin') {


                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const medecin(),// Replace MedecinPage with the name of your Doctor page
                  ),
                );
              } else if (userType == 'Parent'){

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>   const EntryPoint()
                  ),
                );
              }

            });
          });

        } else {
          ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                content: Text(widget.isArabic
                    ? "حسابك غير نشط أو لم يتم العثور عليه"
                    : widget.isFrench
                    ?"votre compte non active ou introuvable"

                    : "your account not active or not found"),backgroundColor: Colors.red,
              ));
          print('Login error: ${response.body}');

          error.fire();
          Future.delayed(const Duration(seconds: 2), () {
            setState(() {
              isShowLoading = false;
            });
          });
        }
      } catch (e) {
        print('Error during login: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("verifier votre connexion"),backgroundColor: Colors.red,
          ),
        );
        // Handle error
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            isShowLoading = false;
          });
        });
      }

    });
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //text et box email

                Text(
                  widget.isArabic ? "البريد الإلكتروني" : widget.isFrench ? "Email" : "Email",
                  style: const TextStyle(color: Colors.black54),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 24),
                  child: TextFormField(

                    controller: _emailController,
                    validator: (value)  {

                      if (value!.isEmpty) {

                        return widget.isArabic ? "يرجى إدخال بريدك الإلكتروني" : widget.isFrench ? "Veuillez entrer votre mail" : "Please enter your email";
                      }
                      if (!value.contains('@')) {
                        return widget.isArabic ? 'يجب أن يحتوي عنوان البريد الإلكتروني على @' : widget.isFrench ? 'L\'adresse e-mail doit contenir un @' : 'Email address must contain @';
                      }
                      // Utilisation d'une expression régulière pour valider le format de l'e-mail
                      String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
                      RegExp regExp = RegExp(emailPattern);
                      if (!regExp.hasMatch(value)) {
                        return widget.isArabic ? 'الرجاء إدخال عنوان بريد إلكتروني صالح' : widget.isFrench ? 'Veuillez entrer une adresse e-mail valide' : 'Please enter a valid email address';
                      }

                      return null;
                    },

                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: SvgPicture.asset("assets/icons/email.svg"),
                      ),
                      focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(25),
                              topRight: Radius.circular(25),
                              bottomRight: Radius.circular(25),
                              bottomLeft: Radius.circular(25))),
                    ),
                  ),
                ),
                //text et box password
                Text(
                  widget.isArabic ? "كلمة السر" : widget.isFrench ? "Mot de passe" : "Password",
                  style: const TextStyle(color: Colors.black54),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                  child: TextFormField(
                    controller: _passwordController,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return widget.isArabic ? "الرجاء إدخال كلمة السر" : widget.isFrench ? "Veuillez entrer votre mot de passe" : "Please enter your password";
                      }
                      if (value.length < 6) {
                        return widget.isArabic ? 'كلمة المرور غير صالحة' : widget.isFrench ? 'Le mot de passe invalid' : 'Invalid password';
                      }
                      return null;
                    },
                    onSaved: (password) {},
                    obscureText: !_isPasswordVisible, // Met à jour l'obscuration du texte en fonction de l'état de visibilité

                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: SvgPicture.asset("assets/icons/password.svg"),
                      ),
                      suffixIcon: IconButton(
                        onPressed: _togglePasswordVisibility, // Appelle la fonction pour basculer la visibilité du mot de passe
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(25),
                              topRight: Radius.circular(25),
                              bottomRight: Radius.circular(25),
                              bottomLeft: Radius.circular(25))),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 24),
                  child: ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          signIn(context);
                        }
                      },

                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF77D8E),
                          minimumSize: const Size(double.infinity, 56),
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(25),
                                  bottomRight: Radius.circular(25),
                                  bottomLeft: Radius.circular(25)))),
                      icon: const Icon(
                        CupertinoIcons.arrow_right,
                        color: Color(0xFFFE0037),
                      ),
                      label: Text(widget.isArabic ? "تسجيل الدخول" : widget.isFrench ? "Login" : "Sign In")),
                )
              ],
            )),

        isShowLoading
            ? CustomPositioned(
          child: RiveAnimation.asset(
            'assets/RiveAssets/check.riv',
            fit: BoxFit.cover,
            onInit: _onCheckRiveInit,
          ),
        )
            : const SizedBox(),
        isShowConfetti
            ? CustomPositioned(
          scale: 6,
          child: RiveAnimation.asset(
            "assets/RiveAssets/confetti.riv",
            onInit: _onConfettiRiveInit,
            fit: BoxFit.cover,
          ),
        )
            : const SizedBox(),
      ],
    );
  }
}

class CustomPositioned extends StatelessWidget {
  const CustomPositioned({super.key, this.scale = 1, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 100,
            width: 100,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
