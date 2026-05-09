import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class PrizePage extends StatefulWidget {
  final String username;
  final String userphonenumber;
  final String country;

  const PrizePage({
    super.key,
    required this.username,
    required this.userphonenumber,
    required this.country,
  });

  @override
  State<PrizePage> createState() => _PrizePageState();
}

class _PrizePageState extends State<PrizePage> {

  // 🖼 SAFE IMAGE HANDLER (same logic as Messages.dart)
  Widget buildPrizeImage(dynamic images) {
    try {
      String value = "";

      if (images is List && images.isNotEmpty) {
        value = images[0].toString();
      } else if (images is String) {
        value = images;
      }

      if (value.isEmpty) {
        return const Icon(Icons.card_giftcard, size: 50);
      }

      // Base64 image
      if (value.startsWith("data:image")) {
        final base64Str = value.split(',').last;
        final bytes = base64Decode(base64Str);

        return Image.memory(bytes, fit: BoxFit.cover);
      }

      // URL image
      if (value.startsWith("http")) {
        return Image.network(
          value,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image),
        );
      }

      return const Icon(Icons.card_giftcard, size: 50);

    } catch (e) {
      return const Icon(Icons.card_giftcard, size: 50);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prizes"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("prizes")
            .orderBy("createdAt", descending: true)
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No prizes available"));
          }

          final prizes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: prizes.length,
            itemBuilder: (context, index) {

              final data = prizes[index].data()
              as Map<String, dynamic>;

              final images = data['images'];
              final name = data['prize_name'] ?? "Prize";
              final points = data['number_of_points_required'] ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [

                      // 🖼 IMAGE
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 70,
                          height: 70,
                          child: buildPrizeImage(images),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // 📄 INFO
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "$points points required",
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 🎁 BUTTON
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {

                          final userQuery = await FirebaseFirestore.instance
                              .collection("users")
                              .where("phone_number" , isEqualTo: widget.userphonenumber)
                              .limit(1)
                              .get();
                          if(userQuery.docs.isEmpty){
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("User not found"))
                            );
                            return;
                          }
                          final userDoc = userQuery.docs.first;
                          final userRef = userDoc.reference;
                          final userpoints = userDoc.data()['number_of_points'] ?? 0;
                          if(userpoints < points){
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("You dont have the enoguh points to get prize"))
                            );
                            return;
                          }
                          await userRef.update({
                            "number_of_points" : userpoints - points
                          });
                          await FirebaseFirestore.instance.collection("users_prizes").add({
                            "winner_name" : widget.username,
                            "winner_phone_number" : widget.userphonenumber,
                            "winner_country" : widget.country,
                            "prize_name" : name,
                            "prize_number_of_points_required" : points,
                            "Date" : FieldValue.serverTimestamp(),
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Congratulations"))
                          );
                        },
                        child: const Text("Get"),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}