import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_screen.dart'; // Make sure you created this file!
import 'splash_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ZingApp());
}
class ZingApp extends StatelessWidget {
  const ZingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      // This will be the first screen your users see
      home: const LoginScreen(),
    );
  }
}