// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import, use_build_context_synchronously, avoid_types_as_parameter_names, no_leading_underscores_for_local_identifiers, non_constant_identifier_names

import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:flutter/physics.dart";
import "package:chatinng/loginpage/auth_services.dart";
import "package:chatinng/loginpage/background_widget.dart";

class Signinpage extends StatefulWidget {
   const Signinpage({super.key});

  @override
  State<Signinpage> createState() => _SigninpageState();
}

class _SigninpageState extends State<Signinpage> {
  String email = '';
  String password = '';  
  String con_password = '';
  final TextEditingController _emailControl = TextEditingController();
  final TextEditingController _passContrl = TextEditingController();
  final TextEditingController _conpassContol = TextEditingController();

void textField(BuildContext context) {
  setState(() {
    final _auth = AuthServices();

    if (_passContrl.text == _conpassContol.text && _passContrl.text.isNotEmpty) {
      if (_emailControl.text.isNotEmpty) {
        _auth.signupwithemailandpass(context, _emailControl.text, _passContrl.text).then((userCredential) {
          if (userCredential != null) {
            Navigator.pushNamed(context, '/login');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Successfully signed in')),
            );
          }
        }).catchError((e) {
          print('${e}');
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e')),
            );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enter email')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords don\'t match')),
      );
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: BackgroundWidget(
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 40),
                    // Original Logo
                    Center(
                      child: Image.asset('assets/images/logo.png',height: 200,width: 200,)
                    ),
                    SizedBox(height: 40),
                    // Title
                    Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 40),
                    // Email Field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                        color: Colors.grey[300]!.withOpacity(0.05),
                      ),
                      child: TextField(
                        controller: _emailControl,
                        style: TextStyle(color: Colors.grey[300]),
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: TextStyle(
                            color: Colors.grey[300]!.withOpacity(0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.email,
                            color: Colors.grey[300]!.withOpacity(0.7),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Password Field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                        color: Colors.grey[300]!.withOpacity(0.05),
                      ),
                      child: TextField(
                        obscureText: true,
                        controller: _passContrl,
                        style: TextStyle(color: Colors.grey[300]),
                        decoration: InputDecoration(
                          hintText: 'New Password',
                          hintStyle: TextStyle(
                            color: Colors.grey[300]!.withOpacity(0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.key,
                            color: Colors.grey[300]!.withOpacity(0.7),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Confirm Password Field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                        color: Colors.grey[300]!.withOpacity(0.05),
                      ),
                      child: TextField(
                        obscureText: true,
                        controller: _conpassContol,
                        style: TextStyle(color: Colors.grey[300]),
                        decoration: InputDecoration(
                          hintText: 'Confirm Password',
                          hintStyle: TextStyle(
                            color: Colors.grey[300]!.withOpacity(0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.key,
                            color: Colors.grey[300]!.withOpacity(0.7),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    // Sign Up Button
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(0xFFD2691E), // Burnt sienna/terracotta color
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () => textField(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    // Login Link
                    Center(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'already registered? ',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                              ),
                            ),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/login');
                                },
                                child: Text(
                                  'login',
                                  style: TextStyle(
                                    color: Color(0xFFD2691E),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 40), // Extra space to prevent white space
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}