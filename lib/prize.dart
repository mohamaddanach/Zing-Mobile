import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class prize extends StatefulWidget {
  const prize({super.key});

  @override
  State<prize> createState() => _prizeState();
}

class _prizeState extends State<prize> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('prize'),
      ),
    );
  }
}
