
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:chatinng/loginpage/background_widget.dart';

class settings extends StatelessWidget {
  const settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:Text('settings'),),
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