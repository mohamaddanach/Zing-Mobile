import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}
class AppColors {
  static const Color bg = Color(0xFF050816);

  static const Color card = Color(0xFF111827);

  static const Color red = Color(0xFFE11D48);

  static const Color redLight = Color(0xFFFF4D6D);

  static const Color blue = Color(0xFF2563EB);

  static const Color blueLight = Color(0xFF60A5FA);

  static const Color field = Color(0xFF0B1220);
}

class _SignupScreenState extends State<SignupScreen> {
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  String selectedCountry = 'Lebanon';
  List<String> countries = ['Lebanon', 'Qatar', 'UAE', 'KSA'];

  File? _image;
  Uint8List? _webImage;

  bool loading = false;

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
      // 🔥 CHECK IF PHONE ALREADY EXISTS
      QuerySnapshot existing = await FirebaseFirestore.instance
          .collection("users")
          .where("phone_number", isEqualTo: phone)
          .get();

      if (existing.docs.isNotEmpty) {
        setState(() => loading = false);
        _show("Phone number already registered");
        return;
      }

      // 🔥 AUTH EMAIL FROM PHONE
      String email = "$phone@zing.com";

      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);

      String uid = cred.user!.uid;

      // 🔥 UPLOAD IMAGE
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

      // 🔥 SAVE USER
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
        backgroundColor: success ? Colors.green : Colors.red,
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

  Widget buildText(TextEditingController c, String t, IconData i,
      {bool ob = false}) {
    return TextField(
      controller: c,
      obscureText: ob,
      decoration: InputDecoration(
        labelText: t,
        prefixIcon: Icon(i),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,

      body: Stack(
        children: [

          // 🔴 RED GLOW
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.18),
              ),
            ),
          ),

          // 🔵 BLUE GLOW
          Positioned(
            bottom: -120,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.15),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [

                  // BACK BUTTON
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // TITLE
                  const Text(
                    "CREATE ACCOUNT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Join the ZING ecosystem",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 35),

                  // PROFILE IMAGE
                  GestureDetector(
                    onTap: pickImage,
                    child: Stack(
                      children: [

                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.red,
                                AppColors.blue,
                              ],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 58,
                            backgroundColor: AppColors.card,
                            backgroundImage: kIsWeb
                                ? (_webImage != null
                                ? MemoryImage(_webImage!)
                                : null)
                                : (_image != null
                                ? FileImage(_image!)
                                : null) as ImageProvider?,
                            child: (_image == null &&
                                _webImage == null)
                                ? const Icon(
                              Icons.person,
                              size: 55,
                              color: Colors.white54,
                            )
                                : null,
                          ),
                        ),

                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.red,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  blurRadius: 15,
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                  // FORM CARD
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                        ),
                      ],
                    ),

                    child: Column(
                      children: [

                        buildText(
                          _username,
                          "Username",
                          Icons.person,
                        ),

                        const SizedBox(height: 18),

                        buildText(
                          _phone,
                          "Phone Number",
                          Icons.phone,
                        ),

                        const SizedBox(height: 18),

                        buildText(
                          _password,
                          "Password",
                          Icons.lock,
                          ob: true,
                        ),

                        const SizedBox(height: 18),

                        // COUNTRY
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.field,
                            borderRadius:
                            BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              dropdownColor: AppColors.card,
                              value: selectedCountry,
                              isExpanded: true,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                              iconEnabledColor:
                              AppColors.blueLight,
                              items: countries
                                  .map(
                                    (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ),
                              )
                                  .toList(),
                              onChanged: (v) {
                                setState(() {
                                  selectedCountry = v!;
                                });
                              },
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
                              borderRadius:
                              BorderRadius.circular(18),
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.red,
                                  AppColors.redLight,
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
                              onPressed: loading ? null : signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                Colors.transparent,
                                shadowColor:
                                Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(18),
                                ),
                              ),
                              child: loading
                                  ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                                  : const Text(
                                "CREATE ACCOUNT",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Powered by ZING Ecosystem",
                    style: TextStyle(
                      color: Colors.white30,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}