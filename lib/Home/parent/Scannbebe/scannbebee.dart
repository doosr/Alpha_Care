import 'dart:math';

import 'package:flutter/material.dart';

import 'package:rive/rive.dart';

import 'package:my_project/models/menuparendetmedecin.dart';
import '../../../../screens/entryPoint/components/menu_btn.dart';
import '../../../screens/entryPoint/components/side_bar.dart';
import '../../../screens/onboding/constants.dart';
import 'Scanbebe.dart';




class scannbebe extends StatefulWidget {

  const scannbebe({super.key});

  @override
  State<scannbebe> createState() => _scannbebeState();
}


class _scannbebeState extends State<scannbebe>
    with SingleTickerProviderStateMixin {
  bool isSideBarOpen = false;

  Menu selectedSideMenu = sidebarMenus.first;

  late SMIBool isMenuOpenInput;


  late AnimationController _animationController;
  late Animation<double> scalAnimation;
  late Animation<double> animation;

  @override
  void initState() {
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200))
      ..addListener(
            () {
          setState(() {});
        },
      );
    scalAnimation = Tween<double>(begin: 1, end: 0.8).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.fastOutSlowIn));
    animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.fastOutSlowIn));
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        backgroundColor: backgroundColor2,
        body: Stack(
          children: [
            AnimatedPositioned(
              width: 288,
              height: MediaQuery.of(context).size.height,
              duration: const Duration(milliseconds: 200),
              curve: Curves.fastOutSlowIn,
              left: isSideBarOpen ? 0 : -288,
              top: 0,
              child:  const SideBar(),
            ),
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(
                    1 * animation.value - 30 * (animation.value) * pi / 180),
              child: Transform.translate(
                offset: Offset(animation.value * 265, 0),
                child: Transform.scale(
                  scale: scalAnimation.value,
                  child:  const ClipRRect(
                    borderRadius: BorderRadius.all(
                      Radius.circular(24),
                    ),
                    child: BabyIdPage(),

                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.fastOutSlowIn,
              left: isSideBarOpen ? 220 : 0,
              top: 16,
              child: MenuBtn(
                press: () {
                  isMenuOpenInput.value = !isMenuOpenInput.value;

                  if (_animationController.value == 0) {
                    _animationController.forward();
                  } else {
                    _animationController.reverse();
                  }

                  setState(
                        () {
                      isSideBarOpen = !isSideBarOpen;
                    },
                  );
                },
                riveOnInit: (artboard) {
                  final controller = StateMachineController.fromArtboard(
                      artboard, "State Machine");

                  artboard.addController(controller!);

                  isMenuOpenInput =
                  controller.findInput<bool>("isOpen") as SMIBool;
                  isMenuOpenInput.value = true;

                },
              ),
            ),
          ],
        ));

  }
}

