// ignore_for_file: prefer_const_constructors, unused_import

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:chatinng/firebase_options.dart';
import 'package:chatinng/loginpage/auth_gate.dart';
import 'package:chatinng/loginpage/chatpage.dart';
import 'package:chatinng/loginpage/homepage.dart';
import 'package:chatinng/loginpage/loginpage.dart';
import 'package:chatinng/loginpage/settings.dart';
import 'package:chatinng/loginpage/signinpage.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp (const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      home : authgate(),
      routes: {
        '/login': (context) => loginPage(),
        '/signin': (context) => Signinpage(),
        '/homepage' : (context) => Homepage(),
        '/settings' : (context) => settings(),
      },
      );
    }
}





