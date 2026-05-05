import 'package:flutter/material.dart';

class PurchaseDialog {
  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> data,
    required Future<void> Function(int qty) onConfirm,
  }) async {
    final qtyController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(data['product_name'] ?? ""),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Quantity",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Text("Price: \$${data['priceonplatform']}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Confirm"),
            onPressed: () async {
              final qty = int.tryParse(qtyController.text) ?? 0;
              if (qty <= 0) return;

              Navigator.pop(context);
              await onConfirm(qty);
            },
          ),
        ],
      ),
    );
  }
}