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

  // Each category gets an icon so the chip row reads at a glance.
  final List<Map<String, dynamic>> _categories = [
    {"name": "All",         "icon": Icons.apps_rounded},
    {"name": "Electronics", "icon": Icons.devices_rounded},
    {"name": "Fashion",     "icon": Icons.checkroom_rounded},
    {"name": "Home",        "icon": Icons.home_rounded},
    {"name": "Super Star",  "icon": Icons.star_rounded},
    {"name": "VIP",         "icon": Icons.workspace_premium_rounded},
  ];

  // Brand palette
  static const Color kPrimary     = Color(0xFFD32F2F);
  static const Color kPrimaryDark = Color(0xFFB71C1C);
  static const Color kAccent      = Color(0xFFD97706);
  static const Color kInk         = Color(0xFF0F0F0F);
  static const Color kMuted       = Color(0xFF6B7280);
  static const Color kBorder      = Color(0xFFE5E7EB);
  static const Color kBg          = Color(0xFFF7F7F9);
  static const Color kBadgeBlue   = Color(0xFF1976D2);

  // ── SAFE IMAGE HANDLER ───────────────────────────────────────
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
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: const Color(0xFFF1F1F4),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: kPrimary,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) =>
              Icon(Icons.broken_image, size: iconSize, color: kMuted),
        );
      }

      return Icon(Icons.card_giftcard, size: iconSize, color: kMuted);
    } catch (_) {
      return Icon(Icons.card_giftcard, size: iconSize, color: kMuted);
    }
  }

  void showToast(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.info_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? const Color(0xFF16A34A) : kInk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  // ── COUNT WINNERS FOR A PRIZE ────────────────────────────────
  Future<int> _countWinners(String prizeName) async {
    final snap = await FirebaseFirestore.instance
        .collection("users_prizes")
        .where("prize_name", isEqualTo: prizeName)
        .get();
    return snap.docs.length;
  }

  // ── CATEGORY CHIP (the new "spinner") ────────────────────────
  Widget _categoryChip({
    required String name,
    required IconData icon,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
            colors: [kPrimary, kPrimaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? Colors.transparent : kBorder,
            width: 1,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: kPrimary.withOpacity(0.30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : kMuted,
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                color: selected ? Colors.white : kInk,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── PRIZE DETAIL BOTTOM SHEET ────────────────────────────────
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: kAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.stars_rounded,
                                  color: kAccent, size: 15),
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
                        final loading =
                            snap.connectionState == ConnectionState.waiting;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [kPrimary, kPrimaryDark],
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
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
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

  // ── QUANTITY + REDEEM FLOW ───────────────────────────────────
  // ── QUANTITY + REDEEM FLOW (Idealz-style) ────────────────────
  Future<void> _openQuantityDialog({
    required String name,
    required int points,
  }) async {
    int selectedQty = 1;
    const int maxQty = 10;
    const double itemWidth = 56.0;
    final scrollController = ScrollController();

    final result = await showDialog<int>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) {
          // Listen to scroll changes
          scrollController.removeListener(() {});
          void onScroll() {
            if (!scrollController.hasClients) return;
            final newQty =
                (scrollController.offset / itemWidth).round() + 1;
            final clamped = newQty.clamp(1, maxQty);
            if (clamped != selectedQty) {
              setLocalState(() => selectedQty = clamped);
            }
          }

          scrollController.addListener(onScroll);

          final totalPoints = points * selectedQty;

          return Dialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── HEADER ───────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.redeem_rounded,
                            color: kPrimary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: kInk,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Confirm your redemption",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: kMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFEFEF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ── COST PER ITEM ────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: kAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kAccent.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars_rounded,
                              color: kAccent, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            "Cost per item",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kInk,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "$points pts",
                            style: const TextStyle(
                              fontSize: 13,
                              color: kAccent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── QUANTITY LABEL ───────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "QUANTITY",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8E8E8E),
                            letterSpacing: 1.2,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.swipe_rounded,
                                size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              "swipe to change",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ── QTY SCROLLER (Idealz-style) ──────────
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double sidePadding =
                            (constraints.maxWidth - itemWidth) / 2;

                        return SizedBox(
                          height: 90,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Centered highlight pill
                              Center(
                                child: Container(
                                  width: itemWidth + 4,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: kPrimary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: kPrimary, width: 2),
                                  ),
                                ),
                              ),

                              // Scrollable numbers with snap
                              NotificationListener<ScrollNotification>(
                                onNotification: (n) {
                                  if (n is ScrollEndNotification &&
                                      scrollController.hasClients) {
                                    final int target =
                                    (scrollController.offset / itemWidth)
                                        .round()
                                        .clamp(0, maxQty - 1);
                                    final double snapOffset =
                                        target * itemWidth;
                                    if ((snapOffset -
                                        scrollController.offset)
                                        .abs() >
                                        0.5) {
                                      scrollController.animateTo(
                                        snapOffset,
                                        duration:
                                        const Duration(milliseconds: 220),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  }
                                  return false;
                                },
                                child: ListView.builder(
                                  controller: scrollController,
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: sidePadding),
                                  itemCount: maxQty,
                                  itemBuilder: (context, index) {
                                    final number = index + 1;
                                    final selected = selectedQty == number;

                                    return GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        scrollController.animateTo(
                                          index * itemWidth,
                                          duration: const Duration(
                                              milliseconds: 250),
                                          curve: Curves.easeOut,
                                        );
                                      },
                                      child: SizedBox(
                                        width: itemWidth,
                                        child: Center(
                                          child: AnimatedDefaultTextStyle(
                                            duration: const Duration(
                                                milliseconds: 180),
                                            style: TextStyle(
                                              fontSize: selected ? 28 : 18,
                                              fontWeight: selected
                                                  ? FontWeight.w800
                                                  : FontWeight.w500,
                                              color: selected
                                                  ? kPrimary
                                                  : Colors.grey.shade400,
                                            ),
                                            child: Text("$number"),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Left fade
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: IgnorePointer(
                                  child: Container(
                                    width: 32,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.white,
                                          Colors.white.withOpacity(0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Right fade
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                child: IgnorePointer(
                                  child: Container(
                                    width: 32,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.white.withOpacity(0),
                                          Colors.white,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // ── SUMMARY ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEFEFEF)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Points per item",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700)),
                              Text(
                                "$points pts",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kInk,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Quantity",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700)),
                              Text(
                                "× $selectedQty",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kInk,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding:
                            const EdgeInsets.symmetric(vertical: 8),
                            child: Container(
                                height: 1, color: const Color(0xFFEFEFEF)),
                          ),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Total cost",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: kInk,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.stars_rounded,
                                      color: kPrimary, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    "$totalPoints pts",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: kPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── ACTIONS ──────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: kInk,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(
                                      color: Color(0xFFDBDBDB)),
                                ),
                              ),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(context, selectedQty),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                "Redeem  •  $totalPoints pts",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    scrollController.dispose();

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

    showToast("Redeemed successfully", success: true);
    setState(() {});
  }

  // ── PRIZE GRID CARD ──────────────────────────────────────────
  Widget _buildPrizeCard({
    required dynamic images,
    required String name,
    required int points,
    required String category,
    required String description,
  }) {
    return GestureDetector(
      onTap: () => _openPrizeDetails(
        images: images,
        name: name,
        points: points,
        category: category,
        description: description,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IMAGE with overlay category chip
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.05,
                    child: Container(
                      color: const Color(0xFFF1F1F4),
                      child: buildPrizeImage(images, iconSize: 42),
                    ),
                  ),
                ),
                // Category badge floating on the image
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: kBadgeBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // CENTERED NAME + decorative divider + points
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
              child: Column(
                children: [
                  // Prize name — CENTERED, polished
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: kInk,
                      height: 1.25,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tiny decorative divider beneath the name
                  Container(
                    width: 28,
                    height: 2.5,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kPrimary, kAccent],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Points pill — centered
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: kAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded,
                            color: kAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "$points pts",
                          style: const TextStyle(
                            color: kAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // ── CATEGORY CHIP RAIL (the new "spinner") ─────────────
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final selected = _selectedCategory == cat['name'];
                return _categoryChip(
                  name: cat['name'],
                  icon: cat['icon'],
                  selected: selected,
                );
              },
            ),
          ),

          // ── PRIZES GRID ───────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("prizes")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: SizedBox(
                      width: 38,
                      height: 38,
                      child: CircularProgressIndicator(
                        color: kPrimary,
                        strokeWidth: 3,
                      ),
                    ),
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
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: kBorder),
                          ),
                          child: const Icon(
                            Icons.card_giftcard_outlined,
                            size: 38,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          "No prizes in $_selectedCategory",
                          style: const TextStyle(
                            color: kInk,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Check back soon for new rewards",
                          style: TextStyle(color: kMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.66,
                  ),
                  itemCount: prizes.length,
                  itemBuilder: (context, index) {
                    final data =
                    prizes[index].data() as Map<String, dynamic>;
                    final images      = data['images'];
                    final name        = data['prize_name'] ?? "Prize";
                    final points      = data['number_of_points_required'] ?? 0;
                    final category    = data['prize_category'] ?? "General";
                    final description = data['description']?.toString() ?? "";

                    return _buildPrizeCard(
                      images: images,
                      name: name,
                      points: points,
                      category: category,
                      description: description,
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

