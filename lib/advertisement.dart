import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AdvertisementBanner extends StatefulWidget {
  const AdvertisementBanner({super.key});

  @override
  State<AdvertisementBanner> createState() => _AdvertisementBannerState();
}

class _AdvertisementBannerState extends State<AdvertisementBanner> {

  int _currentAdIndex = 0;
  List<Map<String, dynamic>> _ads = [];
  late PageController _adPageController;

  @override
  void initState() {
    super.initState();
    _adPageController = PageController();
    _loadAds();
  }

  @override
  void dispose() {
    _adPageController.dispose();
    super.dispose();
  }

  Future<void> _loadAds() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("advertisements")
        .get();

    if (!mounted) return;

    setState(() {
      _ads = snapshot.docs
          .map((d) => d.data())
          .where((d) =>
      d['image'] != null &&
          d['image'].toString().isNotEmpty)
          .toList();
    });

    // AUTO SCROLL EVERY 10 SECONDS
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 10));
      if (!mounted) return false;
      if (_ads.isEmpty) return true;

      _currentAdIndex = (_currentAdIndex + 1) % _ads.length;

      if (_adPageController.hasClients) {
        _adPageController.animateToPage(
          _currentAdIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      return true;
    });
  }

  Widget _buildAdImage(String imageData) {
    try {
      if (imageData.startsWith("http")) {
        return Image.network(imageData, fit: BoxFit.cover);
      }
      final base64Str = imageData.contains(",")
          ? imageData.split(",").last
          : imageData;
      return Image.memory(base64Decode(base64Str), fit: BoxFit.cover);
    } catch (_) {
      return Container(color: const Color(0xFF1A1A1A));
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleaned = phone
        .trim()
        .replaceAll("+", "")
        .replaceAll(" ", "")
        .replaceAll("-", "");

    final uri = Uri.parse("https://wa.me/$cleaned");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ads.isEmpty) return const SizedBox();

    return Column(
      children: [

        // ── HEADER ───────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Featured",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F0F0F),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  "ADS",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── PAGE VIEW ────────────────────────
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _adPageController,
            itemCount: _ads.length,
            onPageChanged: (i) =>
                setState(() => _currentAdIndex = i),
            itemBuilder: (context, index) {
              final ad = _ads[index];

              return GestureDetector(
                onTap: () =>
                    _openWhatsApp(ad['client_phone'] ?? ""),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [

                        // IMAGE
                        _buildAdImage(ad['image'] ?? ""),

                        // GRADIENT OVERLAY
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Color(0xEE0F0F0F),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              crossAxisAlignment:
                              CrossAxisAlignment.end,
                              children: [

                                // LEFT: NAME + CLIENT
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ad['ad_name'] ?? "",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.store_rounded,
                                          color: Color(0xFF9CA3AF),
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          ad['client_name'] ?? "",
                                          style: const TextStyle(
                                            color: Color(0xFF9CA3AF),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                // RIGHT: PRICE + WHATSAPP
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [

                                    // PRICE
                                    Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                        const Color(0xFF16A34A),
                                        borderRadius:
                                        BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "\$${ad['price'] ?? 0}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    // WHATSAPP BUTTON
                                    Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                        const Color(0xFF25D366),
                                        borderRadius:
                                        BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.chat_rounded,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            "Contact",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight:
                                              FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ── DOTS INDICATOR ───────────────────
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_ads.length, (i) {
            final isActive = i == _currentAdIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}