// ignore_for_file: prefer_const_constructors, unused_import, unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chatinng/loginpage/auth_services.dart';
import 'package:chatinng/loginpage/chat_services.dart';
import 'package:chatinng/loginpage/chatpage.dart';
import 'package:chatinng/loginpage/drawer.dart';
import 'package:chatinng/loginpage/loginpage.dart';
import 'package:chatinng/loginpage/usertile.dart';
import 'package:chatinng/loginpage/background_widget.dart';

class Homepage extends StatefulWidget {
  Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final AuthServices _authServices = AuthServices();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ChatServices _chatServices = ChatServices();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A), // Dark background
      drawer: drawer(),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey[300]),
        title: Text(
          'Messages',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
             floatingActionButton: Container(
         decoration: BoxDecoration(
           color: Colors.grey[400],
           shape: BoxShape.circle,
           boxShadow: [
             BoxShadow(
               color: Colors.grey[400]!.withOpacity(0.3),
               blurRadius: 10,
               spreadRadius: 2,
             ),
           ],
         ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          tooltip: "add user",
          onPressed: () {
            print('add');
          },
          child: Icon(
            Icons.add,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: BackgroundWidget(
        child: Column(
          children: [
            // Search Bar
            Container(
              margin: EdgeInsets.all(16),
                             decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(25),
                 color: Colors.grey[300]!.withOpacity(0.05),
                 border: Border.all(
                   color: Colors.grey[300]!.withOpacity(0.2),
                   width: 1,
                 ),
               ),
               child: TextField(
                 style: TextStyle(color: Colors.grey[300]),
                 decoration: InputDecoration(
                   hintText: 'Search',
                   hintStyle: TextStyle(
                     color: Colors.grey[300]!.withOpacity(0.5),
                   ),
                   prefixIcon: Icon(
                     Icons.search,
                     color: Colors.grey[300]!.withOpacity(0.7),
                   ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            // Chat List Container
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[300]!.withOpacity(0.05),
                  border: Border.all(
                    color: Colors.grey[300]!.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: buildUserList(),
                ),
              ),
            ),
            // Bottom Navigation
            Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[300]!.withOpacity(0.05),
                border: Border.all(
                  color: Colors.grey[300]!.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.chat, 'Chats', true),
                    _buildNavItem(Icons.people, 'Contacts', false),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected 
            ? Colors.grey[300] 
            : Colors.grey[300]!.withOpacity(0.5),
          size: 24,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected 
              ? Colors.grey[300] 
              : Colors.grey[300]!.withOpacity(0.5),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget buildUserList() {
    return StreamBuilder(
      stream: _chatServices.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading users",
              style: TextStyle(color: Colors.grey[300]),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Colors.grey[300],
            ),
          );
        }
        return ListView(
          padding: EdgeInsets.symmetric(vertical: 8),
          children: snapshot.data!
              .map<Widget>((userData) => buildUserListItem(userData, context))
              .toList(),
        );
      },
    );
  }

  Widget buildUserListItem(Map<String, dynamic> userData, BuildContext context) {
    if (userData['email'] != _auth.currentUser!.email) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[300]!.withOpacity(0.03),
          border: Border.all(
            color: Colors.grey[300]!.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Stack(
            children: [
              // Profile icon with different colors
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getProfileColor(userData['email']),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    userData['email'].isNotEmpty 
                      ? userData['email'][0].toUpperCase() 
                      : 'U',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Online status indicator
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color(0xFF1A1A1A),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            userData['email'],
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Online',
            style: TextStyle(
              color: Colors.grey[300]!.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(DateTime.now()),
                style: TextStyle(
                  color: Colors.grey[300]!.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
              // Unread message badge (example)
              if (userData['email'].contains('leo')) // Example condition
                Container(
                  margin: EdgeInsets.only(top: 4),
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => chatpage(
                  receiverEmail: userData['email'],
                  receiverID: userData['uid'],
                ),
              ),
            );
          },
        ),
      );
    } else {
      return Container();
    }
  }

  Color _getProfileColor(String email) {
    // Generate different colors based on email
    final colors = [
      Color(0xFFFF6B35), // Orange
      Color(0xFF4CAF50), // Green
      Color(0xFF9C27B0), // Purple
      Color(0xFF2196F3), // Blue
      Color(0xFFFF9800), // Orange
    ];
    return colors[email.hashCode % colors.length];
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}