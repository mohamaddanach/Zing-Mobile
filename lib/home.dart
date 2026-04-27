import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

class home extends StatefulWidget {
  const home({super.key});

  @override
  State<home> createState() => _homeState();
}

class _homeState extends State<home> {

  // 🎯 FIX POINTS (2 decimals)
  double calcPoints(data) {
    double added = (data['added_value'] ?? 0).toDouble();
    double bonus = (data['bonus_reserve'] ?? 0).toDouble();
    double total = added + bonus;
    return double.parse(total.toStringAsFixed(2));
  }

  // 🎨 PRODUCT CARD
  Widget productCard(Map<String, dynamic> data) {
    return Container(
      width: 180,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(
              (data['images'] != null && data['images'].isNotEmpty)
                  ? data['images'][0]
                  : "https://via.placeholder.com/150",
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  data['product_name'] ?? "",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),

                Text(
                  data['sub_title'] ?? "",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  "Price: ${data['priceonplatform']} \$",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                Text(
                  "Points: ${calcPoints(data).toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.blue,
                  ),
                ),

                Text(
                  "Seller: ${data['seller_name'] ?? ""}",
                  style: const TextStyle(fontSize: 12),
                ),

                const SizedBox(height: 8),

                // ACTION ROW
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    // BUY BUTTON
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: const Text("Buy"),
                    ),

                    // SAVE + SHARE
                    Row(
                      children: [

                        IconButton(
                          icon: const Icon(Icons.bookmark_border, color: Colors.blue),
                          onPressed: () {},
                        ),

                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.red),
                          onPressed: () {
                            final name = data['product_name'] ?? '';
                            final price = data['priceonplatform'] ?? '';

                            Share.share("$name - $price\$");
                          },
                        ),
                      ],
                    )

                  ],
                )

              ],
            ),
          )
        ],
      ),
    );
  }

  // 📦 CATEGORY SECTION
  Widget categorySection(String title, String collection, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),

        SizedBox(
          height: 320,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(collection)
                .where('status', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
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
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("Zingo"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            categorySection("Electronics", "products_electronics", Colors.blue),
            categorySection("Fashion", "products_fashion", Colors.red),
            categorySection("Home", "products_home", Colors.blue),

          ],
        ),
      ),
    );
  }
}