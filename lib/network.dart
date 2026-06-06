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
  // 🎨 Instagram-style palette
  static const Color _igBlue = Color(0xFF0095F6);
  static const Color _igText = Color(0xFF262626);
  static const Color _igSecondary = Color(0xFF8E8E8E);
  static const Color _igBorder = Color(0xFFDBDBDB);
  static const Color _igBg = Color(0xFFFAFAFA);
  static const Color _igRed = Color(0xFFED4956);

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

  // 🔥 LOCAL UI STATE (likes/saves) - non-persisted, instant feedback
  final Set<String> _likedItems = {};
  final Set<String> _savedItems = {};
// ──────────────────────────────────────────────────────────
// 🔎 SEARCHED USERS — finds users matching _searchQuery
// ──────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _findMatchingUsers(
      List<Map<String, dynamic>> suggested) {
    if (_searchQuery.isEmpty) return [];

    final results = <Map<String, dynamic>>[];
    final seenPhones = <String>{};

    // a) match inside suggested users
    for (final user in suggested) {
      final name = (user['username'] ?? '').toString().toLowerCase();
      final phone = (user['phone_number'] ?? '').toString();
      if (phone.isEmpty || seenPhones.contains(phone)) continue;
      if (name.contains(_searchQuery)) {
        results.add(user);
        seenPhones.add(phone);
      }
    }

    // b) also match inside friends (already-followed people)
    for (final entry in _friendInfoByPhone.entries) {
      final phone = entry.key;
      final user = entry.value;
      final name = (user['username'] ?? '').toString().toLowerCase();
      if (phone.isEmpty || seenPhones.contains(phone)) continue;
      if (name.contains(_searchQuery)) {
        results.add(user);
        seenPhones.add(phone);
      }
    }

    return results;
  }

