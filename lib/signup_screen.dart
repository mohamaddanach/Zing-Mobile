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
      appBar: AppBar(backgroundColor: Colors.red),
      body: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: ListView(
              children: [
                GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: kIsWeb
                        ? (_webImage != null
                        ? MemoryImage(_webImage!)
                        : null)
                        : (_image != null
                        ? FileImage(_image!)
                        : null) as ImageProvider?,
                    child: (_image == null && _webImage == null)
                        ? const Icon(Icons.add_a_photo)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                buildText(_username, "Username", Icons.person),
                const SizedBox(height: 10),

                buildText(_phone, "Phone", Icons.phone),
                const SizedBox(height: 10),

                buildText(_password, "Password", Icons.lock, ob: true),
                const SizedBox(height: 10),

                DropdownButton<String>(
                  value: selectedCountry,
                  isExpanded: true,
                  items: countries
                      .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedCountry = v!),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: signup,
                  child: const Text("SIGN UP"),
                )
              ],
            ),
          ),

          if (loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}