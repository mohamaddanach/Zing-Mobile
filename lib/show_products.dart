import 'package:flutter/material.dart';
import 'package:zing/purchase_dialog.dart';
import 'transaction_service.dart';
import 'seller_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Public, backward-compatible entry point.
/// home.dart still calls `ShowProducts.showProductDetails(...)` — we just
/// route to a full page instead of a modal bottom sheet now.
class ShowProducts {
  static void showProductDetails({
    required BuildContext context,
    required Map<String, dynamic> data,
    required String productId,
    required String collection,

    // injected from home.dart
    required Widget Function(Map<String, dynamic>) imageWidget,
    required double Function(Map<String, dynamic>) calcPoints,
    required void Function(
        Map<String, dynamic> data,
        String productId,
        String collection,
        ) shareProduct,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsPage(
          data: data,
          productId: productId,
          collection: collection,
          imageWidget: imageWidget,
          calcPoints: calcPoints,
          shareProduct: shareProduct,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PRODUCT DETAILS PAGE  (Instagram-style — matches home.dart)
// ─────────────────────────────────────────────────────────────
class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String productId;
  final String collection;
  final Widget Function(Map<String, dynamic>) imageWidget;
  final double Function(Map<String, dynamic>) calcPoints;
  final void Function(Map<String, dynamic>, String, String) shareProduct;

  const ProductDetailsPage({
    super.key,
    required this.data,
    required this.productId,
    required this.collection,
    required this.imageWidget,
    required this.calcPoints,
    required this.shareProduct,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  // ── Theme tokens (mirror home.dart) ──
  static const _bg = Colors.white;
  static const _text = Colors.black;
  static const _muted = Color(0xFF8E8E8E);
  static const _border = Color(0xFFEFEFEF);
  static const _surface = Color(0xFFFAFAFA);
  static const _blue = Color(0xFF0095F6); // Instagram blue

  final ScrollController _scroll = ScrollController();
  bool _titleVisible = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final v = _scroll.offset > 300;
      if (v != _titleVisible) setState(() => _titleVisible = v);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // ── Helpers ──
  String get _priceText {
    final p = widget.data['priceonplatform'] ?? widget.data['price'];
    return (p ?? 0).toString();
  }

  String get _category =>
      widget.collection.replaceFirst("products_", "");

  String get _stockText {
    final s = widget.data['current_quantity'] ?? widget.data['stock'] ?? 0;
    return s.toString();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final pts = widget.calcPoints(data).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── SCROLLING CONTENT ─────────────────────────
          CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _heroAppBar(data),
              SliverToBoxAdapter(child: _body(data, pts)),
            ],
          ),

          // ── STICKY BOTTOM ACTION BAR ──────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _bottomBar(data),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  HERO IMAGE + SLIVER APP BAR
  // ─────────────────────────────────────────────────────
  Widget _heroAppBar(Map<String, dynamic> data) {
    return SliverAppBar(
      expandedHeight: 420,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: _bg,
      surfaceTintColor: _bg,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Center(
          child: _circleBtn(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Center(
            child: _circleBtn(
              icon: Icons.ios_share_rounded,
              onTap: () => widget.shareProduct(
                  data, widget.productId, widget.collection),
            ),
          ),
        ),
      ],

      // Collapsed-state title fades in as user scrolls
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _titleVisible ? 1 : 0,
        child: Text(
          data['product_name'] ?? "",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _text,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: -0.2,
          ),
        ),
      ),
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: _titleVisible ? 1 : 0,
          child: Container(height: 0.5, color: _border),
        ),
      ),

      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // The actual product image (cover-fitted by home.dart's builder)
            ColoredBox(
              color: _surface,
              child: widget.imageWidget(data),
            ),

            // Top gradient — keeps the floating buttons readable
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 130,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  BODY CONTENT
  // ─────────────────────────────────────────────────────
  Widget _body(Map<String, dynamic> data, String pts) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category eyebrow ──
          Text(
            _category.toUpperCase(),
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),

          // ── Product name ──
          Text(
            data['product_name'] ?? "Unnamed product",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _text,
              height: 1.25,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),

          // ── Price + points pill ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "\$$_priceText",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _text,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  "$pts pts",
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Seller card ──
          _sellerCard(data),

          const SizedBox(height: 12),

          // ── Quick stats ──
          Row(
            children: [
              Expanded(
                child: _statBox(
                  icon: Icons.inventory_2_outlined,
                  label: "In stock",
                  value: _stockText,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBox(
                  icon: Icons.category_outlined,
                  label: "Category",
                  value: _category,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Description ──
          const Text(
            "Description",
            style: TextStyle(
              color: _text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            (data['description'] != null &&
                data['description'].toString().trim().isNotEmpty)
                ? data['description']
                : "No description available for this product.",
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 14,
              height: 1.6,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  SUBVIEWS
  // ─────────────────────────────────────────────────────

  Widget _circleBtn({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withOpacity(0.95),
      shape: const CircleBorder(side: BorderSide(color: _border, width: 0.6)),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: _text, size: 18),
        ),
      ),
    );
  }

  Widget _sellerCard(Map<String, dynamic> data) {
    final name = (data['seller_name'] ?? "Unknown seller").toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : "?";

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SellerProfile(sellerName: data['seller_name'] ?? ""),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              // ── Plain circular avatar (fetches profile_image from Firestore) ──
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection("sellers")
                    .where("name", isEqualTo: name)
                    .limit(1)
                    .get(),
                builder: (context, snapshot) {
                  String? profileImage;
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final seller = snapshot.data!.docs.first.data()
                    as Map<String, dynamic>;
                    final raw = seller['profile_image'];
                    if (raw != null && raw.toString().isNotEmpty) {
                      profileImage = raw.toString();
                    }
                  }

                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _border, width: 1),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: _surface,
                      backgroundImage: profileImage != null
                          ? NetworkImage(profileImage)
                          : null,
                      child: profileImage == null
                          ? Text(
                        initial,
                        style: const TextStyle(
                          color: _text,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      )
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Sold by",
                      style: TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _muted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Icon(icon, color: _text, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(Map<String, dynamic> data) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, -2),
            blurRadius: 14,
          ),
        ],
      ),
      child: Row(
        children: [
          // Share — outlined square button
          SizedBox(
            height: 48,
            width: 48,
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFDBDBDB)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => widget.shareProduct(
                  data,
                  widget.productId,
                  widget.collection,
                ),
                child: const Icon(
                  Icons.send_outlined,
                  color: _text,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Buy — primary CTA (Instagram blue)
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  PurchaseDialog.show(
                    context: context,
                    data: data,
                    onConfirm: (qty, paymentMethod) async {
                      await TransactionService.processPurchase(
                        productData: {
                          ...data,
                          "category": widget.collection
                              .replaceFirst("products_", ""),
                        },
                        quantity: qty,
                        source: "home",
                        paymentMethod: paymentMethod,
                        productId: widget.productId,
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Buy now",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}