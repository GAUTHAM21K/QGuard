// ignore_for_file: prefer_const_constructors, unnecessary_import, camel_case_types, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:chatinng/loginpage/auth_services.dart';

class drawer extends StatefulWidget {
  drawer({super.key});

  @override
  State<drawer> createState() => _drawerState();
}

class _drawerState extends State<drawer> {
  AuthServices _auth = AuthServices();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Color(0xFF2C2C2C), // Dark olive-green background
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
                              SafeArea(
                  child: Center(
                    child: Image.asset('assets/images/logo.png',height: 200,width: 200,)
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 25, top: 10),
                child: ListTile(
                  title: Text(
                    "HOME",
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  leading: Icon(
                    Icons.home,
                    size: 30,
                    color: Colors.grey[300],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: ListTile(
                  title: Text(
                    "SETTINGS",
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  leading: Icon(
                    Icons.settings,
                    size: 30,
                    color: Colors.grey[300],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
              ),
            ],
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 25, bottom: 25),
                child: ListTile(
                  title: Text(
                    "LOGOUT",
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  leading: Icon(
                    Icons.logout,
                    size: 25,
                    color: Colors.grey[300],
                  ),
                  onTap: () {
                    _auth.signOut();
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/login');
                  },
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}