import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'purchase_dialog.dart';
import 'transaction_service.dart';
class Messages extends StatefulWidget {
  final String username;
  final String userphonenumber;
  final String country;

  const Messages({
    super.key,
    required this.username,
    required this.userphonenumber,
    required this.country,
  });

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {

  // 🖼 SAFE IMAGE HANDLER
  Widget buildProductImage(Map<String, dynamic>? product) {
    try {
      if (product == null) return const Icon(Icons.image);

      final images = product['images'];
      String value = "";

      if (images is List && images.isNotEmpty) {
        value = images[0].toString();
      } else if (images is String) {
        value = images;
      }

      if (value.isEmpty) return const Icon(Icons.image);

      // ✅ CASE 1: BASE64 image
      if (value.startsWith("data:image")) {
        final base64Str = value.split(',').last;
        final bytes = base64Decode(base64Str);

        return Image.memory(
          bytes,
          fit: BoxFit.cover,
        );
      }

      // ✅ CASE 2: normal URL
      if (value.startsWith("http")) {
        return Image.network(
          value,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image),
        );
      }

      return const Icon(Icons.image);

    } catch (e) {
      return const Icon(Icons.image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: widget.userphonenumber.isEmpty
          ? const Center(child: Text("Phone number not available"))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("shared_products")
            .where("receiver_phone",
            isEqualTo: widget.userphonenumber)
            .orderBy("timestamp", descending: true)
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No messages yet"));
          }

          final messages = snapshot.data!.docs;

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {

              final msg = messages[index].data()
              as Map<String, dynamic>;

              final productId = msg['product_id'];

              if (productId == null ||
                  productId.toString().isEmpty) {
                return const SizedBox();
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("products_electronics")
                    .doc(productId.toString())
                    .get(),

                builder: (context, productSnap) {

                  if (!productSnap.hasData) {
                    return const SizedBox();
                  }

                  final product = productSnap.data!.data()
                  as Map<String, dynamic>?;

                  if (product == null) {
                    return const SizedBox();
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [

                          // 🖼 IMAGE
                          ClipRRect(
                            borderRadius:
                            BorderRadius.circular(10),
                            child: SizedBox(
                              width: 70,
                              height: 70,
                              child:
                              buildProductImage(product),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // 📄 DETAILS
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [

                                Text(
                                  product['product_name'] ??
                                      "Product",
                                  style: const TextStyle(
                                    fontWeight:
                                    FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  product['sub_title'] ?? "",
                                  style: TextStyle(
                                      color:
                                      Colors.grey[600]),
                                ),

                                const SizedBox(height: 6),

                                Row(
                                  children: [
                                    Text(
                                      "\$${product['priceonplatform'] ?? 0}",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight:
                                        FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "${product['bonus_reserve'] ?? 0} pts",
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight:
                                        FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  "From: ${msg['sender_name'] ?? ""}",
                                  style: const TextStyle(
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),

                          // 📦 STATUS
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              PurchaseDialog.show(
                                context: context,
                                data: product,
                                onConfirm: (qty) async {
                                  await TransactionService.processPurchase(
                                    productData: product,
                                    quantity: qty,
                                    source: "commission",
                                      receiverName: msg['sender_name'] ?? "Unknown",// IMPORTANT DIFFERENCE
                                  );
                                },
                              );
                            },
                            child: const Text("Buy"),
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}