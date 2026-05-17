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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050816),
              Color(0xFF0F172A),
              Color(0xFF111827),
            ],
          ),
        ),
        child: Stack(
          children: [

            // RED GLOW
            Positioned(
              top: -80,
              left: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.18),
                ),
              ),
            ),

            // BLUE GLOW
            Positioned(
              bottom: -100,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.15),
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [

                    // LOGO
                    const Text(
                      "ZING",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "NEXT GENERATION E-COMMERCE",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        letterSpacing: 2,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 50),

                    // LOGIN CARD
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.15),
                            blurRadius: 30,
                            spreadRadius: 1,
                          ),
                        ],
                      ),

                      child: Column(
                        children: [

                          // PHONE
                          TextField(
                            controller: _phoneController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF0B1220),
                              hintText: "Phone Number",
                              hintStyle: const TextStyle(
                                color: Colors.white38,
                              ),
                              prefixIcon: const Icon(
                                Icons.phone_rounded,
                                color: Colors.blueAccent,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // PASSWORD
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF0B1220),
                              hintText: "Password",
                              hintStyle: const TextStyle(
                                color: Colors.white38,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_rounded,
                                color: Colors.redAccent,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE11D48),
                                    Color(0xFFFF4D6D),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed:
                                _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(18),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                    : const Text(
                                  "LOG IN",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                  const SignupScreen(),
                                ),
                              );
                            },
                            child: RichText(
                              text: const TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(
                                  color: Colors.white60,
                                ),
                                children: [
                                  TextSpan(
                                    text: "SIGN UP",
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}