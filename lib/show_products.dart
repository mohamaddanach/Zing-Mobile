import 'package:flutter/material.dart';
import 'package:zing/purchase_dialog.dart';
import 'transaction_service.dart';
import 'seller_profile.dart';
class ShowProducts {
  static void showProductDetails({
    required BuildContext context,
    required Map<String, dynamic> data,
    required String productId,
    required String collection,

    // 🔥 inject from home.dart (clean architecture)
    required Widget Function(Map<String, dynamic>) imageWidget,
    required double Function(Map<String, dynamic>) calcPoints,
    required void Function(
        Map<String, dynamic> data,
        String productId,
        String collection,
        ) shareProduct,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.93,
          decoration: const BoxDecoration(
            color: Color(0xFF0F0F0F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [

              // HANDLE
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // IMAGE
                      SizedBox(
                        height: 320,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(25),
                            bottomRight: Radius.circular(25),
                          ),
                          child: imageWidget(data),
                        ),
                      ),

                      const SizedBox(height: 15),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // NAME
                            Text(
                              data['product_name'] ?? "No name",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // PRICE + POINTS
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [

                                Text(
                                  "\$${data['priceonplatform'] ?? 0}",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "${calcPoints(data).toStringAsFixed(1)} pts",
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // INFO BOX
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade900,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SellerProfile(
                                            sellerName: data['seller_name'] ?? "",
                                          ),
                                        ),
                                      );
                                    },
                                    child: _infoRow(
                                      Icons.store,
                                      "Seller",
                                      data['seller_name'] ?? "Unknown",
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  _infoRow(
                                    Icons.category,
                                    "Category",
                                    collection.replaceFirst("products_", ""),
                                  ),

                                  const SizedBox(height: 10),

                                  _infoRow(
                                    Icons.inventory_2,
                                    "Stock",
                                    "${data['current_quantity'] ?? data['stock'] ?? 0}",
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            const Text(
                              "Description",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade900,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                data['description'] ?? "No description available",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  height: 1.5,
                                ),
                              ),
                            ),

                            const SizedBox(height: 25),

                            // BUTTONS
                            Row(
                              children: [

                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);

                                      PurchaseDialog.show(
                                        context: context,
                                        data: data,
                                        onConfirm: (qty, paymentMethod) async {
                                          await TransactionService.processPurchase(
                                            productData: {
                                              ...data,
                                              "category": collection.replaceFirst("products_", "")
                                            },
                                            quantity: qty,
                                            source: "home",
                                            paymentMethod: paymentMethod,
                                            productId: productId,
                                          );
                                        },
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD32F2F),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text("BUY"),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      shareProduct(data, productId, collection);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1976D2),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text("SHARE"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔥 helper UI
  static Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 18),
        const SizedBox(width: 8),
        Text(
          "$title:",
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}