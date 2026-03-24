import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ondoor/theme/app_theme.dart';
import 'package:ondoor/widgets/genz_card.dart';
import 'package:ondoor/widgets/shimmer_helper.dart';

class EarningsScreen extends StatelessWidget {
  EarningsScreen({super.key});

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  Stream<Map<String, dynamic>> _getStats() {
    return _firestore.collection("deliveryBoys").doc(_uid).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return {"earnings": 0.0};
      return {"earnings": snapshot.data()?["earnings"]?.toDouble() ?? 0.0};
    });
  }

  Stream<List<Map<String, dynamic>>> _getEarningHistory() {
    return _firestore
        .collection("orders")
        .where("deliveryBoyId", isEqualTo: _uid)
        .where("status", whereIn: ["completed", "delivered"])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data["id"] = doc.id;
            return data;
          }).toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Handled by Dashboard's gradient
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SafeArea(bottom: false, child: SizedBox(height: 10)),
            // Total Earnings Card
            StreamBuilder<Map<String, dynamic>>(
              stream: _getStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ShimmerHelper.buildBasicShimmer(
                    width: double.infinity,
                    height: 180,
                    radius: 20,
                  );
                }
                var earnings = snapshot.data?["earnings"] ?? 0.0;
                return GenZCard(
                  color: AppTheme.cardDark,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.attach_money,
                              color: AppTheme.statusOnTheWay,
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "TOTAL EARNINGS",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "₹${earnings.toStringAsFixed(1)}",
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),
            Text(
              "Earnings History",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Earnings History List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getEarningHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ShimmerHelper.buildListShimmer(
                      itemCount: 4,
                      itemBuilder: (index) =>
                          ShimmerHelper.buildEarningsHistoryShimmer(),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 60,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "No earnings yet",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  var earnings = snapshot.data!;
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: earnings.length,
                    itemBuilder: (context, index) {
                      var order = earnings[index];
                      String formattedDate = "N/A";
                      try {
                        if (order["deliveredAt"] is Timestamp) {
                          formattedDate = DateFormat(
                            "dd MMM, hh:mm a",
                          ).format(order["deliveredAt"].toDate());
                        }
                      } catch (_) {}

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GenZCard(
                          color: AppTheme.cardDark,
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.statusOnTheWay.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: AppTheme.statusOnTheWay,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              order["vendorId"] ?? "Unknown Vendor",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              "$formattedDate",
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            trailing: Text(
                              "+ ₹${(order["totalAmount"]?.toDouble() ?? 0.0).toStringAsFixed(1)}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.statusOnTheWay,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