// ──────────────────────────────────────────────────────────
// 🔎 SEARCHED USERS SECTION (renders the matching user cards)
// ──────────────────────────────────────────────────────────
  Widget _searchedUsersSection(List<Map<String, dynamic>> users) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _igBorder, width: 0.5),
              ),
            ),
            child: Text(
              'Users matching "$_searchQuery"',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _igText,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, i) => _searchedUserTile(users[i]),
          ),
          const SizedBox(height: 6),
          _thinDivider(),
        ],
      ),
    );
  }

  Widget _searchedUserTile(Map<String, dynamic> user) {
    final name  = (user['username']     ?? 'User').toString();
    final phone = (user['phone_number'] ?? '').toString();
    final image = (user['profile_url']  ?? '').toString();
    final isFriend = _friendsPhones.contains(phone);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _igBg,
            backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
            child: image.isEmpty
                ? Icon(Icons.person, color: Colors.grey.shade400, size: 24)
                : null,
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
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _igText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isFriend ? "Following" : "Suggested for you",
                  style: const TextStyle(
                    fontSize: 12,
                    color: _igSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!isFriend)
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: () => _addFriend(name, phone, image),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _igBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  "Follow",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _igBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _igBorder),
              ),
              child: const Text(
                "Following",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _igText,
                ),
              ),
            ),
        ],
      ),
    );
  }
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
  // 🔥 LOAD FRIENDS + RESOLVE THEIR IDS  (UNCHANGED)
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

      if (mounted) setState(() => _friendsLoaded = true);
    } catch (e) {
      debugPrint("loadFriends error: $e");
      if (mounted) setState(() => _friendsLoaded = true);
    }
  }

  // ──────────────────────────────────────────────────────────
  // 🔥 IMAGE WIDGET
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
      color: _igBg,
      child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 40),
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
            content: Text("Now following $name"),
            backgroundColor: _igText,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await _loadFriends();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("addFriend error: $e");
    }
  }

  // ──────────────────────────────────────────────────────────
  // 🔥 BUILD THE FEED  (UNCHANGED LOGIC)
  // ──────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _buildFeed() async {
    if (_friendsUids.isEmpty && _friendsPhones.isEmpty) return [];

    final List<Map<String, dynamic>> feed = [];
    final Set<String> seenRepostIds = {};

    // ── 1A) REPOSTS BY UID ──
    try {
      for (int i = 0; i < _friendsUids.length; i += 10) {
        final batch = _friendsUids.skip(i).take(10).toList();
        if (batch.isEmpty) continue;

        try {
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

    // ── 1B) REPOSTS BY PHONE ──
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

    // ── 2) LIKED PRODUCTS FROM FRIENDS ──
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

    // ── 3) SORT BY TIMESTAMP ──
    feed.sort((a, b) {
      final ta = a['sort_ts'] as Timestamp?;
      final tb = b['sort_ts'] as Timestamp?;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });

    return feed;
  }

  // ──────────────────────────────────────────────────────────
  // 🔥 SUGGESTED USERS  (UNCHANGED LOGIC)
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

  // ════════════════════════════════════════════════════════════
  // 🎨 BUILD METHOD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: !_friendsLoaded
          ? const Center(
        child: CircularProgressIndicator(
          color: _igText,
          strokeWidth: 2,
        ),
      )
          : FutureBuilder<List<dynamic>>(
        future: Future.wait([
          _buildFeed(),
          _fetchSuggestedUsers(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: _igText,
                strokeWidth: 2,
              ),
            );
          }

          final feed =
          (snapshot.data![0] as List<Map<String, dynamic>>);
          final suggested =
          (snapshot.data![1] as List<Map<String, dynamic>>);

          if (feed.isEmpty &&
              suggested.isEmpty &&
              _friendsPhones.isEmpty) {
            return RefreshIndicator(
              color: _igText,
              onRefresh: () async {
                await _loadFriends();
                setState(() {});
              },
              child: ListView(
                children: [

                  const SizedBox(height: 60),
                  _emptyState(),
                ],
              ),
            );
          }

          // 🔥 BUILD LIST
          final List<Widget> items = [];

// 🔎 If user is searching, show matching users at the TOP
          if (_searchQuery.isNotEmpty) {
            final matchedUsers = _findMatchingUsers(suggested);
            if (matchedUsers.isNotEmpty) {
              items.add(_searchedUsersSection(matchedUsers));
            }
          } else {
            // Stories row (only when NOT searching, otherwise it's noisy)
            if (suggested.isNotEmpty) {
              items.add(_storiesRow(suggested.take(12).toList()));
              items.add(_thinDivider());
            }
          }

          if (feed.isEmpty) {
            items.add(_noFeedYet());
            if (suggested.length > 12) {
              items.add(_suggestedUsersCarousel(
                  suggested.skip(12).toList()));
            }
          } else {
            // Use suggested users beyond what we showed in stories
            final remainingSuggested =
            suggested.length > 12 ? suggested.skip(12).toList() : [];
            int suggestedIndex = 0;

            for (int i = 0; i < feed.length; i++) {
              items.add(_feedItem(feed[i]));

              // inject suggested users carousel every 4 posts
              if ((i + 1) % 4 == 0 &&
                  suggestedIndex < remainingSuggested.length) {
                final chunk = remainingSuggested
                    .skip(suggestedIndex)
                    .take(6)
                    .toList()
                    .cast<Map<String, dynamic>>();
                if (chunk.isNotEmpty) {
                  items.add(_suggestedUsersCarousel(chunk));
                  suggestedIndex += 6;
                }
              }
            }

            if (suggestedIndex < remainingSuggested.length) {
              items.add(_suggestedUsersCarousel(remainingSuggested
                  .skip(suggestedIndex)
                  .toList()
                  .cast<Map<String, dynamic>>()));
            }

            items.add(_endOfFeed());
          }

          return RefreshIndicator(
            color: _igText,
            onRefresh: () async {
              await _loadFriends();
              setState(() {});
            },
            child: ListView(
              padding: EdgeInsets.zero,
              children: items,
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // 🎨 APP BAR (Instagram style)
  // ──────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.white,
      automaticallyImplyLeading: false,

      title: Container(
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(
            color: Colors.black, // typed text color
            fontSize: 15,
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value.toLowerCase());
          },
          decoration: InputDecoration(
            hintText: "Search...",
            hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),

      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
          height: 0.5,
          color: _igBorder,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // 🔍 SEARCH BAR (IG style — pill, light grey)
  // ──────────────────────────────────────────────────────────
  /*Widget _searchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: _igSecondary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                cursorColor: _igText,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                style: const TextStyle(fontSize: 14, color: _igText),
                decoration: const InputDecoration(
                  hintText: "Search",
                  hintStyle: TextStyle(color: _igSecondary, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = "");
                },
                child: const Icon(Icons.cancel,
                    color: _igSecondary, size: 18),
              ),
          ],
        ),
      ),
    );
  }*/

  // ──────────────────────────────────────────────────────────
  // 📖 STORIES ROW (suggested users as story bubbles)
  // ──────────────────────────────────────────────────────────
  Widget _storiesRow(List<Map<String, dynamic>> users) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 110,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: users.length,
          itemBuilder: (context, i) => _storyAvatar(users[i]),
        ),
      ),
    );
  }

  Widget _storyAvatar(Map<String, dynamic> user) {
    final name = (user['username'] ?? 'User').toString();
    final phone = (user['phone_number'] ?? '').toString();
    final image = (user['profile_url'] ?? '').toString();

    return GestureDetector(
      onTap: () => _showUserProfile(user),
      child: Container(
        width: 130,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _igBorder, width: 0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: _igBg,
                  backgroundImage:
                  image.isNotEmpty ? NetworkImage(image) : null,
                  child: image.isEmpty
                      ? Icon(Icons.person,
                      color: Colors.grey.shade400, size: 26)
                      : null,
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _igBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add,
                        color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: _igText,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ──────────────────────────────────────────────────────────
  // 🔥 FEED ITEM
  // ──────────────────────────────────────────────────────────
  Widget _feedItem(Map<String, dynamic> item) {
    if (item['type'] == 'repost') return _repostCard(item);
    return _likedCard(item);
  }

  // ──────────────────────────────────────────────────────────
  // 🔁 REPOST CARD
  // ──────────────────────────────────────────────────────────
  Widget _repostCard(Map<String, dynamic> item) {
    final d = item['data'] as Map<String, dynamic>;
    final productId = (d['productId'] ?? '').toString();
    final collection = (d['collection'] ?? '').toString();
    final docId = item['doc_id'] as String;

    final userName = (d['repostedByName'] ?? 'User').toString();
    final userImage = (d['repostedByImage'] ?? '').toString();
    final productName = (d['product_name'] ?? '').toString();
    final price = d['priceonplatform'] ?? 0;
    final image = _extractImage(d);
    final ts = d['repostedAt'] as Timestamp?;

    if (_searchQuery.isNotEmpty &&
        !productName.toLowerCase().contains(_searchQuery) &&
        !userName.toLowerCase().contains(_searchQuery)) {
      return const SizedBox.shrink();
    }

    return _instagramPost(
      itemId: docId,
      userName: userName,
      userImage: userImage,
      actionLabel: "reposted",
      actionIcon: Icons.repeat_rounded,
      image: image,
      productName: productName,
      price: price,
      points: _calcPoints(d),
      timestamp: ts,
      onTap: () => _openProduct(d, productId, collection),
      onBuy: () => _buyProduct(d, productId, collection),
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
    final docId = item['doc_id'] as String;

    final userName = (friend['username'] ?? 'Friend').toString();
    final userImage = (friend['profile_url'] ?? '').toString();
    final productName = (d['product_name'] ?? '').toString();
    final price = d['priceonplatform'] ?? 0;
    final image = _extractImage(d);

    if (_searchQuery.isNotEmpty &&
        !productName.toLowerCase().contains(_searchQuery) &&
        !userName.toLowerCase().contains(_searchQuery)) {
      return const SizedBox.shrink();
    }

    return _instagramPost(
      itemId: docId,
      userName: userName,
      userImage: userImage,
      actionLabel: "liked",
      actionIcon: Icons.favorite,
      image: image,
      productName: productName,
      price: price,
      points: _calcPoints(d),
      timestamp: ts,
      onTap: () => _openProduct(d, productId, collection),
      onBuy: () => _buyProduct(d, productId, collection),
    );
  }

  // ──────────────────────────────────────────────────────────
  // 🎨 THE INSTAGRAM POST WIDGET
  // ──────────────────────────────────────────────────────────
  Widget _instagramPost({
    required String itemId,
    required String userName,
    required String userImage,
    required String actionLabel,
    required IconData actionIcon,
    required dynamic image,
    required String productName,
    required dynamic price,
    required double points,
    required Timestamp? timestamp,
    required VoidCallback onTap,
    required VoidCallback onBuy,
  }) {
    final isLiked = _likedItems.contains(itemId);
    final isSaved = _savedItems.contains(itemId);

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _igBorder, width: 0.5),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: _igBg,
                    backgroundImage:
                    userImage.isNotEmpty ? NetworkImage(userImage) : null,
                    child: userImage.isEmpty
                        ? Icon(Icons.person,
                        color: Colors.grey.shade400, size: 18)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              userName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                color: _igText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(actionIcon,
                              size: 11,
                              color: actionLabel == "liked"
                                  ? _igRed
                                  : _igSecondary),
                          const SizedBox(width: 3),
                          Text(
                            actionLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _igSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _timeAgo(timestamp),
                        style: const TextStyle(
                          fontSize: 11,
                          color: _igSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 22),
                  color: _igText,
                  onPressed: () => _showPostOptions(userName),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),

          // ── IMAGE (square, edge-to-edge) ──
          GestureDetector(
            onTap: onTap,
            onDoubleTap: () {
              setState(() {
                if (_likedItems.contains(itemId)) {
                  _likedItems.remove(itemId);
                } else {
                  _likedItems.add(itemId);
                }
              });
            },
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: _igBg,
                child: _imageWidget(image),
              ),
            ),
          ),

          // ── ACTION ROW ──
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 26,
                    color: isLiked ? _igRed : _igText,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isLiked) {
                        _likedItems.remove(itemId);
                      } else {
                        _likedItems.add(itemId);
                      }
                    });
                  },
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  constraints: const BoxConstraints(),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    size: 26,
                  ),
                  color: _igText,
                  onPressed: () {
                    setState(() {
                      if (isSaved) {
                        _savedItems.remove(itemId);
                      } else {
                        _savedItems.add(itemId);
                      }
                    });
                  },
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // ── LIKES COUNT ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
            child: Text(
              isLiked ? "Liked by you and others" : "Be the first to like",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _igText,
              ),
            ),
          ),

          // ── CAPTION (username + product name) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: const TextStyle(
                    color: _igText, fontSize: 13.5, height: 1.3),
                children: [
                  TextSpan(
                    text: "$userName ",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: productName),
                ],
              ),
            ),
          ),

          // ── VIEW COMMENTS ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
            child: GestureDetector(
              onTap: onTap,
              child: const Text(
                "View product details",
                style: TextStyle(
                  fontSize: 13,
                  color: _igSecondary,
                ),
              ),
            ),
          ),

          // ── PRICE + POINTS + SHOP BUTTON ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: Row(
              children: [
                Text(
                  "\$$price",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _igText,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6E0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "+${points.toStringAsFixed(2)} pts",
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onBuy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: _igBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Buy now",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // 👥 SUGGESTED USERS CAROUSEL (mid-feed, IG style)
  // ──────────────────────────────────────────────────────────
  Widget _suggestedUsersCarousel(List<Map<String, dynamic>> users) {
    if (users.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: _igBorder, width: 0.5),
                bottom: BorderSide(color: _igBorder, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  "Suggested for you",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _igText,
                  ),
                ),
                const Spacer(),
                Text(
                  "See All",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _igText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: users.length,
              itemBuilder: (context, i) => _suggestedUserCard(users[i]),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _suggestedUserCard(Map<String, dynamic> user) {
    final name = (user['username'] ?? 'User').toString();
    final phone = (user['phone_number'] ?? '').toString();
    final image = (user['profile_url'] ?? '').toString();

    return Container(
      width: 130,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _igBorder, width: 0.5),
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          CircleAvatar(
            radius: 30,
            backgroundColor: _igBg,
            backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
            child: image.isEmpty
                ? Icon(Icons.person, color: Colors.grey.shade400, size: 30)
                : null,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _igText,
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              "Suggested for you",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _igSecondary,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              width: double.infinity,
              height: 30,
              child: ElevatedButton(
                onPressed: () => _addFriend(name, phone, image),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _igBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  "Follow",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // ⚙️ POST OPTIONS BOTTOM SHEET (Instagram-style)
  // ──────────────────────────────────────────────────────────
  void _showPostOptions(String userName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              _bottomSheetTile(
                  Icons.bookmark_border, "Save", _igText, () {
                Navigator.pop(ctx);
              }),
              _bottomSheetTile(Icons.link, "Copy link", _igText, () {
                Navigator.pop(ctx);
              }),
              _bottomSheetTile(
                  Icons.share_outlined, "Share to...", _igText, () {
                Navigator.pop(ctx);
              }),
              _bottomSheetTile(
                  Icons.flag_outlined, "Report", _igRed, () {
                Navigator.pop(ctx);
              }),
              _bottomSheetTile(
                  Icons.person_remove_outlined, "Unfollow $userName",
                  _igRed, () {
                Navigator.pop(ctx);
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _bottomSheetTile(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
// ──────────────────────────────────────────────────────────
// 👤 USER PROFILE POPUP
// ──────────────────────────────────────────────────────────
  void _showUserProfile(Map<String, dynamic> user) {
    final name    = (user['username']     ?? 'User').toString();
    final phone   = (user['phone_number'] ?? '').toString();
    final image   = (user['profile_url']  ?? '').toString();
    final country = (user['country']      ?? '—').toString();

    // try common field names for join date
    final joinedAt = user['created_at']
        ?? user['createdAt']
        ?? user['joined_at']
        ?? user['joinedAt']
        ?? user['signup_date'];

    String joinDateStr = '—';
    if (joinedAt is Timestamp) {
      final d = joinedAt.toDate();
      const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      joinDateStr = '${months[d.month - 1]} ${d.day}, ${d.year}';
    }

    final isFriend = _friendsPhones.contains(phone);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile image with IG-style ring
              // Profile image (plain, no story ring)
              CircleAvatar(
                radius: 46,
                backgroundColor: _igBg,
                backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                child: image.isEmpty
                    ? Icon(Icons.person, color: Colors.grey.shade400, size: 48)
                    : null,
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _igText,
                ),
              ),
              const SizedBox(height: 18),

              // Info card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _igBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _profileInfoRow(Icons.location_on_outlined, "Country", country),
                    const SizedBox(height: 12),
                    _profileInfoRow(Icons.phone_outlined, "Phone",
                        phone.isEmpty ? '—' : phone),
                    const SizedBox(height: 12),
                    _profileInfoRow(Icons.calendar_today_outlined, "Joined", joinDateStr),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _igText,
                        side: const BorderSide(color: _igBorder),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Close",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  if (!isFriend && phone.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _addFriend(name, phone, image);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _igBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Follow",
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _igSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: _igSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              color: _igText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
  // ──────────────────────────────────────────────────────────
  // 🛒 ACTIONS
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
    if (ts == null) return "now";
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inSeconds < 60) return "${diff.inSeconds}s";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    if (diff.inDays < 7) return "${diff.inDays}d";
    if (diff.inDays < 30) return "${(diff.inDays / 7).floor()}w";
    return "${(diff.inDays / 30).floor()}mo";
  }

  Widget _thinDivider() {
    return Container(
      height: 0.5,
      color: _igBorder,
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _igText, width: 2),
              ),
              child: const Icon(Icons.person_outline,
                  size: 50, color: _igText),
            ),
            const SizedBox(height: 20),
            const Text(
              "Your feed is empty",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: _igText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "When you follow people, you'll see their reposts and likes here.",
              textAlign: TextAlign.center,
              style: TextStyle(color: _igSecondary, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noFeedYet() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _igText, width: 1.5),
            ),
            child: const Icon(Icons.camera_alt_outlined,
                size: 38, color: _igText),
          ),
          const SizedBox(height: 16),
          const Text(
            "No Posts Yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: _igText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Follow more people to see their activity in your feed.",
            textAlign: TextAlign.center,
            style: TextStyle(color: _igSecondary, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _endOfFeed() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline,
              color: Colors.grey.shade400, size: 32),
          const SizedBox(height: 8),
          const Text(
            "You're all caught up",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _igText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "You've seen all new posts from your network",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}