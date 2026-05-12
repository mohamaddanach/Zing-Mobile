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

  int selectedQty = 1;

  // 🖼 SAFE IMAGE HANDLER
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

      if (value.startsWith("data:image")) {
        final base64Str = value.split(',').last;
        final bytes = base64Decode(base64Str);

        return Image.memory(bytes, fit: BoxFit.cover);
      }

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

  void showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
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
                  child: Column(
                    children: [

                      Row(
                        children: [

                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 70,
                              height: 70,
                              child: buildPrizeImage(images),
                            ),
                          ),

                          const SizedBox(width: 12),

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
                                  "$points points per unit",
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          ElevatedButton(
                            onPressed: () async {

                              int selectedQty = 1;

                              final result = await showDialog<int>(
                                context: context,
                                builder: (context) => StatefulBuilder(
                                  builder: (context, setState) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),

                                    title: const Text("Select Quantity"),

                                    content: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: List.generate(10, (index) {
                                        final num = index + 1;
                                        final selected = selectedQty == num;

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedQty = num;
                                            });
                                          },
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: selected ? Colors.blue : Colors.white,
                                              border: Border.all(color: Colors.blue),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "$num",
                                                style: TextStyle(
                                                  color: selected ? Colors.white : Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),

                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancel"),
                                      ),

                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, selectedQty),
                                        child: const Text("Confirm"),
                                      ),
                                    ],
                                  ),
                                ),
                              );

                              if (result == null) return;

                              final qty = result;

                              final userQuery = await FirebaseFirestore.instance
                                  .collection("users")
                                  .where("phone_number", isEqualTo: widget.userphonenumber)
                                  .limit(1)
                                  .get();

                              if (userQuery.docs.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("User not found")),
                                );
                                return;
                              }

                              final userDoc = userQuery.docs.first;
                              final userRef = userDoc.reference;

                              final userpoints = userDoc.data()['number_of_points'] ?? 0;

                              int totalCost = points * qty;

                              if (userpoints < totalCost) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Not enough points")),
                                );
                                return;
                              }

                              await userRef.update({
                                "number_of_points": userpoints - totalCost
                              });

                              await FirebaseFirestore.instance.collection("users_prizes").add({
                                "winner_name": widget.username,
                                "winner_phone_number": widget.userphonenumber,
                                "winner_country": widget.country,
                                "prize_name": name,
                                "quantity": qty,
                                "total_points_used": totalCost,
                                "check_admin": false,
                                "Date": FieldValue.serverTimestamp(),
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Operation is done")),
                              );
                            },
                            child: const Text("Get"),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

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