import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as flutter_widgets;
import 'package:rive/rive.dart' ;
import 'package:my_project/screens/onboding/components/animated_btn.dart';

import 'components/Signin/customSigninDialog.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.locale});
  final Locale locale;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool isSignInDialogShown = false;

  late RiveAnimationController _btnAnimationController;

  @override
  void initState() {
    _btnAnimationController = OneShotAnimation("active", autoplay: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    bool isArabic = widget.locale.languageCode == 'ar';
    bool isFrench = widget.locale.languageCode == 'fr';
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            width: MediaQuery.of(context).size.width * 1.7,
            bottom: 100,
            left: 100,
            child: flutter_widgets.Image.asset('assets/Backgrounds/img.png'),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            ),
          ),
          const RiveAnimation.asset('assets/RiveAssets/shapes.riv'),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: const SizedBox(),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 240),
            top: isSignInDialogShown ? -50 : 0,
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     SizedBox(
                      width: 260,
                      child: Column(
                        children: [
                          Text(
                            isArabic
                                ? "مراقب ذكي للرضع"
                                : isFrench
                                ? "Moniteur Bébé Intelligent"
                                : "Smart Baby Monitor",
                            style: const TextStyle(
                              fontSize: 45,
                              fontFamily: "Poppins",
                              height: 1.2,
                            ),
                          ),
                          Text(
                            isArabic
                                ? "نقترح عليك دائمًا ترك السوار مثبتًا على القشرة الواقية، حتى لو لم تكن تستخدم مراقب الرضع الذكي، وفصله فقط عندما يتطلب نمو طفلك سوارًا أكبر."
                                : isFrench
                                ? "Nous vous conseillons de laisser toujours le bracelet fixé à la languette de sécurité, même si vous n’êtes pas en train d’utiliser le Moniteur Bébé Intelligent, et de la détacher uniquement lorsque la croissance de votre bébé exigera un bracelet plus grand."
                                : "We always recommend leaving the strap fastened to the safety flap, even if you are not using the Smart Baby Monitor, and only detach it when your baby's growth requires a larger strap.",
                          ),
                        ],
                      ),
                    ),
                    const Spacer(
                      flex: 2,
                    ),
                    AnimatedBtn(
                      btnAnimationController: _btnAnimationController,
                      press: () {
                        _btnAnimationController.isActive = true;
                        Future.delayed(
                          const Duration(milliseconds: 800),
                              () {
                            setState(() {
                              isSignInDialogShown = true;
                            });
                            customSigninDialog(
                              context,
                              onClosed: (_) {
                                setState(() {
                                  isSignInDialogShown = false;
                                });
                              },
                              isArabic: isArabic,
                              isFrench: isFrench,
                            );
                          },
                        );
                      },
                      isArabic: isArabic, // Modification ici
                      isFrench: isFrench, // Modification ici
                    ),
                     Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Text(
                        isArabic
                            ? "ثبته بإحكام، واضغط على النواة بيد واحدة باتجاه الساق وضبط السوار باليد الأخرى عن طريق تثبيت الشريط الفيلكرو على القماش."
                            : isFrench
                            ? "Placez-le fermement, en serrant d’une main le noyau vers la jambe et ajustez le bracelet avec l’autre main en fixant la bande velcro au tissu."
                            : "Secure it firmly, press the core with one hand towards the leg and adjust the strap with the other hand by attaching the velcro strip to the fabric.",
                        style: const TextStyle(),
                      ),
                    ),
                    const SizedBox(height: 100,)
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
