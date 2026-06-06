import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signup_screen.dart';
import 'Home_page.dart';

class _AuthColors {
  static const bg = Color(0xFFFAFAFA);
  static const surface = Colors.white;
  static const text = Color(0xFF262626);
  static const grey = Color(0xFF8E8E8E);
  static const divider = Color(0xFFDBDBDB);
  static const blue = Color(0xFF0095F6);
  static const danger = Color(0xFFED4956);

  static const gradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFFFEDA77),
      Color(0xFFF58529),
      Color(0xFFDD2A7B),
      Color(0xFF8134AF),
      Color(0xFF515BD4),
    ],
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

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
      String fakeEmail = "$phoneInput@zing.com";

      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: fakeEmail,
        password: passwordInput,
      );

      String uid = userCredential.user!.uid;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        _showError("User profile missing in database");
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

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
      SnackBar(
        content: Text(message),
        backgroundColor: _AuthColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─────────────── Instagram-style text field ───────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _AuthColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AuthColors.divider),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: _AuthColors.text,
          fontSize: 15,
        ),
        cursorColor: _AuthColors.text,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: _AuthColors.grey,
            fontSize: 15,
          ),
          prefixIcon: Icon(icon, color: _AuthColors.grey, size: 20),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: _AuthColors.grey,
              size: 20,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AuthColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),

                // ─────────── ZING Logo (gradient + Pacifico) ───────────
                ShaderMask(
                  shaderCallback: (bounds) =>
                      _AuthColors.gradient.createShader(bounds),
                  child: Text(
                    "ZING",
                    style: GoogleFonts.pacifico(
                      color: Colors.white,
                      fontSize: 64,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Next generation e-commerce",
                  style: TextStyle(
                    color: _AuthColors.grey,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 50),

                // ─────────── Phone field ───────────
                _buildTextField(
                  controller: _phoneController,
                  hint: "Phone number",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),

                // ─────────── Password field ───────────
                _buildTextField(
                  controller: _passwordController,
                  hint: "Password",
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),

                const SizedBox(height: 22),

                // ─────────── Log in button (gradient) ───────────
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: _isLoading ? null : _AuthColors.gradient,
                      color: _isLoading ? _AuthColors.divider : null,
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        "Log in",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ─────────── Forgot password ───────────
                GestureDetector(
                  onTap: () {
                    // hook up to forgot-password flow when ready
                  },
                  child: const Text(
                    "Forgot password?",
                    style: TextStyle(
                      color: _AuthColors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ─────────── OR divider ───────────


                const SizedBox(height: 28),

                // ─────────── Continue with phone (gradient-ringed) ───────────

              ],
            ),
          ),
        ),
      ),

      // ─────────── Bottom sign-up bar (Instagram-style) ───────────
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: _AuthColors.divider, width: 0.6),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(
                  color: _AuthColors.grey,
                  fontSize: 13,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignupScreen(),
                    ),
                  );
                },
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      _AuthColors.gradient.createShader(bounds),
                  child: const Text(
                    "Sign up",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}