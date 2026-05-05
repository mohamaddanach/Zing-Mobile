import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup_screen.dart';
import 'Home_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  String normalizePhone(String phone) {
    return phone
        .trim()
        .replaceAll(" ", "")
        .replaceAll("+", "")
        .replaceAll("-", "");
  }

  void _handleLogin() async {
    String phoneInput = normalizePhone(_phoneController.text);
    String passwordInput = _passwordController.text.trim();

    if (phoneInput.isEmpty || passwordInput.isEmpty) {
      _showError("Please enter both phone and password");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔥 IMPORTANT: must match signup EXACTLY
      String fakeEmail = "$phoneInput@zing.com";

      print("LOGIN DEBUG EMAIL: $fakeEmail");
      print("LOGIN DEBUG PASS: $passwordInput");

      // 🔐 AUTH
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: fakeEmail,
        password: passwordInput,
      );

      String uid = userCredential.user!.uid;

      // 📦 FIRESTORE
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        _showError("User profile missing in database");
        return;
      }

      Map<String, dynamic> userData =
      userDoc.data() as Map<String, dynamic>;

      String username = userData['username'] ?? "";
      String phone = userData['phone_number'] ?? "";
      String country = userData['country'] ?? "";
      String profileUrl = userData['profile_url'] ?? "";
      double points = (userData['number_of_points'] ?? 0).toDouble();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            username: username,
            phone: phone,
            country: country,
            profileUrl: profileUrl,
            points: points,
          ),
        ),
            (route) => false,
      );

    } on FirebaseAuthException catch (e) {
      String message = "Login Failed";

      switch (e.code) {
        case 'user-not-found':
          message = "No account found for this phone";
          break;
        case 'wrong-password':
        case 'invalid-credential':
          message = "Incorrect password";
          break;
        case 'invalid-email':
          message = "Phone format mismatch";
          break;
        default:
          message = e.message ?? "Authentication error";
      }

      _showError(message);

    } catch (e) {
      _showError("System Error: $e");

    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              const Text(
                "ZING",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
              const Text(
                "E-COMMERCE ECOSYSTEM",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 60),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Phone Number",
                        hintStyle: TextStyle(color: Colors.white30),
                        prefixIcon:
                        Icon(Icons.phone, color: Colors.blueAccent),
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Password",
                        hintStyle: TextStyle(color: Colors.white30),
                        prefixIcon:
                        Icon(Icons.lock_outline, color: Colors.blueAccent),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("LOG IN"),
                ),
              ),

              const SizedBox(height: 25),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignupScreen()),
                  );
                },
                child: const Text(
                  "Don't have an account? Signup",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}