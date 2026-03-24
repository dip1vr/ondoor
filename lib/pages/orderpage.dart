import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ondoor/theme/app_theme.dart';
import 'package:ondoor/widgets/genz_card.dart';
import 'package:ondoor/widgets/shimmer_helper.dart';

class OrdersHistoryScreen extends StatelessWidget {
  OrdersHistoryScreen({super.key});

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  Stream<List<Map<String, dynamic>>> _getOrderHistory() {
    return _firestore
        .collection("orders")
        .where("deliveryBoyId", isEqualTo: _uid)
        .where(
          "status",
          whereIn: ["delivered", "cancelled"],
        ) // Show delivered and cancelled
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data["id"] = doc.id;
            return data;
          }).toList(),
        );
  }

  Stream<Map<String, dynamic>> _getStats() {
    return _firestore.collection("deliveryBoys").doc(_uid).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return {"completedOrders": 0};
      final data = snapshot.data()!;
      return {"completedOrders": data["completedOrders"] ?? 0};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SafeArea(bottom: false, child: SizedBox(height: 10)),
            // Completed Orders Card
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
                final stats = snapshot.data ?? {"completedOrders": 0};
                final completedOrders = stats["completedOrders"];

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
                              Icons.check_circle_outline,
                              color: AppTheme.primaryBlue,
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "COMPLETED ORDERS",
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
                          "$completedOrders",
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
              "Delivery History",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Orders List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getOrderHistory(),
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
                            Icons.inbox_outlined,
                            size: 60,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "No orders found",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  var historyOrders = snapshot.data!;
                  // Show most recent first
                  historyOrders.sort((a, b) {
                    Timestamp? t1 = a["deliveredAt"];
                    Timestamp? t2 = b["deliveredAt"];
                    if (t1 == null || t2 == null) return 0;
                    return t2.compareTo(t1);
                  });

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: historyOrders.length,
                    itemBuilder: (context, index) {
                      var order = historyOrders[index];
                      return _buildOrderCard(order);
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

  Widget _buildOrderCard(Map<String, dynamic> order) {
    String formattedDate = "N/A";
    try {
      if (order["deliveredAt"] is Timestamp) {
        formattedDate = DateFormat(
          "dd MMM, hh:mm a",
        ).format(order["deliveredAt"].toDate());
      }
    } catch (_) {}

    String status = (order['status'] ?? 'unknown').toString();
    Color statusColor = AppTheme.getStatusColor(status);

    return GenZCard(
      color: AppTheme.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order["customerName"] ?? "Unknown",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order["deliveryAddress"] ?? "",
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.white.withOpacity(0.05)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "₹${(double.tryParse((order['totalAmount'] ?? 0).toString()) ?? 0.0).toStringAsFixed(1)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
