import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPanel extends StatelessWidget {
  const NotificationsPanel({super.key});

  // 🎨 Instagram-style palette (same as Net feed)
  static const Color _igBlue = Color(0xFF0095F6);
  static const Color _igText = Color(0xFF262626);
  static const Color _igSecondary = Color(0xFF8E8E8E);
  static const Color _igBorder = Color(0xFFDBDBDB);
  static const Color _igBg = Color(0xFFFAFAFA);
  static const Color _igRed = Color(0xFFED4956);

  Stream<QuerySnapshot> _stream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection("notifications")
        .where("receiver_id", isEqualTo: uid)
        .snapshots();
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
    return '${(diff.inDays / 30).floor()}mo';
  }

  String _sectionFor(DateTime? date) {
    if (date == null) return 'Earlier';
    final diff = DateTime.now().difference(date);
    if (diff.inHours < 24) return 'New';
    if (diff.inDays < 7) return 'This Week';
    if (diff.inDays < 30) return 'This Month';
    return 'Earlier';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Notifications",
                style: TextStyle(
                  color: _igText,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Thin divider under header (IG style)
          Container(height: 0.5, color: _igBorder),

          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _stream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _igText,
                      strokeWidth: 2,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _emptyState();
                }

                // Sort manually (since orderBy is removed)
                final docs = snapshot.data!.docs.toList()
                  ..sort((a, b) {
                    final ta = (a.data() as Map<String, dynamic>)['created_at']
                    as Timestamp?;
                    final tb = (b.data() as Map<String, dynamic>)['created_at']
                    as Timestamp?;
                    if (ta == null && tb == null) return 0;
                    if (ta == null) return 1;
                    if (tb == null) return -1;
                    return tb.compareTo(ta);
                  });

                // Group by time section
                final Map<String, List<QueryDocumentSnapshot>> grouped = {};
                for (final d in docs) {
                  final data = d.data() as Map<String, dynamic>;
                  final ts = (data['created_at'] as Timestamp?)?.toDate();
                  grouped.putIfAbsent(_sectionFor(ts), () => []).add(d);
                }

                const order = ['New', 'This Week', 'This Month', 'Earlier'];
                final sections = order.where(grouped.containsKey).toList();

                // Flatten into items: [header, tile, tile, header, tile, ...]
                final List<Widget> items = [];
                for (final s in sections) {
                  items.add(_sectionHeader(s));
                  for (final doc in grouped[s]!) {
                    items.add(_notificationTile(doc));
                  }
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: items.length,
                  itemBuilder: (_, i) => items[i],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------- UI BUILDERS ----------

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _igText, width: 2),
            ),
            child: const Icon(Icons.favorite_border,
                color: _igText, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            "Activity On Your Posts",
            style: TextStyle(
              color: _igText,
              fontSize: 20,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "When someone likes or comments on one of your posts, you'll see it here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _igSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: _igText,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _notificationTile(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final id = doc.id;
    final isRead = data['is_read'] ?? false;
    final title = data['title'] ?? '';
    final body = data['body'] ?? '';
    final avatarUrl = data['sender_avatar'] as String?;
    final senderName = data['sender_name'] as String?;
    final thumbnailUrl = data['post_thumbnail'] as String?;
    final type = (data['type'] as String?) ?? '';
    final ts = (data['created_at'] as Timestamp?)?.toDate();
    final timeText = _timeAgo(ts);

    final displayName = senderName ?? title;

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        await FirebaseFirestore.instance
            .collection("notifications")
            .doc(id)
            .delete();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: _igRed,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Material(
        color: isRead ? Colors.white : _igBg,
        child: InkWell(
          onTap: () async {
            await FirebaseFirestore.instance
                .collection("notifications")
                .doc(id)
                .update({"is_read": true});
          },
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _avatar(avatarUrl, displayName, type),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: _igText,
                        fontSize: 14,
                        height: 1.35,
                      ),
                      children: [
                        TextSpan(
                          text: displayName,
                          style:
                          const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: '  '),
                        TextSpan(text: body),
                        if (timeText.isNotEmpty)
                          TextSpan(
                            text: '  $timeText',
                            style: const TextStyle(
                              color: _igSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _trailing(type, thumbnailUrl, isRead),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatar(String? url, String fallbackText, String type) {
    final hasUrl = url != null && url.isNotEmpty;
    final initial =
    fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?';

    final inner = hasUrl
        ? ClipOval(
      child: Image.network(
        url,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initialAvatar(initial),
      ),
    )
        : _initialAvatar(initial);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        inner,
        if (type.isNotEmpty)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _igBorder, width: 0.5),
              ),
              child: Icon(
                _iconForType(type),
                size: 12,
                color: _colorForType(type),
              ),
            ),
          ),
      ],
    );
  }

  Widget _initialAvatar(String initial) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF833AB4),
            Color(0xFFE1306C),
            Color(0xFFF77737),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.chat_bubble;
      case 'follow':
        return Icons.person_add_alt_1;
      case 'mention':
        return Icons.alternate_email;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'like':
        return _igRed;
      case 'comment':
        return _igBlue;
      case 'follow':
        return Colors.purple;
      default:
        return _igSecondary;
    }
  }

  Widget _trailing(String type, String? thumbnailUrl, bool isRead) {
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          thumbnailUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 44,
            height: 44,
            color: _igBg,
          ),
        ),
      );
    }
    if (type == 'follow') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: _igBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Follow',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      );
    }
    if (!isRead) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: _igBlue,
          shape: BoxShape.circle,
        ),
      );
    }
    return const SizedBox(width: 8);
  }
}