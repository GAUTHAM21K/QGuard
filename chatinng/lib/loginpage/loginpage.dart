// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import

import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:chatinng/loginpage/auth_services.dart";
import "package:chatinng/loginpage/background_widget.dart";

class loginPage extends StatefulWidget {
  const loginPage({super.key});

  @override
  State<loginPage> createState() => _loginPageState();
}

class _loginPageState extends State<loginPage> {
  final TextEditingController _emailControl = TextEditingController();
  final TextEditingController _passContrl = TextEditingController();

  @override
  void dispose(){
    _emailControl.dispose();    
    _passContrl.dispose();
    super.dispose();
  }

  void textField(BuildContext context) async{
    final authServices = AuthServices();
    try{
      await authServices.signinwithemailpass(context,_emailControl.text, _passContrl.text );
      Navigator.pushNamed(context, '/homepage');
        }catch(e){
      showDialog(context: context, builder: (context) => const AlertDialog(
        title: Text("invalid password or email"),
      ) );
    }
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
                      'Log In',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 40),
                    // Username Field
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
                          hintText: 'Username',
                          hintStyle: TextStyle(
                            color: Colors.grey[300]!.withOpacity(0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.person,
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
                          hintText: 'Password',
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
                    // Login Button
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
                          'Log In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    // Registration Link
                    Center(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'not registered? ',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                              ),
                            ),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/signin');
                                },
                                child: Text(
                                  'register now',
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