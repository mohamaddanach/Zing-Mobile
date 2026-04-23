import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // ADD THIS
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
  final _phonenumber = TextEditingController();
  final _password = TextEditingController();

  String selectedCountry = 'Lebanon';
  List<String> countries = ['Lebanon', 'Qatar', 'UAE', 'KSA'];

  File? _selectedImage;
  Uint8List? _webImage;

  Future<void> _pickImage() async {
    final returnedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnedImage == null) return;

    if (kIsWeb) {
      final bytes = await returnedImage.readAsBytes();
      setState(() => _webImage = bytes);
    } else {
      setState(() => _selectedImage = File(returnedImage.path));
    }
  }

  void handleSignup() async {
    String name = _username.text.trim();
    String pass = _password.text.trim();
    String phone = _phonenumber.text.trim(); // Get the phone number

    if (name.length < 3 || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide a name and phone number")),
      );
      return;
    }
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
    );

    try {
      String sanitizedName = name.replaceAll(' ', '').toLowerCase();
      String fakeEmail = "$sanitizedName@zing.com";

      print("Final Unique Email: $fakeEmail");

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: fakeEmail, password: pass);

      String uid = userCredential.user!.uid;
      String imageUrl = "";

      // 2. Upload Image to Firebase Storage
      if (kIsWeb && _webImage != null) {
        Reference ref = FirebaseStorage.instance.ref().child('user_images').child('$uid.jpg');
        await ref.putData(_webImage!);
        imageUrl = await ref.getDownloadURL();
      } else if (_selectedImage != null) {
        Reference ref = FirebaseStorage.instance.ref().child('user_images').child('$uid.jpg');
        await ref.putFile(_selectedImage!);
        imageUrl = await ref.getDownloadURL();
      }

      if (!mounted) return;

      // 3. Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': name,
        'phone_number': phone,
        'password' : pass,
        'country': selectedCountry,
        'number_of_points': 0,
        'friends': [],
        'role': 'buyer',
        'profile_url': imageUrl,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context); // Close loading spinner

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Success! Account created."), backgroundColor: Colors.green),
      );

      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      String errorMsg = e.message ?? "Signup Failed";
      if (e.code == 'email-already-in-use') {
        errorMsg = "An account with this phone number already exists.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      print("System Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB71C1C), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            children: [
              const Text("ZING Sign Up",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
              const SizedBox(height: 30),

              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: kIsWeb
                      ? (_webImage != null ? MemoryImage(_webImage!) : null) as ImageProvider?
                      : (_selectedImage != null ? FileImage(_selectedImage!) : null) as ImageProvider?,
                  child: (kIsWeb ? _webImage == null : _selectedImage == null)
                      ? const Icon(Icons.person_add, size: 40, color: Colors.blueAccent)
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              const Text("Optional Profile Image", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
              const SizedBox(height: 30),

              _buildTextField(_username, "Your Name", Icons.person_outline),
              const SizedBox(height: 15),
              _buildTextField(_phonenumber, "Phone Number", Icons.phone_android),
              const SizedBox(height: 15),
              _buildTextField(_password, "Password", Icons.lock_outline, obscure: true),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blueAccent, width: 1.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCountry,
                    isExpanded: true,
                    items: countries.map((String country) {
                      return DropdownMenuItem(
                        value: country,
                        child: Text(country, style: const TextStyle(color: Colors.black)),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => selectedCountry = value!),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("CREATE ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueAccent),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }
}