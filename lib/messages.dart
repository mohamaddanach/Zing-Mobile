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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Shared with network"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFFD32F2F),
            unselectedLabelColor: Colors.black54,
            indicatorColor: Color(0xFFD32F2F),
            tabs: [
              Tab(
                icon: Icon(Icons.inbox_outlined),
                text: "Received",
              ),
              Tab(
                icon: Icon(Icons.send_outlined),
                text: "Sent",
              ),
            ],
          ),
        ),

        body: widget.userphonenumber.isEmpty
            ? const Center(child: Text("Phone number not available"))
            : TabBarView(
          children: [
            // 📥 TAB 1: RECEIVED (shared with me)
            _buildMessagesList(isReceived: true),

            // 📤 TAB 2: SENT (shared by me)
            _buildMessagesList(isReceived: false),
          ],
        ),
      ),
    );
  }

  // 🔄 REUSABLE LIST BUILDER
  Widget _buildMessagesList({required bool isReceived}) {
    final fieldName = isReceived ? "receiver_phone" : "sender_phone";

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("shared_products")
          .where(fieldName, isEqualTo: widget.userphonenumber)
          .snapshots(),

      builder: (context, snapshot) {

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isReceived ? Icons.inbox_outlined : Icons.send_outlined,
                  size: 60,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  isReceived
                      ? "No messages received yet"
                      : "You haven't shared anything yet",
                  style: TextStyle(color: Colors.grey[600], fontSize: 15),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data!.docs;

        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {

            final msg = messages[index].data() as Map<String, dynamic>;

            final productId = msg['product_id'];

            if (productId == null || productId.toString().isEmpty) {
              return const SizedBox();
            }

            final categoryRaw = msg['category'];

            final category = (categoryRaw == null || categoryRaw.toString().isEmpty)
                ? "electronics"
                : categoryRaw.toString();

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("products_$category")
                  .doc(productId.toString())
                  .get(),

              builder: (context, productSnap) {

                if (!productSnap.hasData) {
                  return const SizedBox();
                }

                final product = productSnap.data!.data() as Map<String, dynamic>?;

                if (product == null) {
                  return const SizedBox();
                }

                return InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) {
                        return Container(
                          height: MediaQuery.of(context).size.height * 0.9,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F0F0F),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: SizedBox(
                                      height: 250,
                                      width: double.infinity,
                                      child: buildProductImage(product),
                                    ),
                                  ),

                                  const SizedBox(height: 15),

                                  Text(
                                    product['product_name'] ?? "",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  Text(
                                    "\$${product['priceonplatform'] ?? 0}",
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  Text(
                                    product['description'] ?? "No description",
                                    style: const TextStyle(color: Colors.grey),
                                  ),

                                  const SizedBox(height: 20),

                                  // Only allow buying from received tab
                                  if (isReceived)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFD32F2F),
                                        minimumSize: const Size(double.infinity, 45),
                                      ),
                                      onPressed: () {
                                        PurchaseDialog.show(
                                          context: context,
                                          data: product,
                                          onConfirm: (qty, paymentMethod) async {
                                            await TransactionService.processPurchase(
                                              productData: {
                                                ...product,
                                                "category": category,
                                              },
                                              quantity: qty,
                                              source: "messages",
                                              paymentMethod: paymentMethod,
                                              productId: productId,
                                            );
                                          },
                                        );
                                      },
                                      child: const Text("Buy Now"),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [

                          // 🖼 IMAGE
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 70,
                              height: 70,
                              child: buildProductImage(product),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // 📄 DETAILS
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Text(
                                  product['product_name'] ?? "Product",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  product['sub_title'] ?? "",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),

                                const SizedBox(height: 6),

                                Row(
                                  children: [
                                    Text(
                                      "\$${product['priceonplatform'] ?? 0}",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "${product['bonus_reserve'] ?? 0} pts",
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                // 👤 SENDER / RECEIVER LABEL
                                Text(
                                  isReceived
                                      ? "From: ${msg['sender_name'] ?? ""}"
                                      : "To: ${msg['receiver_name'] ?? msg['receiver_phone'] ?? ""}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),

                                // ── MESSAGE ─────────────────────────
                                if (msg['message'] != null && msg['message'].toString().isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1976D2).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF1976D2).withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          isReceived
                                              ? Icons.chat_bubble_outline_rounded
                                              : Icons.send_outlined,
                                          color: const Color(0xFF1976D2),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            msg['message'].toString(),
                                            style: const TextStyle(
                                              color: Color(0xFF1976D2),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // 📦 ACTION BUTTON
                          const SizedBox(height: 8),

                          // Show "Buy" only on received; show status badge on sent
                          if (isReceived)
                            ElevatedButton(
                              onPressed: () {
                                PurchaseDialog.show(
                                  context: context,
                                  data: product,
                                  onConfirm: (qty, paymentMethod) async {
                                    await TransactionService.processPurchase(
                                      productData: {
                                        ...product,
                                        "category": category,
                                      },
                                      quantity: qty,
                                      source: "commission",
                                      paymentMethod: paymentMethod,
                                      productId: productId,
                                      receiverName: msg['sender_name'] ?? "Unknown",
                                    );
                                  },
                                );
                              },
                              child: const Text("Buy"),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Sent",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}