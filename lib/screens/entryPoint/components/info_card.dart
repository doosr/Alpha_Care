import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_project/screens/entryPoint/consulterprofile.dart';


class InfoCard extends StatelessWidget {

  const InfoCard({
    super.key,
    required this.name,
    required this.bio

  });

  final String name;
  final String bio;


  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>  const ProfilePage(storage:FlutterSecureStorage()),
          ),
        );
      },      leading: const CircleAvatar(
      backgroundColor: Colors.white24,
      child: Icon(
        CupertinoIcons.person,
        color: Colors.white,
      ),
    ),
      title: Text(
        name,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        bio,
        style: const TextStyle(color: Colors.white70,fontSize: 10),
      ),
    );
  }
}