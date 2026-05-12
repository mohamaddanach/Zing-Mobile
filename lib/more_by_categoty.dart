import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'purchase_dialog.dart';
import 'transaction_service.dart';

class all_in_one_category extends StatelessWidget {
  final String title;
  final String collection;

  const all_in_one_category({
    super.key,
    required this.title,
    required this.collection,
  });

  // 🖼 SAFE IMAGE HANDLER (FIXED)
  Widget _imageWidget(Map<String, dynamic> data) {
    try {
      final images = data['images'];
      String value = "";

      if (images is List && images.isNotEmpty) {
        value = images.first.toString();
      } else if (images is String) {
        value = images;
      }

      if (value.isEmpty) {
        return Image.network(
          "https://via.placeholder.com/150",
          fit: BoxFit.cover,
        );
      }

      // 🌐 URL IMAGE
      if (value.startsWith("http")) {
        return Image.network(
          value,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Image.network("https://via.placeholder.com/150"),
        );
      }

      // 🧠 BASE64 IMAGE
      if (value.contains(",")) {
        value = value.split(",").last;
      }

      return Image.memory(
        base64Decode(value),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Image.network("https://via.placeholder.com/150"),
      );

    } catch (_) {
      return Image.network(
        "https://via.placeholder.com/150",
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(collection)
            .where('status', isEqualTo: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No products found"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                padding: const EdgeInsets.all(10),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),

                child: Row(
                  children: [

                    // 🖼 IMAGE
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 90,
                        height: 90,
                        child: _imageWidget(data),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 📦 INFO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            data['product_name'] ?? "",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "\$${data['priceonplatform']}",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "${data['bonus_reserve'] ?? 0} pts",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 🛒 BUTTON
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),

                      child: const Text("Buy"),

                      onPressed: () {
                        PurchaseDialog.show(
                          context: context,
                          data: data,
                          onConfirm: (qty, paymentMethod) async {
                            await TransactionService.processPurchase(
                              productData: data,
                              quantity: qty,
                              source: "category_page",
                              paymentMethod: paymentMethod,
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}