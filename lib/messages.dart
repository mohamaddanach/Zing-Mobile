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

class _MessagesState extends State<Messages>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = "";

  // 🌈 Instagram signature gradient
  static const _igGradient = LinearGradient(
    colors: [
      Color(0xFFFEDA75),
      Color(0xFFFA7E1E),
      Color(0xFFD62976),
      Color(0xFF962FBF),
      Color(0xFF4F5BD5),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🎨 Instagram palette
  static const _igBlue = Color(0xFF0095F6);
  static const _igGray = Color(0xFF8E8E8E);
  static const _igLightGray = Color(0xFFEFEFEF);
  static const _igBorder = Color(0xFFDBDBDB);
  static const _igText = Color(0xFF262626);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 🖼 SAFE IMAGE HANDLER
  Widget buildProductImage(Map<String, dynamic>? product,
      {BoxFit fit = BoxFit.cover}) {
    try {
      if (product == null) return _placeholderImage();

      final images = product['images'];
      String value = "";

      if (images is List && images.isNotEmpty) {
        value = images[0].toString();
      } else if (images is String) {
        value = images;
      }

      if (value.isEmpty) return _placeholderImage();

      if (value.startsWith("data:image")) {
        final base64Str = value.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, fit: fit);
      }

      if (value.startsWith("http")) {
        return Image.network(
          value,
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholderImage(),
        );
      }

      return _placeholderImage();
    } catch (e) {
      return _placeholderImage();
    }
  }

  Widget _placeholderImage() {
    return Container(
      color: _igLightGray,
      child: const Icon(Icons.image_outlined, color: _igGray),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 0,
        automaticallyImplyLeading: false,

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),

              // 🔍 Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: _igLightGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                          Icons.search,
                          color: _igGray,
                          size: 20,
                        ),
                      ),

                      Expanded(
                        child: TextField(
                          onChanged: (v) {
                            setState(() {
                              _searchQuery = v.toLowerCase();
                            });
                          },
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: "Search",
                            hintStyle: TextStyle(
                              color: _igGray,
                              fontSize: 14,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 📑 Tabs
              TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                unselectedLabelColor: _igGray,
                indicatorColor: Colors.black,
                indicatorWeight: 2,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: _igLightGray,

                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),

                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),

                tabs: const [
                  Tab(text: "Received"),
                  Tab(text: "Sent"),
                ],
              ),

              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
      body: widget.userphonenumber.isEmpty
          ? const Center(
        child: Text(
          "Phone number not available",
          style: TextStyle(color: _igGray),
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildMessagesList(isReceived: true),
          _buildMessagesList(isReceived: false),
        ],
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
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.black,
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(isReceived);
        }

        final messages = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index].data() as Map<String, dynamic>;
            final productId = msg['product_id'];

            if (productId == null || productId.toString().isEmpty) {
              return const SizedBox();
            }

            final categoryRaw = msg['category'];
            final category =
            (categoryRaw == null || categoryRaw.toString().isEmpty)
                ? "electronics"
                : categoryRaw.toString();

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("products_$category")
                  .doc(productId.toString())
                  .get(),
              builder: (context, productSnap) {
                if (!productSnap.hasData) return const SizedBox();

                final product =
                productSnap.data!.data() as Map<String, dynamic>?;
                if (product == null) return const SizedBox();

                // 🔍 client-side search filter
                if (_searchQuery.isNotEmpty) {
                  final name =
                  (product['product_name'] ?? "").toString().toLowerCase();
                  final sender =
                  (msg['sender_name'] ?? "").toString().toLowerCase();
                  final receiver =
                  (msg['receiver_name'] ?? "").toString().toLowerCase();
                  if (!name.contains(_searchQuery) &&
                      !sender.contains(_searchQuery) &&
                      !receiver.contains(_searchQuery)) {
                    return const SizedBox();
                  }
                }

                return _buildMessageRow(
                  msg: msg,
                  product: product,
                  productId: productId,
                  category: category,
                  isReceived: isReceived,
                );
              },
            );
          },
        );
      },
    );
  }

  // 📝 IG-STYLE DM ROW
  Widget _buildMessageRow({
    required Map<String, dynamic> msg,
    required Map<String, dynamic> product,
    required dynamic productId,
    required String category,
    required bool isReceived,
  }) {
    final displayName = isReceived
        ? (msg['sender_name'] ?? "Unknown").toString()
        : (msg['receiver_name'] ?? msg['receiver_phone'] ?? "Unknown")
        .toString();

    final messageText = msg['message']?.toString() ?? "";
    final hasMessage = messageText.isNotEmpty;

    return InkWell(
      onTap: () => _showProductSheet(
        product: product,
        productId: productId,
        category: category,
        isReceived: isReceived,
        msg: msg,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🖼 Normal rounded-rectangle product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 60,
                color: _igLightGray, // background while image loads
                child: buildProductImage(product),
              ),
            ),
            const SizedBox(width: 12),

            // 📄 NAME + PREVIEW
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        isReceived
                            ? Icons.shopping_bag_outlined
                            : Icons.send_outlined,
                        size: 13,
                        color: _igGray,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hasMessage
                              ? messageText
                              : (product['product_name']?.toString() ??
                              "Shared a product"),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _igGray,
                          ),
                        ),
                      ),
                      Text(
                        " · \$${product['priceonplatform'] ?? 0}",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // 📦 ACTION
            if (isReceived)
              GestureDetector(
                onTap: () {
                  PurchaseDialog.show(
                    context: context,
                    data: product,
                    onConfirm: (qty, paymentMethod) async {
                      await TransactionService.processPurchase(
                        productData: {...product, "category": category},
                        quantity: qty,
                        source: "commission",
                        paymentMethod: paymentMethod,
                        productId: productId,
                        receiverName: msg['sender_name'] ?? "Unknown",
                      );
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _igBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Buy",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              const Icon(
                Icons.check_circle,
                size: 18,
                color: _igGray,
              ),
          ],
        ),
      ),
    );
  }

  // 📭 IG-STYLE EMPTY STATE
  Widget _buildEmptyState(bool isReceived) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Icon(
                isReceived ? Icons.shopping_bag_outlined : Icons.send_outlined,
                size: 42,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              isReceived ? "Your Inbox" : "Nothing sent yet",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isReceived
                  ? "Products shared with you will appear here."
                  : "Products you share with friends will appear here.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _igGray,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🪟 IG-POST STYLE BOTTOM SHEET
  void _showProductSheet({
    required Map<String, dynamic> product,
    required dynamic productId,
    required String category,
    required bool isReceived,
    required Map<String, dynamic> msg,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  // grab handle
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _igBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
                    child: Row(
                      children: [
                        const Text(
                          "Product",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: _igLightGray),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // poster-style author row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    color: _igLightGray,
                                    child: buildProductImage(product),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isReceived
                                        ? (msg['sender_name'] ?? "Shared")
                                        .toString()
                                        : "Shared with ${msg['receiver_name'] ?? msg['receiver_phone'] ?? ""}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.more_horiz, size: 22),
                              ],
                            ),
                          ),

                          // square product image (IG post style)
                          AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              color: const Color(0xFFFAFAFA),
                              child: buildProductImage(product),
                            ),
                          ),

                          // action icons row (IG post)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                            child: Row(
                              children: const [
                                Icon(Icons.favorite_border, size: 28),
                                SizedBox(width: 16),
                                Icon(Icons.chat_bubble_outline, size: 26),
                                SizedBox(width: 16),
                                Icon(Icons.send_outlined, size: 26),
                                Spacer(),
                                Icon(Icons.bookmark_border, size: 28),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // bonus points row
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.stars_rounded,
                                      size: 16,
                                      color: Color(0xFFFFA500),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${product['bonus_reserve'] ?? 0} bonus points",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _igText,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // name + description (IG caption style)
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: _igText,
                                      height: 1.4,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                        "${product['product_name'] ?? ""}  ",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(
                                        text: product['description'] ??
                                            "No description",
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // price
                                Text(
                                  "\$${product['priceonplatform'] ?? 0}",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),

                                // shared message
                                if ((msg['message'] ?? "")
                                    .toString()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _igLightGray,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.chat_bubble_outline,
                                          size: 16,
                                          color: _igGray,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            msg['message'].toString(),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: _igText,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 20),

                                // Buy button with IG gradient
                                if (isReceived)
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      PurchaseDialog.show(
                                        context: context,
                                        data: product,
                                        onConfirm:
                                            (qty, paymentMethod) async {
                                          await TransactionService
                                              .processPurchase(
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
                                    child: Container(
                                      width: double.infinity,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        gradient: _igGradient,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        "Buy Now",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: double.infinity,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: _igLightGray,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: _igGray,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          "Sent",
                                          style: TextStyle(
                                            color: _igGray,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 28),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}