import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// Match the class name used in your HomePage
class ai_helper extends StatefulWidget {
  const ai_helper({super.key});

  @override
  State<ai_helper> createState() => _ai_helperState();
}

class _ai_helperState extends State<ai_helper> {
  final TextEditingController _controller = TextEditingController();

  // 🔑 PASTE YOUR KEY HERE
  static const String _apiKey = 'AQ.Ab8RN6I5A94Qmh372Fad8gcoe1hMvGF4zprRbT3C4YRhjTtpzA';

  late final GenerativeModel _model;
  late final ChatSession _chat;
  final List<Content> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
          "You are the Zing AI Assistant. You help users with marketplace questions "
              "about electronics, fashion, and prizes. Be concise and friendly."
      ),
    );
    _chat = _model.startChat();
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final userMessage = _controller.text;
    setState(() {
      _messages.add(Content.text(userMessage));
      _isLoading = true;
    });
    _controller.clear();

    try {
      final response = await _chat.sendMessage(Content.text(userMessage));
      setState(() {
        if (response.text != null) {
          _messages.add(Content.model([TextPart(response.text!)]));
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816), // Matching your AppColors.bg
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
              child: Text(
                "How can I help you with Zing today?",
                style: TextStyle(color: Colors.white70),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final content = _messages[index];
                final isUser = content.role == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFFE11D48) : const Color(0xFF111827),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: Radius.circular(isUser ? 15 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 15),
                      ),
                    ),
                    child: Text(
                      content.parts.whereType<TextPart>().map((e) => e.text).join(),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: LinearProgressIndicator(color: Color(0xFFE11D48)),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF111827),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF050816),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFFE11D48),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}