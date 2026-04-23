import 'package:flutter/material.dart';

class net extends StatefulWidget {
  final String username;
  final String userphonenumber;
  final String country;

  const net({
    super.key,
    required this.username,
    required this.userphonenumber,
    required this.country,
  });

  @override
  State<net> createState() => _netState();
}

class _netState extends State<net> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: "Search in Network...",
                    prefixIcon: Icon(Icons.search, color: Color(0xFF0F172A)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  onChanged: (value) {
                    print("Searching for: $value");
                  },
                ),
              ),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hub, size: 80, color: Color(0xFF0F172A)),
                      const SizedBox(height: 20),
                      const Text(
                        "Network Details",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A)
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "Username: ${widget.username}",
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Phone: ${widget.userphonenumber}",
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        "Country: ${widget.country}",
                        style: const TextStyle(fontSize: 18),
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
  }
}