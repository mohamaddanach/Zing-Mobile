import 'package:flutter/material.dart';

class PurchaseDialog {
  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> data,
    required Future<void> Function(int qty,String payementmethod) onConfirm,
  }) async {

    int qty = 1;
    String selectedPayment = "Cash on Delivery";

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          title: Text(data['product_name'] ?? ""),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// PAYMENT METHOD
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Payment Method",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedPayment,
                    isExpanded: true,

                    items: const [

                      DropdownMenuItem(
                        value: "Cash on Delivery",
                        child: Text("Cash on Delivery"),
                      ),

                      DropdownMenuItem(
                        value: "Wish Money",
                        child: Text("Wish Money"),
                      ),

                      DropdownMenuItem(
                        value: "BOB Card",
                        child: Text("BOB Card"),
                      ),

                      DropdownMenuItem(
                        value: "OMT",
                        child: Text("OMT"),
                      ),
                    ],

                    onChanged: (value) {
                      setState(() {
                        selectedPayment = value!;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// QTY CIRCLES
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Select Quantity",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                runSpacing: 10,

                children: List.generate(10, (index) {

                  final number = index + 1;
                  final selected = qty == number;

                  return GestureDetector(

                    onTap: () {
                      setState(() {
                        qty = number;
                      });
                    },

                    child: Container(
                      width: 45,
                      height: 45,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? Colors.red : Colors.white,

                        border: Border.all(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),

                      child: Center(
                        child: Text(
                          number.toString(),

                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : Colors.red,

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              Text(
                "Price: \$${data['priceonplatform']}",
              ),
            ],
          ),

          actions: [

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),

              child: const Text("Confirm"),

              onPressed: () async {

                Navigator.pop(context);

                await onConfirm(qty,selectedPayment);
              },
            ),
          ],
        ),
      ),
    );
  }
}