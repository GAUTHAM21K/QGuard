import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chatinng/loginpage/homepage.dart';
import 'package:chatinng/loginpage/loginpage.dart';
import 'package:chatinng/loginpage/background_widget.dart';

class authgate extends StatelessWidget {
  const authgate({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: BackgroundWidget(
        child: StreamBuilder<User?>(stream: 
        FirebaseAuth.instance.authStateChanges(), 
        builder: (context, snapshot){
          if(snapshot.hasData){
            return  Homepage();
          }
          else{
            return  loginPage();
          }
        }),
      ),
    );
  }
}