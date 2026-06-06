import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class _AuthColors {
  static const bg = Color(0xFFFAFAFA);
  static const surface = Colors.white;
  static const text = Color(0xFF262626);
  static const grey = Color(0xFF8E8E8E);
  static const divider = Color(0xFFDBDBDB);
  static const blue = Color(0xFF0095F6);
  static const danger = Color(0xFFED4956);
  static const success = Color(0xFF2DAA59);

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

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  String selectedCountry = 'Lebanon';
  final List<String> countries = ['Lebanon', 'Qatar', 'UAE', 'KSA'];

  File? _image;
  Uint8List? _webImage;

  bool loading = false;
  bool _obscurePassword = true;

  Future<void> pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img == null) return;

    if (kIsWeb) {
      _webImage = await img.readAsBytes();
    } else {
      _image = File(img.path);
    }
    setState(() {});
  }

  Future<void> signup() async {
    String name = _username.text.trim();
    String phone = _phone.text.trim();
    String pass = _password.text.trim();

    if (name.length < 3 || phone.isEmpty || pass.length < 6) {
      _show("Fill all fields correctly");
      return;
    }

    setState(() => loading = true);

    try {
      // CHECK IF PHONE ALREADY EXISTS
      QuerySnapshot existing = await FirebaseFirestore.instance
          .collection("users")
          .where("phone_number", isEqualTo: phone)
          .get();

      if (existing.docs.isNotEmpty) {
        setState(() => loading = false);
        _show("Phone number already registered");
        return;
      }

      // AUTH EMAIL FROM PHONE
      String email = "$phone@zing.com";

      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);

      String uid = cred.user!.uid;

      // UPLOAD IMAGE
      String imageUrl = "";

      if (kIsWeb && _webImage != null) {
        final ref = FirebaseStorage.instance.ref("users/$uid.jpg");
        await ref.putData(_webImage!);
        imageUrl = await ref.getDownloadURL();
      } else if (_image != null) {
        final ref = FirebaseStorage.instance.ref("users/$uid.jpg");
        await ref.putFile(_image!);
        imageUrl = await ref.getDownloadURL();
      }

      // SAVE USER
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        "username": name,
        "phone_number": phone,
        "country": selectedCountry,
        "profile_url": imageUrl,
        "number_of_points": 0,
        "friends": [],
        "role": "buyer",
        "created_at": FieldValue.serverTimestamp(),
      });

      setState(() => loading = false);
      _show("Account created successfully", success: true);

      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() => loading = false);
      String msg = "Signup failed";
      if (e.code == 'email-already-in-use') {
        msg = "This phone is already registered";
      } else if (e.code == 'weak-password') {
        msg = "Password is too weak";
      }
      _show(msg);
    } catch (e) {
      setState(() => loading = false);
      _show("Error: $e");
    }
  }

  void _show(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? _AuthColors.success : _AuthColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _username.dispose();
    _phone.dispose();
    _password.dispose();
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
    OutlineInputBorder border({
      Color color = _AuthColors.divider,
      double width = 1,
    }) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return TextField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: keyboardType,
      enableInteractiveSelection: true,
      style: const TextStyle(color: _AuthColors.text, fontSize: 15),
      cursorColor: _AuthColors.text,
      decoration: InputDecoration(
        filled: true,
        fillColor: _AuthColors.bg,
        hintText: hint,
        hintStyle: const TextStyle(color: _AuthColors.grey, fontSize: 15),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: border(),
        enabledBorder: border(),
        focusedBorder: border(color: _AuthColors.text, width: 1.2),
        disabledBorder: border(),
      ),
    );
  }

  // ─────────────── Profile image with gradient ring ───────────────
  Widget _buildProfileImage() {
    final hasImage =
        (kIsWeb && _webImage != null) || (!kIsWeb && _image != null);

    ImageProvider? provider;
    if (kIsWeb && _webImage != null) {
      provider = MemoryImage(_webImage!);
    } else if (!kIsWeb && _image != null) {
      provider = FileImage(_image!);
    }

    return GestureDetector(
      onTap: pickImage,
      child: Stack(
        children: [
          // Gradient story ring
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: _AuthColors.gradient,
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _AuthColors.surface,
              ),
              child: CircleAvatar(
                radius: 52,
                backgroundColor: _AuthColors.bg,
                backgroundImage: provider,
                child: !hasImage
                    ? const Icon(
                  Icons.person,
                  size: 50,
                  color: _AuthColors.grey,
                )
                    : null,
              ),
            ),
          ),

          // Camera badge
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _AuthColors.surface,
              ),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _AuthColors.gradient,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AuthColors.surface,
      appBar: AppBar(
        backgroundColor: _AuthColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _AuthColors.text),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.6),
          child: Container(height: 0.6, color: _AuthColors.divider),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            children: [
              // ─────────── ZING Logo ───────────
              ShaderMask(
                shaderCallback: (bounds) =>
                    _AuthColors.gradient.createShader(bounds),
                child: Text(
                  "ZING",
                  style: GoogleFonts.pacifico(
                    color: Colors.white,
                    fontSize: 48,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Create your account",
                style: TextStyle(
                  color: _AuthColors.grey,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 28),

              // ─────────── Profile picture ───────────
              _buildProfileImage(),
              const SizedBox(height: 10),
              Text(
                "Add profile photo",
                style: TextStyle(
                  color: _AuthColors.blue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 28),

              // ─────────── Username ───────────
              _buildTextField(
                controller: _username,
                hint: "Username",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),

              // ─────────── Phone ───────────
              _buildTextField(
                controller: _phone,
                hint: "Phone number",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              // ─────────── Password ───────────
              _buildTextField(
                controller: _password,
                hint: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 12),

              // ─────────── Country dropdown ───────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _AuthColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _AuthColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.public,
                      color: _AuthColors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCountry,
                          isExpanded: true,
                          dropdownColor: _AuthColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _AuthColors.grey,
                          ),
                          style: const TextStyle(
                            color: _AuthColors.text,
                            fontSize: 15,
                          ),
                          items: countries
                              .map(
                                (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ),
                          )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => selectedCountry = v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Hint line
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  "By signing up, you agree to our Terms and Privacy Policy.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _AuthColors.grey,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ─────────── Create account button ───────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: loading ? null : _AuthColors.gradient,
                    color: loading ? _AuthColors.divider : null,
                  ),
                  child: ElevatedButton(
                    onPressed: loading ? null : signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      "Sign up",
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

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // ─────────── Bottom log-in bar ───────────
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
                "Have an account? ",
                style: TextStyle(color: _AuthColors.grey, fontSize: 13),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      _AuthColors.gradient.createShader(bounds),
                  child: const Text(
                    "Log in",
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