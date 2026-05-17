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
  String _selectedCategory = "All";

  final List<String> _categories = [
    "All",
    "Electronics",
    "Fashion",
    "Home",
    "Super Star",
    "VIP",
  ];
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

      body: Column(
        children: [

          // ── CATEGORY SPINNER ─────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFFD32F2F),
                ),
                style: const TextStyle(
                  color: Color(0xFF0F0F0F),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                  }
                },
                items: _categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cat == "All"
                                ? const Color(0xFF6B7280)
                                : const Color(0xFFD32F2F),
                          ),
                        ),
                        Text(cat),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── PRIZES LIST ──────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("prizes")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFD32F2F),
                    ),
                  );
                }

                // FILTER BY CATEGORY
                final allPrizes = snapshot.data!.docs;
                final prizes = _selectedCategory == "All"
                    ? allPrizes
                    : allPrizes.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['prize_category'] == _selectedCategory;
                }).toList();

                if (prizes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.card_giftcard_outlined,
                          size: 48,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No prizes in $_selectedCategory",
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                  itemCount: prizes.length,
                  itemBuilder: (context, index) {

                    final data = prizes[index].data()
                    as Map<String, dynamic>;

                    final images   = data['images'];
                    final name     = data['prize_name'] ?? "Prize";
                    final points   = data['number_of_points_required'] ?? 0;
                    final category = data['prize_category'] ?? "General";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [

                            // IMAGE
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 75,
                                height: 75,
                                child: buildPrizeImage(images),
                              ),
                            ),

                            const SizedBox(width: 14),

                            // INFO
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [

                                  // NAME
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F0F0F),
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  // CATEGORY BADGE
                                  Container(
                                    padding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1976D2)
                                          .withOpacity(0.1),
                                      borderRadius:
                                      BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      category,
                                      style: const TextStyle(
                                        color: Color(0xFF1976D2),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  // POINTS
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.stars_rounded,
                                        color: Color(0xFFD97706),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "$points pts per unit",
                                        style: const TextStyle(
                                          color: Color(0xFFD97706),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // GET BUTTON
                            GestureDetector(
                              onTap: () async {

                                int selectedQty = 1;

                                final result = await showDialog<int>(
                                  context: context,
                                  builder: (context) => StatefulBuilder(
                                    builder: (context, setState) =>
                                        AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(18),
                                          ),
                                          title: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Select Quantity",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 17,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "$points pts × qty",
                                                style: const TextStyle(
                                                  color: Color(0xFFD97706),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          content: Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: List.generate(10,
                                                    (i) {
                                                  final num = i + 1;
                                                  final isSelected =
                                                      selectedQty == num;
                                                  return GestureDetector(
                                                    onTap: () => setState(
                                                            () => selectedQty = num),
                                                    child: AnimatedContainer(
                                                      duration: const Duration(
                                                          milliseconds: 200),
                                                      width: 44,
                                                      height: 44,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: isSelected
                                                            ? const Color(
                                                            0xFFD32F2F)
                                                            : Colors.white,
                                                        border: Border.all(
                                                          color: isSelected
                                                              ? const Color(
                                                              0xFFD32F2F)
                                                              : const Color(
                                                              0xFFE5E7EB),
                                                          width: 1.5,
                                                        ),
                                                        boxShadow: isSelected
                                                            ? [
                                                          BoxShadow(
                                                            color: const Color(
                                                                0xFFD32F2F)
                                                                .withOpacity(
                                                                0.3),
                                                            blurRadius: 8,
                                                          )
                                                        ]
                                                            : [],
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "$num",
                                                          style: TextStyle(
                                                            color: isSelected
                                                                ? Colors.white
                                                                : const Color(
                                                                0xFF0F0F0F),
                                                            fontWeight:
                                                            FontWeight.w700,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text(
                                                "Cancel",
                                                style: TextStyle(
                                                    color:
                                                    Color(0xFF6B7280)),
                                              ),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                const Color(0xFFD32F2F),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      10),
                                                ),
                                              ),
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      context, selectedQty),
                                              child: Text(
                                                "Confirm  •  ${points * selectedQty} pts",
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                  ),
                                );

                                if (result == null) return;

                                final qty = result;

                                final userQuery =
                                await FirebaseFirestore.instance
                                    .collection("users")
                                    .where("phone_number",
                                    isEqualTo:
                                    widget.userphonenumber)
                                    .limit(1)
                                    .get();

                                if (userQuery.docs.isEmpty) {
                                  showToast("User not found");
                                  return;
                                }

                                final userDoc  = userQuery.docs.first;
                                final userRef  = userDoc.reference;
                                final userPts  =
                                    userDoc.data()['number_of_points'] ??
                                        0;
                                final totalCost = points * qty;

                                if (userPts < totalCost) {
                                  showToast("Not enough points");
                                  return;
                                }

                                await userRef.update({
                                  "number_of_points": userPts - totalCost
                                });

                                await FirebaseFirestore.instance
                                    .collection("users_prizes")
                                    .add({
                                  "winner_name": widget.username,
                                  "winner_phone_number":
                                  widget.userphonenumber,
                                  "winner_country": widget.country,
                                  "prize_name": name,
                                  "quantity": qty,
                                  "total_points_used": totalCost,
                                  "check_admin": false,
                                  "Date": FieldValue.serverTimestamp(),
                                });

                                showToast("Operation is done ✅");
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD32F2F),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD32F2F)
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  "Get",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}