import 'package:flutter/material.dart';

import '../signup/singup.dart';
import 'resetpassword.dart';
import 'sign_in_form.dart';

Future<Object?> customSigninDialog(BuildContext context,
    {required ValueChanged onClosed, bool isArabic = false, bool isFrench = false}) {
  String resetText = isArabic ? "إعادة تعيين" : isFrench ? "Réinitialiser" : "Reset";
  String signUpText = isArabic ? "سجل الآن بالبريد الإلكتروني" : isFrench ? "Inscrivez-vous avec e-mail" : "Sign up with Email";
  String signInTitle = isArabic ? "تسجيل الدخول" : isFrench ? "Login" : "Sign In";
  String forgotPasswordText = isArabic ? "نسيت كلمة المرور؟" : isFrench ? "Mot de passe oublié?" : "Forgot Password?";
  String orText = isArabic ? "أو" : isFrench ? "OU" : "OR";

  return showGeneralDialog(
    barrierDismissible: true,
    barrierLabel: "Sign In",
    context: context,
    transitionDuration: const Duration(milliseconds: 400),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      Tween<Offset> tween =
      Tween(begin: const Offset(0, -1), end: Offset.zero);
      return SlideTransition(
        position: tween.animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      );
    },
    pageBuilder: (context, _, __) => Center(
      child: Container(
        height: 620,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: const BorderRadius.all(Radius.circular(40))),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false, // avoid overflow error when keyboard shows up
          body: Stack(
            clipBehavior: Clip.none,
            children: [
              SingleChildScrollView(
                child: Column(children: [
                  Text(
                    signInTitle,
                    style: const TextStyle(
                      fontSize: 40,
                      fontFamily: "Outfit",
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 8),
                    child: Text(
                      '_____________',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                   SignInForm( isArabic: isArabic,
                     isFrench: isFrench,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        forgotPasswordText,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>  ResetPasswordPage(isArabic: isArabic,isFrench: isFrench,)),
                          );
                        },

                        child: Text(resetText),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          orText,
                          style: const TextStyle(color: Colors.black26),
                        ),
                      ),
                      const Expanded(
                        child: Divider(),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Text(
                      signUpText,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                   signup( isArabic: isArabic,
                    isFrench: isFrench,),
                ]),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -48,
                child: GestureDetector(
                  onTap: () {
                    // Retour à la page précédente en poppant la route actuelle
                    Navigator.pop(context);
                  },
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.close, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ).then(onClosed);
}
