import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
class home extends StatefulWidget {
  const home({super.key});

  @override
  State<home> createState() => _homeState();
}

class _homeState extends State<home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          "Zingo"
        ),
      ),
    );
  }
}
