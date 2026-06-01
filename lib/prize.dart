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

  // Brand palette
  static const Color kPrimary    = Color(0xFFD32F2F);
  static const Color kAccent     = Color(0xFFD97706);
  static const Color kInk        = Color(0xFF0F0F0F);
  static const Color kMuted      = Color(0xFF6B7280);
  static const Color kBorder     = Color(0xFFE5E7EB);
  static const Color kBg         = Color(0xFFF7F7F9);
  static const Color kBadgeBlue  = Color(0xFF1976D2);

  // 🖼 SAFE IMAGE HANDLER
  Widget buildPrizeImage(dynamic images, {double iconSize = 50}) {
    try {
      String value = "";
      if (images is List && images.isNotEmpty) {
        value = images[0].toString();
      } else if (images is String) {
        value = images;
      }

      if (value.isEmpty) {
        return Container(
          color: const Color(0xFFF1F1F4),
          child: Icon(Icons.card_giftcard, size: iconSize, color: kMuted),
        );
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
          errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: iconSize, color: kMuted),
        );
      }

      return Icon(Icons.card_giftcard, size: iconSize, color: kMuted);
    } catch (_) {
      return Icon(Icons.card_giftcard, size: iconSize, color: kMuted);
    }
  }

  void showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: kInk,
      ),
    );
  }

  // ── COUNT WINNERS FOR A PRIZE ─────────────────────────
  Future<int> _countWinners(String prizeName) async {
    final snap = await FirebaseFirestore.instance
        .collection("users_prizes")
        .where("prize_name", isEqualTo: prizeName)
        .get();
    return snap.docs.length;
  }

  // ── PRIZE DETAIL BOTTOM SHEET ─────────────────────────
  void _openPrizeDetails({
    required dynamic images,
    required String name,
    required int points,
    required String category,
    required String description,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollCtrl) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // drag handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: kBorder,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),

                    // hero image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Container(
                          color: const Color(0xFFF1F1F4),
                          child: buildPrizeImage(images, iconSize: 70),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // title
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: kInk,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // category + points pills
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: kBadgeBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: kBadgeBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: kAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.stars_rounded, color: kAccent, size: 15),
                              const SizedBox(width: 4),
                              Text(
                                "$points pts",
                                style: const TextStyle(
                                  color: kAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Winners count (live)
                    FutureBuilder<int>(
                      future: _countWinners(name),
                      builder: (context, snap) {
                        final count = snap.data ?? 0;
                        final loading = snap.connectionState == ConnectionState.waiting;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimary.withOpacity(0.25),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Total Winners",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    loading
                                        ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                        : Text(
                                      "$count ${count == 1 ? 'user' : 'users'} won this",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 22),

                    // Description
                    const Text(
                      "About this prize",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: kInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description.isNotEmpty
                          ? description
                          : "Redeem this prize using your earned points. Once confirmed, our team will contact you to deliver your reward.",
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: kMuted,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Redeem button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.redeem_rounded),
                        label: const Text(
                          "Redeem Now",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _openQuantityDialog(name: name, points: points);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── QUANTITY + REDEEM FLOW ────────────────────────────
  Future<void> _openQuantityDialog({
    required String name,
    required int points,
  }) async {
    int selectedQty = 1;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select Quantity",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 4),
              Text(
                "$points pts × qty",
                style: const TextStyle(
                  color: kAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(10, (i) {
              final num = i + 1;
              final isSelected = selectedQty == num;
              return GestureDetector(
                onTap: () => setState(() => selectedQty = num),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? kPrimary : Colors.white,
                    border: Border.all(
                      color: isSelected ? kPrimary : kBorder,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.3),
                        blurRadius: 8,
                      )
                    ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      "$num",
                      style: TextStyle(
                        color: isSelected ? Colors.white : kInk,
                        fontWeight: FontWeight.w700,
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
              child: const Text("Cancel", style: TextStyle(color: kMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context, selectedQty),
              child: Text(
                "Confirm  •  ${points * selectedQty} pts",
                style: const TextStyle(color: Colors.white),
              ),
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
      showToast("User not found");
      return;
    }

    final userDoc = userQuery.docs.first;
    final userRef = userDoc.reference;
    final userPts = userDoc.data()['number_of_points'] ?? 0;
    final totalCost = points * qty;

    if (userPts < totalCost) {
      showToast("Not enough points");
      return;
    }

    await userRef.update({"number_of_points": userPts - totalCost});

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

    showToast("Operation is done ✅");
    setState(() {}); // refresh winners count next time
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text(
          "Prizes",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: kInk,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // ── CATEGORY SPINNER ─────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kPrimary),
                style: const TextStyle(
                  color: kInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
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
                            color: cat == "All" ? kMuted : kPrimary,
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
                    child: CircularProgressIndicator(color: kPrimary),
                  );
                }

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
                        const Icon(Icons.card_giftcard_outlined, size: 48, color: Color(0xFF9CA3AF)),
                        const SizedBox(height: 12),
                        Text(
                          "No prizes in $_selectedCategory",
                          style: const TextStyle(color: kMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                  itemCount: prizes.length,
                  itemBuilder: (context, index) {
                    final data = prizes[index].data() as Map<String, dynamic>;
                    final images      = data['images'];
                    final name        = data['prize_name'] ?? "Prize";
                    final points      = data['number_of_points_required'] ?? 0;
                    final category    = data['prize_category'] ?? "General";
                    final description = data['description']?.toString() ?? "";

                    return GestureDetector(
                      onTap: () => _openPrizeDetails(
                        images: images,
                        name: name,
                        points: points,
                        category: category,
                        description: description,
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kBorder),
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
                                child: Container(
                                  width: 78,
                                  height: 78,
                                  color: const Color(0xFFF1F1F4),
                                  child: buildPrizeImage(images),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // INFO
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: kInk,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: kBadgeBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        category,
                                        style: const TextStyle(
                                          color: kBadgeBlue,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.stars_rounded, color: kAccent, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          "$points pts per unit",
                                          style: const TextStyle(
                                            color: kAccent,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // CHEVRON (indicates tappable)
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: kMuted,
                              ),
                            ],
                          ),
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