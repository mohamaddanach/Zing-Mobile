import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zing/purchase_dialog.dart';
import 'transaction_service.dart';
import 'show_products.dart';

class Net extends StatefulWidget {
  final String username;
  final String userphonenumber;
  final String country;

  const Net({
    super.key,
    required this.username,
    required this.userphonenumber,
    required this.country,
  });

  @override
  State<Net> createState() => _NetState();
}

class _NetState extends State<Net> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // 🔥 CACHED FRIENDS LIST (phone numbers)
  List<String> _friendsPhones = [];
  // 🔥 CACHED FRIENDS UIDS (resolved from users collection)
  List<String> _friendsUids = [];
  // 🔥 CACHED FRIEND INFO BY UID
  final Map<String, Map<String, dynamic>> _friendInfoByUid = {};
  // 🔥 CACHED FRIEND INFO BY PHONE
  final Map<String, Map<String, dynamic>> _friendInfoByPhone = {};

  bool _friendsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  // 🔥 LOAD FRIENDS + RESOLVE THEIR IDS
  //   NOTE: The `users` collection may be keyed by phone OR uid.
  //   We grab BOTH (the `uid` field if present, and the doc id),
  //   so reposts (which match by repostedByUid) work no matter
  //   how the user docs are structured.
  // ──────────────────────────────────────────────────────────
  Future<void> _loadFriends() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userphonenumber)
          .collection('friends_list')
          .get();

      final phones = snap.docs
          .map((d) => (d.data()['phone_number'] ?? '').toString())
          .where((p) => p.isNotEmpty)
          .toList();

      _friendsPhones = phones;
      _friendsUids = [];
      _friendInfoByUid.clear();
      _friendInfoByPhone.clear();

      // Resolve phones -> uids in batches of 10 (firestore whereIn limit)
      for (int i = 0; i < phones.length; i += 10) {
        final batch = phones.skip(i).take(10).toList();
        if (batch.isEmpty) continue;

        final usersSnap = await FirebaseFirestore.instance
            .collection('users')
            .where('phone_number', whereIn: batch)
            .get();

        for (final d in usersSnap.docs) {
          final data = d.data();
          final phone = (data['phone_number'] ?? '').toString();

          // 🔥 IMPORTANT: collect BOTH the `uid` field AND the doc id.
          // home.dart writes repostedByUid using FirebaseAuth.currentUser.uid,
          // which may NOT be the same as the firestore doc id (which is
          // often the phone number). We try both to catch every case.
          final authUid = (data['uid'] ?? '').toString();
          final docId = d.id;

          final ids = <String>{};
          if (authUid.isNotEmpty) ids.add(authUid);
          if (docId.isNotEmpty) ids.add(docId);

          for (final id in ids) {
            _friendsUids.add(id);
            _friendInfoByUid[id] = data;
          }

          if (phone.isNotEmpty) {
            _friendInfoByPhone[phone] = {
              ...data,
              '_uid': authUid.isNotEmpty ? authUid : docId,
              '_docId': docId,
            };
          }
        }
      }

      debugPrint(
          "Net: loaded ${_friendsPhones.length} friends, resolved ${_friendsUids.length} ids");

      if (mounted) {
        setState(() => _friendsLoaded = true);
      }
    } catch (e) {
      debugPrint("loadFriends error: $e");
      if (mounted) setState(() => _friendsLoaded = true);
    }
  }

  // ──────────────────────────────────────────────────────────
  // 🔥 IMAGE WIDGET (supports url + base64 + lists)
  // ──────────────────────────────────────────────────────────
  Widget _imageWidget(dynamic raw, {double? height, double? width}) {
    try {
      String value;

      if (raw is List && raw.isNotEmpty) {
        value = raw[0].toString();
      } else if (raw is String) {
        value = raw;
      } else {
        return _placeholderImage(height: height, width: width);
      }

      if (value.isEmpty) return _placeholderImage(height: height, width: width);

      if (value.startsWith("http")) {
        return Image.network(
          value,
          height: height,
          width: width,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _placeholderImage(height: height, width: width),
        );
      }

      if (value.contains(",")) value = value.split(",").last;

      return Image.memory(
        base64Decode(value),
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _placeholderImage(height: height, width: width),
      );
    } catch (_) {
      return _placeholderImage(height: height, width: width);
    }
  }

  /// Extract best available image from a product map (covers many field names)
  dynamic _extractImage(Map<String, dynamic> data) {
    return data['images'] ??
        data['image_url'] ??
        data['image'] ??
        data['photo'] ??
        data['product_image'] ??
        data['productImage'] ??
        data['photoUrl'] ??
        '';
  }

  Widget _placeholderImage({double? height, double? width}) {
    return Container(
      height: height,
      width: width,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 40),
    );
  }

  double _calcPoints(Map<String, dynamic> data) {
    final raw = data['bonus_reserve'];
    if (raw == null) return 0;
    if (raw is int) return raw.toDouble();
    if (raw is double) return raw;
    if (raw is String) return double.tryParse(raw) ?? 0;
    return 0;
  }

  // ──────────────────────────────────────────────────────────
  // 🔥 ADD FRIEND
  // ──────────────────────────────────────────────────────────
  Future<void> _addFriend(String name, String phone, String image) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userphonenumber)
          .collection('friends_list')
          .doc(phone)
          .set({
        'username': name,
        'phone_number': phone,
        'profile_url': image,
        'added_on': FieldValue.serverTimestamp(),
      });

      setState(() => _friendsPhones.add(phone));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Added $name to your network"),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // refresh full friends info so their activity appears in the feed
      await _loadFriends();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("addFriend error: $e");
    }
  }

  // ──────────────────────────────────────────────────────────
  // 🔥 BUILD THE FEED — merges reposts + liked products from friends
  // ──────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _buildFeed() async {
    if (_friendsUids.isEmpty && _friendsPhones.isEmpty) return [];

    final List<Map<String, dynamic>> feed = [];
    final Set<String> seenRepostIds = {};

    // ── 1A) FETCH REPOSTS BY UID ────────────────────────
    try {
      for (int i = 0; i < _friendsUids.length; i += 10) {
        final batch = _friendsUids.skip(i).take(10).toList();
        if (batch.isEmpty) continue;

        try {
          // Try with ordering first (requires composite index)
          final repostsSnap = await FirebaseFirestore.instance
              .collection('reposts')
              .where('repostedByUid', whereIn: batch)
              .orderBy('repostedAt', descending: true)
              .limit(30)
              .get();

          for (final doc in repostsSnap.docs) {
            if (seenRepostIds.contains(doc.id)) continue;
            seenRepostIds.add(doc.id);

            final d = doc.data();
            feed.add({
              'type': 'repost',
              'doc_id': doc.id,
              'data': d,
              'sort_ts': d['repostedAt'] as Timestamp?,
            });
          }
        } catch (e) {
          // If composite index missing, retry without orderBy
          debugPrint(
              "reposts ordered query failed, retrying without order: $e");
          try {
            final repostsSnap = await FirebaseFirestore.instance
                .collection('reposts')
                .where('repostedByUid', whereIn: batch)
                .limit(30)
                .get();

            for (final doc in repostsSnap.docs) {
              if (seenRepostIds.contains(doc.id)) continue;
              seenRepostIds.add(doc.id);

              final d = doc.data();
              feed.add({
                'type': 'repost',
                'doc_id': doc.id,
                'data': d,
                'sort_ts': d['repostedAt'] as Timestamp?,
              });
            }
          } catch (e2) {
            debugPrint("reposts fallback also failed: $e2");
          }
        }
      }
    } catch (e) {
      debugPrint("reposts by uid outer error: $e");
    }

    // ── 1B) FETCH REPOSTS BY PHONE (fallback) ───────────
    // Some reposts may store repostedByPhone even when the uid match fails.
    try {
      for (int i = 0; i < _friendsPhones.length; i += 10) {
        final batch = _friendsPhones.skip(i).take(10).toList();
        if (batch.isEmpty) continue;

        try {
          final repostsSnap = await FirebaseFirestore.instance
              .collection('reposts')
              .where('repostedByPhone', whereIn: batch)
              .limit(30)
              .get();

          for (final doc in repostsSnap.docs) {
            if (seenRepostIds.contains(doc.id)) continue;
            seenRepostIds.add(doc.id);

            final d = doc.data();
            feed.add({
              'type': 'repost',
              'doc_id': doc.id,
              'data': d,
              'sort_ts': d['repostedAt'] as Timestamp?,
            });
          }
        } catch (e) {
          debugPrint("reposts by phone batch error: $e");
        }
      }
    } catch (e) {
      debugPrint("reposts by phone outer error: $e");
    }

    debugPrint("Net: fetched ${feed.length} reposts");

    // ── 2) FETCH LIKED PRODUCTS FROM FRIENDS ─────────────
    try {
      for (final friendUid in _friendsUids) {
        try {
          final likedSnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(friendUid)
              .collection('liked_products')
              .orderBy('timestamp', descending: true)
              .limit(5)
              .get();

          for (final liked in likedSnap.docs) {
            final likedData = liked.data();
            final productId = (likedData['product_id'] ?? '').toString();
            final collection = (likedData['collection'] ?? '').toString();

            if (productId.isEmpty || collection.isEmpty) continue;

            // fetch actual product
            final productDoc = await FirebaseFirestore.instance
                .collection(collection)
                .doc(productId)
                .get();

            if (!productDoc.exists) continue;

            final friendData = _friendInfoByUid[friendUid] ?? {};

            feed.add({
              'type': 'liked',
              'doc_id': liked.id,
              'productId': productId,
              'collection': collection,
              'data': productDoc.data() ?? {},
              'friend': {
                'username': friendData['username'] ?? 'Friend',
                'profile_url': friendData['profile_url'] ?? '',
                'phone_number': friendData['phone_number'] ?? '',
                'uid': friendUid,
              },
              'sort_ts': likedData['timestamp'] as Timestamp?,
            });
          }
        } catch (e) {
          debugPrint("liked for $friendUid error: $e");
        }
      }
    } catch (e) {
      debugPrint("liked outer error: $e");
    }

    // ── 3) SORT BY TIMESTAMP (newest first) ─────────────
    feed.sort((a, b) {
      final ta = a['sort_ts'] as Timestamp?;
      final tb = b['sort_ts'] as Timestamp?;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });

    debugPrint("Net: final feed size = ${feed.length}");
    return feed;
  }

  // ──────────────────────────────────────────────────────────
  // 🔥 FETCH SUGGESTED USERS (not in network, same country)
  // ──────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchSuggestedUsers() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('country', isEqualTo: widget.country)
          .limit(50)
          .get();

      final users = snap.docs.where((doc) {
        final data = doc.data();
        final phone = data['phone_number']?.toString() ?? '';
        return phone != widget.userphonenumber &&
            phone.isNotEmpty &&
            !_friendsPhones.contains(phone);
      }).map((d) => d.data()).toList();

      users.shuffle(Random());
      return users.take(20).toList();
    } catch (e) {
      debugPrint("suggested users error: $e");
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────
  // 🎨 BUILD METHOD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          "Network",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: !_friendsLoaded
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<dynamic>>(
        future: Future.wait([
          _buildFeed(),
          _fetchSuggestedUsers(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final feed =
          (snapshot.data![0] as List<Map<String, dynamic>>);
          final suggested =
          (snapshot.data![1] as List<Map<String, dynamic>>);

          if (feed.isEmpty &&
              suggested.isEmpty &&
              _friendsPhones.isEmpty) {
            return RefreshIndicator(
              color: Colors.blue,
              onRefresh: () async {
                await _loadFriends();
                setState(() {});
              },
              child: ListView(
                children: [
                  _searchBar(),
                  const SizedBox(height: 40),
                  _emptyState(),
                ],
              ),
            );
          }

          // 🔥 INTERLEAVE SUGGESTED USERS LIKE INSTAGRAM
          final List<Widget> items = [];
          items.add(_searchBar());

          if (feed.isEmpty) {
            items.add(_noFeedYet());
            if (suggested.isNotEmpty) {
              items.add(_suggestedUsersCarousel(suggested));
            }
          } else {
            int suggestedIndex = 0;

            for (int i = 0; i < feed.length; i++) {
              items.add(_feedItem(feed[i]));

              // every 3 posts, inject suggested users carousel
              if ((i + 1) % 3 == 0 &&
                  suggestedIndex < suggested.length) {
                final chunk =
                suggested.skip(suggestedIndex).take(6).toList();
                if (chunk.isNotEmpty) {
                  items.add(_suggestedUsersCarousel(chunk));
                  suggestedIndex += 6;
                }
              }
            }

            // append remaining suggested users at the end
            if (suggestedIndex < suggested.length) {
              items.add(_suggestedUsersCarousel(
                  suggested.skip(suggestedIndex).toList()));
            }
          }

          return RefreshIndicator(
            color: Colors.blue,
            onRefresh: () async {
              await _loadFriends();
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: items,
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // 🔍 SEARCH BAR
  // ──────────────────────────────────────────────────────────
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
            )
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          decoration: const InputDecoration(
            hintText: "Search your network...",
            prefixIcon: Icon(Icons.search, color: Colors.blue),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // 🔥 FEED ITEM — repost or liked product
  // ──────────────────────────────────────────────────────────
  Widget _feedItem(Map<String, dynamic> item) {
    if (item['type'] == 'repost') {
      return _repostCard(item);
    } else {
      return _likedCard(item);
    }
  }

  // ──────────────────────────────────────────────────────────
  // 🔁 REPOST CARD (Instagram-style)
  // ──────────────────────────────────────────────────────────
  Widget _repostCard(Map<String, dynamic> item) {
    final d = item['data'] as Map<String, dynamic>;
    final productId = (d['productId'] ?? '').toString();
    final collection = (d['collection'] ?? '').toString();

    final userName = d['repostedByName'] ?? 'User';
    final userImage = (d['repostedByImage'] ?? '').toString();
    final productName = d['product_name'] ?? '';
    final price = d['priceonplatform'] ?? 0;
    final image = _extractImage(d);
    final ts = d['repostedAt'] as Timestamp?;

    // search filter
    if (_searchQuery.isNotEmpty &&
        !productName.toString().toLowerCase().contains(_searchQuery) &&
        !userName.toString().toLowerCase().contains(_searchQuery)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage:
                  userImage.isNotEmpty ? NetworkImage(userImage) : null,
                  child: userImage.isEmpty
                      ? const Icon(Icons.person,
                      color: Colors.white, size: 20)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text: userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const TextSpan(
                              text: "  reposted",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _timeAgo(ts),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.repeat_rounded,
                          color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        "Repost",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── PRODUCT IMAGE ──
          GestureDetector(
            onTap: () => _openProduct(d, productId, collection),
            child: AspectRatio(
              aspectRatio: 1,
              child: _imageWidget(image),
            ),
          ),

          // ── PRODUCT INFO + ACTIONS ──
          _productFooter(
            productName: productName.toString(),
            price: price,
            points: _calcPoints(d),
            onBuy: () => _buyProduct(d, productId, collection),
            onView: () => _openProduct(d, productId, collection),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // ❤️ LIKED CARD
  // ──────────────────────────────────────────────────────────
  Widget _likedCard(Map<String, dynamic> item) {
    final d = item['data'] as Map<String, dynamic>;
    final friend = item['friend'] as Map<String, dynamic>;
    final productId = item['productId'] as String;
    final collection = item['collection'] as String;
    final ts = item['sort_ts'] as Timestamp?;

    final userName = friend['username'] ?? 'Friend';
    final userImage = (friend['profile_url'] ?? '').toString();
    final productName = d['product_name'] ?? '';
    final price = d['priceonplatform'] ?? 0;
    final image = _extractImage(d);

    if (_searchQuery.isNotEmpty &&
        !productName.toString().toLowerCase().contains(_searchQuery) &&
        !userName.toString().toLowerCase().contains(_searchQuery)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.red.shade100,
                  backgroundImage:
                  userImage.isNotEmpty ? NetworkImage(userImage) : null,
                  child: userImage.isEmpty
                      ? const Icon(Icons.person,
                      color: Colors.white, size: 20)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text: userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const TextSpan(
                              text: "  liked this",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _timeAgo(ts),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Color(0xFFD32F2F),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),

          // ── IMAGE ──
          GestureDetector(
            onTap: () => _openProduct(d, productId, collection),
            child: AspectRatio(
              aspectRatio: 1,
              child: _imageWidget(image),
            ),
          ),

          // ── INFO ──
          _productFooter(
            productName: productName.toString(),
            price: price,
            points: _calcPoints(d),
            onBuy: () => _buyProduct(d, productId, collection),
            onView: () => _openProduct(d, productId, collection),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // 🧱 SHARED FOOTER (product name, price, buttons)
  // ──────────────────────────────────────────────────────────
  Widget _productFooter({
    required String productName,
    required dynamic price,
    required double points,
    required VoidCallback onBuy,
    required VoidCallback onView,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            productName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                "\$$price",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                "${points.toStringAsFixed(2)} pts",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onBuy,
                  icon: const Icon(Icons.shopping_bag_outlined,
                      size: 16, color: Colors.white),
                  label: const Text(
                    "Buy Now",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined,
                      size: 16, color: Colors.blue),
                  label: const Text(
                    "View",
                    style: TextStyle(color: Colors.blue),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // 👥 SUGGESTED USERS CAROUSEL
  // ──────────────────────────────────────────────────────────
  Widget _suggestedUsersCarousel(List<Map<String, dynamic>> users) {
    if (users.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.group_add_outlined,
                    color: Colors.blue, size: 18),
                const SizedBox(width: 8),
                const Text(
                  "Suggested for you",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                Text(
                  "From ${widget.country}",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: users.length,
              itemBuilder: (context, i) {
                final u = users[i];
                return _suggestedUserCard(u);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestedUserCard(Map<String, dynamic> user) {
    final name = (user['username'] ?? 'User').toString();
    final phone = (user['phone_number'] ?? '').toString();
    final image = (user['profile_url'] ?? '').toString();

    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.blue.shade100,
            backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
            child: image.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 32)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Suggested",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _addFriend(name, phone, image),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Follow",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // 🛒 OPEN PRODUCT DETAILS
  // ──────────────────────────────────────────────────────────
  void _openProduct(
      Map<String, dynamic> data, String productId, String collection) {
    if (productId.isEmpty || collection.isEmpty) return;

    ShowProducts.showProductDetails(
      context: context,
      data: data,
      productId: productId,
      collection: collection,
      imageWidget: (d) => _imageWidget(_extractImage(d)),
      calcPoints: _calcPoints,
      shareProduct: (d, pid, col) async {},
    );
  }

  void _buyProduct(
      Map<String, dynamic> data, String productId, String collection) {
    PurchaseDialog.show(
      context: context,
      data: data,
      onConfirm: (qty, paymentMethod) async {
        await TransactionService.processPurchase(
          productData: {
            ...data,
            "category": collection.replaceFirst("products_", ""),
          },
          quantity: qty,
          source: "network",
          paymentMethod: paymentMethod,
          productId: productId,
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────
  // 🧰 HELPERS
  // ──────────────────────────────────────────────────────────
  String _timeAgo(Timestamp? ts) {
    if (ts == null) return "Just now";
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inSeconds < 60) return "${diff.inSeconds}s ago";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    if (diff.inDays < 30) return "${(diff.inDays / 7).floor()}w ago";
    return "${(diff.inDays / 30).floor()}mo ago";
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: 70, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            "Your network is empty",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Add friends to see their activity here",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _noFeedYet() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.dynamic_feed_outlined,
              size: 50, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            "No activity from your network yet",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Follow more people below to see their reposts and likes",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}