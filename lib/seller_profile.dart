import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:zing/show_products.dart';

class SellerProfile extends StatelessWidget {
  final String sellerName;

  const SellerProfile({
    super.key,
    required this.sellerName,
  });

  // 🟢 Null-safe image decoder
  Widget imageWidget(Map<String, dynamic> data) {
    try {
      final images = data['images'];
      String value;

      if (images != null && images is List && images.isNotEmpty) {
        value = images[0].toString();
      } else if (images is String && images.isNotEmpty) {
        value = images;
      } else {
        return Image.network(
          "https://via.placeholder.com/150",
          fit: BoxFit.cover,
        );
      }

      if (value.startsWith("http")) {
        return Image.network(value, fit: BoxFit.cover);
      }

      if (value.contains(",")) {
        value = value.split(",").last;
      }

      return Image.memory(base64Decode(value), fit: BoxFit.cover);
    } catch (_) {
      return Image.network(
        "https://via.placeholder.com/150",
        fit: BoxFit.cover,
      );
    }
  }

  double calcPoints(Map<String, dynamic> data) {
    final raw = data['bonus_reserve'];
    if (raw == null) return 0;
    if (raw is int) return raw.toDouble();
    if (raw is double) return raw;
    if (raw is String) return double.tryParse(raw) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ── INSTAGRAM-STYLE APP BAR ─────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFEFEFEF), width: 0.5),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.black, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    "Seller Profile",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),

      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection("sellers")
            .where("name", isEqualTo: sellerName)
            .limit(1)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0095F6),
                strokeWidth: 2,
              ),
            );
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront_outlined,
                      color: Colors.grey.shade400, size: 56),
                  const SizedBox(height: 12),
                  Text(
                    "Seller not found",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final seller =
          snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final joinedAt = (seller['joinedAt'] as Timestamp?)?.toDate();
          final year = joinedAt?.year ?? "—";
          final category = seller['product_category'] ?? "electronics";
          final collectionString = "products_$category";

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // ── AVATAR WITH IG STORY-RING GRADIENT ───────
                // ── AVATAR (plain, no story ring) ───────
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFEFEFEF),
                      width: 1,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFFAFAFA),
                    backgroundImage: seller['profile_image'] != null
                        ? NetworkImage(seller['profile_image'])
                        : null,
                    child: seller['profile_image'] == null
                        ? const Icon(Icons.person_rounded,
                        size: 50, color: Color(0xFF8E8E8E))
                        : null,
                  ),
                ),

                const SizedBox(height: 14),

                // ── NAME ─────────────────────────────────────
                Text(
                  seller['name'] ?? "",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 4),

                // ── HANDLE-LIKE SUBTITLE ─────────────────────
                Text(
                  "@${(seller['name'] ?? "").toString().toLowerCase().replaceAll(' ', '_')}",
                  style: const TextStyle(
                    color: Color(0xFF8E8E8E),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 18),

                // ── STATS ROW ────────────────────────────────
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(collectionString)
                      .where("seller_name", isEqualTo: sellerName)
                      .where("status", isEqualTo: true)
                      .snapshots(),
                  builder: (context, snap) {
                    final count = snap.hasData ? snap.data!.docs.length : 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _statItem(count.toString(), "Products"),
                          _verticalDivider(),
                          _statItem("$year", "Joined"),
                          _verticalDivider(),
                          _statItem(
                              seller['country'] ?? "—", "Country"),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // ── FOLLOW / MESSAGE BUTTONS (IG-style) ──────


                const SizedBox(height: 20),

                // ── SECTION DIVIDER (IG-style) ───────────────
                Container(
                  height: 0.5,
                  color: const Color(0xFFEFEFEF),
                ),

                // ── PRODUCTS HEADER ──────────────────────────
                Padding(
                  padding:
                  const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.grid_on_rounded,
                          size: 18, color: Colors.black),
                      const SizedBox(width: 8),
                      const Text(
                        "Products",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "Trending now",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── PRODUCT GRID ─────────────────────────────
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(collectionString)
                      .where("seller_name", isEqualTo: sellerName)
                      .where("status", isEqualTo: true)
                      .snapshots(),
                  builder: (context, productSnap) {
                    if (!productSnap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0095F6),
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }

                    final products = productSnap.data!.docs;

                    if (products.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                color: Colors.grey.shade400, size: 48),
                            const SizedBox(height: 10),
                            Text(
                              "No products listed yet",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final doc = products[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final productId = doc.id;

                        return _productCard(
                          context: context,
                          data: data,
                          productId: productId,
                          collection: collectionString,
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── STAT ITEM (IG-profile style) ─────────────────────
  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8E8E8E),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 0.5,
      height: 28,
      color: const Color(0xFFEFEFEF),
    );
  }

  // ── INSTAGRAM-STYLE PRODUCT CARD ─────────────────────
  Widget _productCard({
    required BuildContext context,
    required Map<String, dynamic> data,
    required String productId,
    required String collection,
  }) {
    return GestureDetector(
      onTap: () {
        ShowProducts.showProductDetails(
          context: context,
          data: data,
          productId: productId,
          collection: collection,
          imageWidget: imageWidget,
          calcPoints: calcPoints,
          shareProduct: (productData, id, col) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    "Use Home interface to share directly with friends"),
              ),
            );
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
        ),
        child: Column(
          children: [
            // ── IMAGE + 3-DOT MENU OVERLAY ─────────────
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: imageWidget(data),
                    ),
                  ),

                  // 3-DOT MENU (top-right, IG-style)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        shape: BoxShape.circle,
                      ),
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_horiz_rounded,
                            color: Colors.black, size: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'view') {
                            ShowProducts.showProductDetails(
                              context: context,
                              data: data,
                              productId: productId,
                              collection: collection,
                              imageWidget: imageWidget,
                              calcPoints: calcPoints,
                              shareProduct: (productData, id, col) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Use Home interface to share directly with friends"),
                                  ),
                                );
                              },
                            );
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_outlined,
                                    size: 18, color: Color(0xFF0095F6)),
                                SizedBox(width: 8),
                                Text(
                                  "View Product",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── INFO SECTION ───────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data['product_name'] ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "\$${data['priceonplatform'] ?? 0}",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(0xFFEFEFEF)),
                          ),
                          child: Text(
                            "${calcPoints(data).toStringAsFixed(0)} pts",
                            style: const TextStyle(
                              color: Color(0xFF8E8E8E),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: () {
                          ShowProducts.showProductDetails(
                            context: context,
                            data: data,
                            productId: productId,
                            collection: collection,
                            imageWidget: imageWidget,
                            calcPoints: calcPoints,
                            shareProduct: (productData, id, col) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Use Home interface to share directly with friends"),
                                ),
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0095F6),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "View",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}