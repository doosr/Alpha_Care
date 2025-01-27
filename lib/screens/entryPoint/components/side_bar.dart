import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../Home/medecin/mesengerr/doctor_screen.dart';
import '../../../Home/parent/Scannbebe/scannbebee.dart';
import '../../../Home/parent/cherchermedecin/searchmedecinn.dart';
import '../../../Home/parent/messenger/parent_messenger.dart';
import '../../../Home/parent/notificationparent/notificationparent.dart';
import '../../../Home/parent/rendez_vous/rendezvous.dart';
import '../../../models/menuparendetmedecin.dart';
import '../../../utils/rive_utils.dart';
import '../../onboding/api_constants.dart';
import '../entry_point.dart';
import 'info_card.dart';
import 'side_menu.dart';



class SideBar extends StatefulWidget {

  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}
class _SideBarState extends State<SideBar> {
  Menu selectedSideMenu = sidebarMenus.first;
  // String email = '';
  String usrname = '';
  String userType='';
  late String _message; // Declare _message variable here


  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchUserData();

    // Initialize _message here
    DateTime now = DateTime.now();
    String currentHour = DateFormat('kk').format(now);
    int hour = int.parse(currentHour);

    if (hour >= 5 && hour < 12) {
      _message = 'Bonjour';
    } else if (hour >= 12 && hour <= 17) {
      _message = 'Bon après-midi';
    } else {
      _message = 'Bonne soirée';
    }
  }

  Future<void> _fetchUserData() async {
    final token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse(ApiConstants.pageUrl),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',

      },

    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      setState(() {
        // email = responseData['email'];
        usrname = responseData['usrname'];
        userType=responseData['userType'];
      });
    } else {
      // Gérer l'erreur
    }
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(

      child: Container(
        width: 288,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF17203A),
          borderRadius: BorderRadius.all(
            Radius.circular(30),
          ),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoCard(
                name: usrname,
                bio: userType,

              ),
              Center(
                child: Text(
                  _message,
                  style: const TextStyle()
                      .copyWith(color: Colors.green),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 19, bottom: 16),
                child: Text(
                  "Browse".toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(color: Colors.white70),
                ),
              ),
              ...sidebarMenus.map((menu) => SideMenu(
                menu: menu,
                selectedMenu: selectedSideMenu,
                press: () {
                  RiveUtils.chnageSMIBoolState(menu.rive.status!);
                  setState(() {
                    selectedSideMenu = menu;
                  });

                  if (menu.title == "Home" ) {
                    if(userType=='Parent') {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const EntryPoint()),
                        );
                      });
                    }
                  } else if (menu.title == "Search") {
                    if(userType=='Parent') {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const searchmedecinn()),
                        );
                      });
                    }
                  } else if (menu.title == "ScanBébé") {
                    if(userType=='Parent') {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const scannbebe()),
                        );
                      });
                    }
                  } else if (menu.title == "Rendez_vous") {
                    if(userType=='Parent') {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const rendezvous()),
                        );
                      });
                    }

                  }

                  else if (menu.title == "Messenger") {
                    if(userType=='Parent') {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ParentMessenger()),
                        );
                      });
                    }

                  }
                },

                riveOnInit: (artboard) {
                  menu.rive.status = RiveUtils.getRiveInput(artboard,
                      stateMachineName: menu.rive.stateMachineName);
                },
              )),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 40, bottom: 16),
                child: Text(
                  "History".toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(color: Colors.white70),
                ),
              ),
              ...sidebarMenus2
                  .map((menu) => SideMenu(
                menu: menu,
                selectedMenu: selectedSideMenu,
                press: () {
                  RiveUtils.chnageSMIBoolState(menu.rive.status!);
                  setState(() {
                    selectedSideMenu = menu; // Mettre à jour selectedSideMenu avec l'élément de menu sélectionné
                  });

                  if (menu.title == "Notifications") {
                    Future.delayed(const Duration(milliseconds: 200), () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotificatioParent()),
                      );
                    });
                  }
                },

                riveOnInit: (artboard) {
                  menu.rive.status = RiveUtils.getRiveInput(artboard,
                      stateMachineName: menu.rive.stateMachineName);
                },
              ))
              ,
            ],
          ),
        ),
      ),
    );
  }
}