import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionService {

  static double clean(double value) =>
      double.parse(value.toStringAsFixed(2));
  static Future<void> _sendCommissionEarnedNotification({
    required String senderUid,
    required String receiverName,
    required double commission,
    required String productName,
  }) async {

    await FirebaseFirestore.instance.collection("notifications").add({
      "title": "Commission earned 💰",
      "body":
      "$receiverName bought $productName. You earned \$${commission.toStringAsFixed(2)}",

      "type": "commission",
      "is_read": false,

      "receiver_id": senderUid,

      "sender_name": receiverName,
      "sender_uid": FirebaseAuth.instance.currentUser?.uid ?? "",

      "target_id": "",
      "collection": "",

      "timestamp": FieldValue.serverTimestamp(),
    });
  }
  static Future<void> processPurchase({
    required Map<String, dynamic> productData,
    required int quantity,
    required String source,
    required String paymentMethod,
    required String productId,
    String? receiverName,
  }) async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    final firestore = FirebaseFirestore.instance;

    // 🔢 Transaction ID
    final counterRef = firestore.collection("counters").doc("transactions");

    final newId = await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      int current = 1000;

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        current = (data["last_id"] ?? 1000);
      }

      final next = current + 1;

      transaction.set(counterRef, {"last_id": next}, SetOptions(merge: true));

      return next;
    });

    // 👤 USER DATA
    final userDoc =
    await firestore.collection("users").doc(user.uid).get();

    final userData = userDoc.data() ?? {};

    String phone = userData['phone_number'] ?? user.phoneNumber ?? "";
    String username = userData['username'] ?? "Unknown";

    double price = (productData['priceonplatform'] ?? 0).toDouble();

    double totalPrice = clean(price * quantity);
    double profit = clean((productData['profit_one_item'] ?? 0).toDouble() * quantity);
    double bonus = clean((productData['bonus_reserve'] ?? 0).toDouble() * quantity);

    double sellerIncome = clean(totalPrice - bonus - profit);

    double commission = clean(profit / 2);
    double appNetProfit = clean(profit / 2);

    final transactionRef =
    firestore.collection("transactions").doc(newId.toString());

    final financeRef =
    firestore.collection("transaction_finance").doc(newId.toString());

    final commissionRef =
    firestore.collection("transaction_commission").doc(newId.toString());

    // 🛒 PRODUCT STOCK UPDATE
    final String category =
    (productData['category'] ?? "").toString().trim();

    final userRef = firestore.collection("users").doc(user.uid);
    if (category.isEmpty) {
      throw Exception("Category missing in productData");
    }
    if (category.isNotEmpty && productId.isNotEmpty) {

      final productRef = firestore
          .collection("products_$category")
          .doc(productId);

      await firestore.runTransaction((tx) async {

        final snap = await tx.get(productRef);

        if (!snap.exists) {
          throw Exception("Product not found");
        }

        final data = snap.data() as Map<String, dynamic>;

        final int currentQty =
        (data['current_quantity'] ?? 0) as int;
        final int orderQty = quantity;
        print("🟡 ORDER QTY: $orderQty");
        print("🟢 CURRENT QTY: $currentQty");
        // ❌ NOT ENOUGH STOCK
        if (currentQty < quantity) {
          print("🔴 ERROR: Not enough stock!");
          throw Exception("Not enough stock available");
        }

        // ✅ CALCULATE NEW STOCK
        final int updatedQty = currentQty - quantity;

        // ✅ UPDATE FIRESTORE
        tx.update(productRef, {
          "current_quantity": updatedQty,
        });
      });
    }
    // 👇 ALL WRITES TOGETHER
    await Future.wait([

      transactionRef.set({
        "transaction_id": newId,
        "user_id": user.uid,
        "username": username,
        "phone_number": phone,
        "country": userData['country'] ?? "",
        "seller_name": productData['seller_name'] ?? "",
        "product_name": productData['product_name'] ?? "",
        "quantity": quantity,
        "total_price": totalPrice,
        "category": category,
        "source": source,
        "payement_method": paymentMethod,
        "status": "pending",
        "timestamp": FieldValue.serverTimestamp(),
      }),

      financeRef.set({
        "transaction_id": newId,
        "product_name": productData['product_name'] ?? "",
        "quantity": quantity,
        "total_price": totalPrice,
        "seller_income": sellerIncome,
        "profit": profit,
        "bonus_reserve": bonus,
        "timestamp": FieldValue.serverTimestamp(),
      }),
    ]);

    // 💸 COMMISSION ONLY IF SOURCE = commission
    if (source == "commission") {

      final usersRef = firestore.collection("users");

      final query = await usersRef
          .where("username", isEqualTo: receiverName)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {

        final brokerDoc = query.docs.first;
        final brokerRef = brokerDoc.reference;

        final brokerUid = brokerDoc.id;

        // 💰 UPDATE BROKER POINTS
        await firestore.runTransaction((tx) async {
          final snap = await tx.get(brokerRef);

          final currentPoints =
          ((snap.data()?["number_of_points"] ?? 0) as num).toDouble();

          final updatedPoints = currentPoints + commission;

          tx.update(brokerRef, {
            "number_of_points": clean(updatedPoints),
          });
        });

        // 🔥 NOTIFY BROKER (SEND BONUS INFO)
        await _sendCommissionEarnedNotification(
          senderUid: brokerUid,
          receiverName: username,
          commission: commission,
          productName: productData['product_name'] ?? "product",
        );
      }

      await commissionRef.set({
        "transaction_id": newId,
        "sender_name": receiverName ?? "Unknown",
        "receiver_name": username,
        "sender_commission": commission,
        "app_net_profit": appNetProfit,
        "source": source,
        "timestamp": FieldValue.serverTimestamp(),
      });
    }

    // 👤 UPDATE USER POINTS (ONLY ONCE, FIXED)
    final usersRef = firestore.collection("users");

    final query = await usersRef
        .where("phone_number", isEqualTo: phone)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final userRef = query.docs.first.reference;

      await firestore.runTransaction((tx) async {
        final snap = await tx.get(userRef);

        final currentPoints =
        ((snap.data()?["number_of_points"] ?? 0) as num).toDouble();

        tx.update(userRef, {
          "number_of_points": clean(currentPoints + bonus),
        });
      });
    }
  }
}