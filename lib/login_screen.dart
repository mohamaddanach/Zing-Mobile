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
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    String nameInput = _usernameController.text.trim();
    String passwordInput = _passwordController.text.trim();

    if (nameInput.isEmpty || passwordInput.isEmpty) {
      _showError("Please enter both username and password");
      return;
    }

    setState(() => _isLoading = true);

    try {
      String fakeEmail = "$nameInput@zing.com";

      print("Attempting login for: $fakeEmail");

      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: fakeEmail,
        password: passwordInput,
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        String nameDB = userData['username'] ?? nameInput;
        String passDB = userData['password'] ?? passwordInput;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              username: nameDB,
              password: passDB,
            ),
          ),
              (route) => false,
        );
      } else {
        _showError("User profile not found in database.");
      }

    } on FirebaseAuthException catch (e) {
      String message = "Login Failed";
      if (e.code == 'user-not-found') {
        message = "No account found for '$nameInput'.";
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = "Incorrect password. Please try again.";
      } else {
        message = e.message ?? "An error occurred.";
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Navy
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              const Text("E-COMMERCE ECOSYSTEM",
                  style: TextStyle(color: Colors.blueAccent, fontSize: 12, letterSpacing: 2)),
              const SizedBox(height: 60),

              // Login Card
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
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Username",
                        hintStyle: TextStyle(color: Colors.white30),
                        prefixIcon: Icon(Icons.person_outline, color: Colors.blueAccent),
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
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.blueAccent),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("LOG IN", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 25),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignupScreen()),
                  );
                },
                child: const Text("Don't have an account? Signup",
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}