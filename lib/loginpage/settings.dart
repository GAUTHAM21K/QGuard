import 'package:flutter/material.dart';
import 'package:chatinng/loginpage/background_widget.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings')),
      body: BackgroundWidget(
        child: Center(
          child: Text(
            'Settings Page',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
