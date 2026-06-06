import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'secrets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AiHelper extends StatefulWidget {
  const AiHelper({super.key});

  @override
  State<AiHelper> createState() => _AiHelperState();
}

class _AiHelperState extends State<AiHelper> {
  late final GenerativeModel _model;
  late ChatSession _chat;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_Message> _messages = [];
  bool _isLoading = false;

  // === Define the tools the AI is allowed to call ===
  final _tools = [
    Tool(functionDeclarations: [
      FunctionDeclaration(
        'getBestSeller',
        'Returns the seller with the highest total income from sales. '
            'Use when the user asks about the best seller, top seller, who sells the most.',
        Schema(SchemaType.object, properties: {}),
      ),
      FunctionDeclaration(
        'getTopSellers',
        'Returns the top N sellers ranked by total income. '
            'Use when the user asks about top sellers (plural) or a ranking.',
        Schema(SchemaType.object, properties: {
          'limit': Schema(SchemaType.integer,
              description: 'How many sellers to return. Default 5.'),
        }),
      ),
      FunctionDeclaration(
        'getTopProducts',
        'Returns the most sold products across all categories (electronics, fashion, home). '
            'Use when the user asks about popular products, top items, best-selling products.',
        Schema(SchemaType.object, properties: {
          'limit': Schema(SchemaType.integer,
              description: 'How many products to return. Default 5.'),
        }),
      ),
      FunctionDeclaration(
        'getPlatformStats',
        'Returns global platform stats: total sales amount, total profit, total bonuses given. '
            'Use when the user asks about overall app stats, platform performance, totals.',
        Schema(SchemaType.object, properties: {}),
      ),
      FunctionDeclaration(
        'getSellerCount',
        'Returns the number of active sellers on the platform.',
        Schema(SchemaType.object, properties: {}),
      ),
    ]),
  ];

  // Quick-prompt suggestions shown in the empty state
  final List<_Suggestion> _suggestions = const [
    _Suggestion(
      icon: Icons.emoji_events_rounded,
      title: "Best seller",
      prompt: "Who is the best seller right now?",
    ),
    _Suggestion(
      icon: Icons.local_fire_department_rounded,
      title: "Top products",
      prompt: "What are the top 5 most popular products?",
    ),
    _Suggestion(
      icon: Icons.trending_up_rounded,
      title: "Trending",
      prompt: "What's trending on the app today?",
    ),
    _Suggestion(
      icon: Icons.lightbulb_outline_rounded,
      title: "Tips",
      prompt: "Give me a tip to grow my sales.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: geminiApiKey,
      tools: _tools,
      systemInstruction: Content.system(
        "You are a helpful assistant inside the Zing app. "
            "When users ask about app data (sellers, products, stats), use the "
            "provided tools to fetch real data — never invent numbers. "
            "Keep answers concise and friendly.",
      ),
    );
    _chat = _model.startChat();
  }

  // === What each tool actually does ===
  Future<Map<String, dynamic>> _runTool(FunctionCall call) async {
    final fs = FirebaseFirestore.instance;

    switch (call.name) {
      case 'getBestSeller':
        {
          // Aggregate sales by seller_name from the sales collection
          final snap = await fs.collection('sales').get();
          final Map<String, double> totals = {};
          for (final doc in snap.docs) {
            final d = doc.data();
            final name = (d['seller_name'] ?? 'Unknown') as String;
            final income = (d['total_income_for_seller'] ?? 0).toDouble();
            totals[name] = (totals[name] ?? 0) + income;
          }
          if (totals.isEmpty) return {'result': 'No sales yet'};
          final best = totals.entries
              .reduce((a, b) => a.value > b.value ? a : b);
          return {
            'name': best.key,
            'totalIncome': best.value.toStringAsFixed(2),
          };
        }

      case 'getTopSellers':
        {
          final limit = (call.args['limit'] as int?) ?? 5;
          final snap = await fs.collection('sales').get();
          final Map<String, double> totals = {};
          for (final doc in snap.docs) {
            final d = doc.data();
            final name = (d['seller_name'] ?? 'Unknown') as String;
            final income = (d['total_income_for_seller'] ?? 0).toDouble();
            totals[name] = (totals[name] ?? 0) + income;
          }
          final sorted = totals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          return {
            'sellers': sorted.take(limit).map((e) => {
              'name': e.key,
              'totalIncome': e.value.toStringAsFixed(2),
            }).toList(),
          };
        }

      case 'getTopProducts':
        {
          final limit = (call.args['limit'] as int?) ?? 5;
          // Aggregate quantity_sold per product_name from sales
          final snap = await fs.collection('sales').get();
          final Map<String, int> productCounts = {};
          for (final doc in snap.docs) {
            final d = doc.data();
            final name = (d['product_name'] ?? 'Unknown') as String;
            final qty = (d['quantity_sold'] ?? 0) as int;
            productCounts[name] = (productCounts[name] ?? 0) + qty;
          }
          final sorted = productCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          return {
            'products': sorted.take(limit).map((e) => {
              'name': e.key,
              'quantitySold': e.value,
            }).toList(),
          };
        }

      case 'getPlatformStats':
        {
          final doc = await fs.collection('totals').doc('global_totals').get();
          if (!doc.exists) return {'result': 'No totals available'};
          final d = doc.data()!;
          return {
            'totalSales': (d['total_sales'] ?? 0).toStringAsFixed(2),
            'totalProfit': (d['total_profit'] ?? 0).toStringAsFixed(2),
            'totalBonus': (d['total_bonus'] ?? 0).toStringAsFixed(2),
          };
        }

      case 'getSellerCount':
        {
          final snap = await fs
              .collection('sellers')
              .where('status', isEqualTo: 'active')
              .get();
          return {'activeSellerCount': snap.docs.length};
        }

      default:
        return {'error': 'Unknown tool: ${call.name}'};
    }
  }

