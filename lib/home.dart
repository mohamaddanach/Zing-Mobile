import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class home extends StatefulWidget {
  const home({super.key});

  @override
  State<home> createState() => _homeState();
}

class _homeState extends State<home> {

  // 🎯 POINTS
  double calcPoints(Map<String, dynamic> data) {
    double added = (data['added_value'] ?? 0).toDouble();
    double bonus = (data['bonus_reserve'] ?? 0).toDouble();
    return added + bonus;
  }

  // 🖼 IMAGE
  Widget _imageWidget(Map<String, dynamic> data) {
    try {
      final images = data['images'];
      String value;

      if (images is List && images.isNotEmpty) {
        value = images[0].toString();
      } else if (images is String) {
        value = images;
      } else {
        return Image.network("https://via.placeholder.com/150", fit: BoxFit.cover);
      }

      if (value.startsWith("http")) {
        return Image.network(value, fit: BoxFit.cover);
      }

      if (value.contains(",")) {
        value = value.split(",").last;
      }

      return Image.memory(base64Decode(value), fit: BoxFit.cover);

    } catch (_) {
      return Image.network("https://via.placeholder.com/150", fit: BoxFit.cover);
    }
  }

  // 🚀 PURCHASE FUNCTION
  Future<void> processPurchase(
      Map<String, dynamic> productData, int quantity) async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    final firestore = FirebaseFirestore.instance;

    // 🔢 COUNTER
    final counterRef =
    firestore.collection("counters").doc("transactions");

    final newId = await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      int current = 1000;

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        current = (data["last_id"] ?? 1000);
      }

      final next = current + 1;

      transaction.set(
        counterRef,
        {"last_id": next},
        SetOptions(merge: true),
      );

      return next;
    });

    final transactionRef =
    firestore.collection("transactions").doc(newId.toString());

    final financeRef =
    firestore.collection("transaction_finance").doc(newId.toString());

    // 👤 USER DATA
    Map<String, dynamic> userData = {};
    String phone = "";

    final userDoc =
    await firestore.collection("users").doc(user.uid).get();

    if (userDoc.exists && userDoc.data() != null) {
      userData = userDoc.data()!;
      phone = userData['phone_number'] ?? "";
    }

    if (phone.isEmpty) {
      phone = user.phoneNumber ?? "";
    }

    // 💰 CALCULATIONS
    double price = (productData['priceonplatform'] ?? 0).toDouble();
    double total = quantity * price;
    double profit =
        (productData['profit_one_item'] ?? 0).toDouble() * quantity;
    double bonus =
        (productData['bonus_reserve'] ?? 0).toDouble() * quantity;

    double pointsEarned =
        calcPoints(productData) * quantity;

    // ⚡ WRITE TRANSACTIONS
    await Future.wait([
      transactionRef.set({
        "transaction_id": newId,
        "user_id": user.uid,
        "username": userData['username'] ?? "Unknown",
        "phone": phone,
        "country": userData['country'] ?? "",
        "seller_name": productData['seller_name'] ?? "",
        "product_name": productData['product_name'] ?? "",
        "quantity": quantity,
        "total": total,
        "status": "pending",
        "timestamp": FieldValue.serverTimestamp(),
      }),

      financeRef.set({
        "transaction_id": newId,
        "seller_name": productData['seller_name'] ?? "",
        "product_name": productData['product_name'] ?? "",
        "total": total,
        "profit": profit,
        "bonus_reserve": bonus,
        "quantity": quantity,
        "timestamp": FieldValue.serverTimestamp(),
      }),
    ]);

    // ⭐ UPDATE USER POINTS (NEW FEATURE)
    try {
      final usersRef = firestore.collection("users");

      final query = await usersRef
          .where("phone_number", isEqualTo: phone)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final userRef = query.docs.first.reference;

        await firestore.runTransaction((tx) async {
          final snap = await tx.get(userRef);

          final currentPoints =
          (snap.data()?["number_of_points"] ?? 0).toDouble();

          tx.update(userRef, {
            "number_of_points": currentPoints + pointsEarned,
          });
        });
      }
    } catch (e) {
      print("❌ Points update error: $e");
    }
  }

  // 🛒 DIALOG
  void showPurchaseDialog(Map<String, dynamic> data) {
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(data['product_name'] ?? ""),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Quantity",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Text("Price: \$${data['priceonplatform']}"),
            Text("Points: ${calcPoints(data)}"),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Confirm"),
            onPressed: () async {
              final qty = int.tryParse(qtyController.text) ?? 0;
              if (qty <= 0) return;

              Navigator.pop(context);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                const Center(child: CircularProgressIndicator()),
              );

              try {
                await processPurchase(data, qty);

                if (mounted) Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Order placed successfully"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (mounted) Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ $e")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // 🎨 PRODUCT CARD (UI)
  Widget productCard(Map<String, dynamic> data) {
    return Container(
      width: 190,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [

          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                width: double.infinity,
                child: _imageWidget(data),
              ),
            ),
          ),

          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Text(
                    data['product_name'] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    "\$${data['priceonplatform']}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    "${calcPoints(data)} pts",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () => showPurchaseDialog(data),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Buy"),
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

  // 📦 CATEGORY
  Widget categorySection(String title, String collection, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: Colors.red),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          height: 270,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(collection)
                .snapshots(),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, i) {
                  final data =
                  snapshot.data!.docs[i].data()
                  as Map<String, dynamic>;
                  return productCard(data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Zingo",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            const SizedBox(height: 10),

            categorySection(
              "Electronics",
              "products_electronics",
              Icons.devices,
            ),

            categorySection(
              "Fashion",
              "products_fashion",
              Icons.checkroom,
            ),

            categorySection(
              "Home",
              "products_home",
              Icons.home,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}