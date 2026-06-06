import 'package:flutter/material.dart';

class PurchaseDialog {
  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> data,
    required Future<void> Function(
        int qty,
        String payementmethod,
        ) onConfirm,
  }) async {
    final int currentStock = (data['current_quantity'] ?? 0) as int;

    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _PurchaseDialogContent(
        data: data,
        currentStock: currentStock,
        onConfirm: onConfirm,
      ),
    );
  }
}

class _PurchaseDialogContent extends StatefulWidget {
  final Map<String, dynamic> data;
  final int currentStock;
  final Future<void> Function(int qty, String paymentMethod) onConfirm;

  const _PurchaseDialogContent({
    required this.data,
    required this.currentStock,
    required this.onConfirm,
  });

  @override
  State<_PurchaseDialogContent> createState() => _PurchaseDialogContentState();
}

class _PurchaseDialogContentState extends State<_PurchaseDialogContent> {
  int qty = 1;
  String selectedPayment = "Cash on Delivery";

  late final ScrollController _scrollController;
  late final int _maxQty;

  // Each quantity tile width — keep this consistent everywhere
  static const double _itemWidth = 56.0;

  @override
  void initState() {
    super.initState();
    _maxQty = widget.currentStock > 99 ? 99 : widget.currentStock;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final newQty = (_scrollController.offset / _itemWidth).round() + 1;
    final clamped = newQty.clamp(1, _maxQty <= 0 ? 1 : _maxQty);
    if (clamped != qty) {
      setState(() => qty = clamped);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productName = widget.data['product_name'] ?? "";
    final price = widget.data['priceonplatform'] ?? 0;
    final priceNum = price is num ? price.toDouble() : 0.0;
    final totalPrice = priceNum * qty;

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
              // ── HEADER ─────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0095F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: Color(0xFF0095F6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Confirm your order",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
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

              // ── STOCK STATUS ───────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEFEFEF)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.currentStock > 0
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFED4956),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.currentStock > 0 ? "In stock" : "Out of stock",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${widget.currentStock} available",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── QUANTITY LABEL ─────────────────────────
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
                      Icon(
                        Icons.swipe_rounded,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
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

              // ── IDEALZ-STYLE QUANTITY SCROLLER ─────────
              if (_maxQty > 0)
                _buildQtyScroller()
              else
                _buildEmptyQtyState(),

              const SizedBox(height: 20),

              // ── PAYMENT METHOD LABEL ───────────────────
              const Text(
                "PAYMENT METHOD",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8E8E8E),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              _buildPaymentSelector(),

              const SizedBox(height: 18),

              // ── PRICE SUMMARY ──────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEFEFEF)),
                ),
                child: Column(
                  children: [
                    _summaryRow("Unit price", "\$$price"),
                    const SizedBox(height: 6),
                    _summaryRow("Quantity", "× $qty"),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        height: 1,
                        color: const Color(0xFFEFEFEF),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "\$${totalPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0095F6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── ACTIONS ────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0xFFDBDBDB)),
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
                        onPressed: widget.currentStock <= 0
                            ? null
                            : () async {
                          Navigator.pop(context);
                          await widget.onConfirm(qty, selectedPayment);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0095F6),
                          disabledBackgroundColor:
                          const Color(0xFF0095F6).withOpacity(0.4),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          widget.currentStock <= 0
                              ? "Out of stock"
                              : "Confirm purchase",
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
  }

  // ─── QTY SCROLLER (Idealz-style) ─────────────────────
  Widget _buildQtyScroller() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Side padding so that index 0 starts at the center indicator
        final double sidePadding =
            (constraints.maxWidth - _itemWidth) / 2;

        return SizedBox(
          height: 90,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Centered highlight pill
              Center(
                child: Container(
                  width: _itemWidth + 4,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0095F6).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF0095F6),
                      width: 2,
                    ),
                  ),
                ),
              ),

              // Scrollable numbers with snap behavior
              NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollEndNotification &&
                      _scrollController.hasClients) {
                    final int target =
                    (_scrollController.offset / _itemWidth)
                        .round()
                        .clamp(0, _maxQty - 1);
                    final double snapOffset = target * _itemWidth;
                    if ((snapOffset - _scrollController.offset).abs() > 0.5) {
                      _scrollController.animateTo(
                        snapOffset,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      );
                    }
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: sidePadding),
                  itemCount: _maxQty,
                  itemBuilder: (context, index) {
                    final number = index + 1;
                    final selected = qty == number;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _scrollController.animateTo(
                          index * _itemWidth,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      },
                      child: SizedBox(
                        width: _itemWidth,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 180),
                            style: TextStyle(
                              fontSize: selected ? 28 : 18,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: selected
                                  ? const Color(0xFF0095F6)
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
    );
  }

  Widget _buildEmptyQtyState() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Center(
        child: Text(
          "No stock available",
          style: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ─── PAYMENT SELECTOR ────────────────────────────────
  Widget _buildPaymentSelector() {
    final methods = <Map<String, dynamic>>[
      {"name": "Cash on Delivery", "icon": Icons.payments_rounded},
      {"name": "Wish Money", "icon": Icons.account_balance_wallet_rounded},
      {"name": "BOB Card", "icon": Icons.credit_card_rounded},
      {"name": "OMT", "icon": Icons.send_to_mobile_rounded},
    ];

    return Column(
      children: methods.map((m) {
        final name = m["name"] as String;
        final icon = m["icon"] as IconData;
        final selected = selectedPayment == name;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => selectedPayment = name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF0095F6).withOpacity(0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? const Color(0xFF0095F6)
                    : const Color(0xFFDBDBDB),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF0095F6).withOpacity(0.12)
                        : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: selected
                        ? const Color(0xFF0095F6)
                        : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                      color:
                      selected ? Colors.black : Colors.grey.shade800,
                    ),
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF0095F6)
                          : const Color(0xFFDBDBDB),
                      width: 2,
                    ),
                    color: selected
                        ? const Color(0xFF0095F6)
                        : Colors.white,
                  ),
                  child: selected
                      ? const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: Colors.white,
                  )
                      : null,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}