  Future<void> _sendMessage({String? overrideText}) async {
    final text = (overrideText ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      var response = await _chat.sendMessage(Content.text(text));

      while (response.functionCalls.isNotEmpty) {
        final results = <FunctionResponse>[];
        for (final call in response.functionCalls) {
          final result = await _runTool(call);
          results.add(FunctionResponse(call.name, result));
        }
        response = await _chat.sendMessage(
          Content.functionResponses(results),
        );
      }

      final reply = response.text ?? "Sorry, I couldn't generate a response.";
      setState(() {
        _messages.add(_Message(text: reply, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.add(_Message(
          text: "Error: ${e.toString()}",
          isUser: false,
          isError: true,
        ));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ── INSTAGRAM-STYLE APP BAR ─────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFEFEFEF), width: 0.5),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // ── AI AVATAR WITH STORY-GRADIENT RING ──────
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFEDA75),
                          Color(0xFFFA7E1E),
                          Color(0xFFD62976),
                          Color(0xFF833AB4),
                        ],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFAFAFA),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.black,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ── TITLE + STATUS ──────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "AI Assistant",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF44C25C),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              "Online",
                              style: TextStyle(
                                color: Color(0xFF8E8E8E),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // ── NEW CHAT BUTTON ─────────────────────────
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _messages.clear();
                        _chat = _model.startChat();
                      });
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0095F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFF0095F6),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // ── BODY ─────────────────────────────────────────────
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _emptyState()
                : ListView.builder(
              controller: _scrollController,
              padding:
              const EdgeInsets.fromLTRB(12, 16, 12, 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _bubble(_messages[index]),
            ),
          ),

          // ── TYPING INDICATOR ──────────────────────────────
          if (_isLoading) _typingIndicator(),

          // ── INPUT BAR ─────────────────────────────────────
          _inputBar(),
        ],
      ),
    );
  }

  // 🎨 EMPTY STATE — STORY-RING AVATAR + SUGGESTION CHIPS
  Widget _emptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // Large gradient ring with sparkle icon
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFEDA75),
                  Color(0xFFFA7E1E),
                  Color(0xFFD62976),
                  Color(0xFF833AB4),
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Container(
                width: 78,
                height: 78,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFAFAFA),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.black,
                  size: 34,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            "Hey there 👋",
            style: TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Ask me anything about Zing",
            style: TextStyle(
              color: Color(0xFF8E8E8E),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 36),

          // ── SECTION DIVIDER ──────────────────────────────
          const Row(
            children: [
              Expanded(
                child: Divider(color: Color(0xFFEFEFEF), height: 1),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "TRY ASKING",
                  style: TextStyle(
                    color: Color(0xFF8E8E8E),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: Color(0xFFEFEFEF), height: 1),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── SUGGESTION CHIPS ─────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: _suggestions
                .map((s) => _suggestionChip(s))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _suggestionChip(_Suggestion s) {
    return GestureDetector(
      onTap: () => _sendMessage(overrideText: s.prompt),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF0095F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                s.icon,
                color: const Color(0xFF0095F6),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎨 MESSAGE BUBBLE — Instagram DM style
  Widget _bubble(_Message m) {
    if (m.isError) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.red.shade400, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: SelectableText(
                m.text,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isUser = m.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // AI avatar on the left
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFEDA75),
                    Color(0xFFFA7E1E),
                    Color(0xFFD62976),
                    Color(0xFF833AB4),
                  ],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFAFAFA),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.black,
                    size: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF0095F6)
                    : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(color: const Color(0xFFEFEFEF)),
              ),
              child: SelectableText(
                m.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 TYPING INDICATOR — AI avatar + animated dots feel
  Widget _typingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(1.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFEDA75),
                  Color(0xFFFA7E1E),
                  Color(0xFFD62976),
                  Color(0xFF833AB4),
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFAFAFA),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.black,
                  size: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: const Color(0xFFEFEFEF)),
            ),
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF0095F6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 INPUT BAR — Instagram DM style pill
  Widget _inputBar() {
    final hasText = _controller.text.trim().isNotEmpty;
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFEFEFEF), width: 0.5),
          ),
        ),
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── INPUT FIELD ──────────────────────────────
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 42),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: const Color(0xFFEFEFEF), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          contentPadding:
                          EdgeInsets.symmetric(vertical: 12),
                          border: InputBorder.none,
                          hintText: "Message AI Assistant…",
                          hintStyle: TextStyle(
                            color: Color(0xFF8E8E8E),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ── SEND BUTTON ──────────────────────────────
            GestureDetector(
              onTap: (_isLoading || !hasText) ? null : _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (hasText && !_isLoading)
                      ? const Color(0xFF0095F6)
                      : const Color(0xFF0095F6).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isUser;
  final bool isError;
  _Message({required this.text, required this.isUser, this.isError = false});
}

class _Suggestion {
  final IconData icon;
  final String title;
  final String prompt;
  const _Suggestion({
    required this.icon,
    required this.title,
    required this.prompt,
  });
}