import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Added for date formatting

class OrdersHistoryScreen extends StatelessWidget {
  OrdersHistoryScreen({super.key});

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  /// 🔹 Fetch all orders for this delivery boy
  Stream<List<Map<String, dynamic>>> _getOrderHistory() {
    return _firestore
        .collection("orders")
        .where("deliveryBoyId", isEqualTo: _uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data["id"] = doc.id;
              return data;
            }).toList());
  }

  /// 🔹 Fetch stats (completed orders only)
  Stream<Map<String, dynamic>> _getStats() {
    return _firestore.collection("deliveryBoys").doc(_uid).snapshots().map(
      (snapshot) {
        if (!snapshot.exists) {
          return {
            "completedOrders": 0,
          };
        }
        final data = snapshot.data()!;
        return {
          "completedOrders": data["completedOrders"] ?? 0,
        };
      },
    );
  }

  /// 🔹 Get badge color based on order status
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "delivered":
        return Colors.green.shade400;
      case "cancelled":
        return Colors.red.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  /// 🔹 Safely parse numbers
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Completed Orders Card
            StreamBuilder<Map<String, dynamic>>(
              stream: _getStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stats = snapshot.data ?? {
                  "completedOrders": 0,
                };

                final completedOrders = stats["completedOrders"];
                final totalOrders = completedOrders; // ✅ सिर्फ completed count

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.green, width: 1.5),
                  ),
                  elevation: 4,
                  shadowColor: Colors.grey.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 28),
                            SizedBox(width: 6),
                            Text(
                              "Completed Orders",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "$totalOrders",
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),
            const Divider(color: Colors.grey),
            const Text(
              "Delivery History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Divider(color: Colors.grey),
            const SizedBox(height: 8),

            /// 🔹 Orders List (only delivered)
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getOrderHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    // Log the error for debugging
                    debugPrint("Error fetching order history: ${snapshot.error}");
                    return const Center(
                      child: Text(
                        "Error loading order history.",
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "lib/assets/order.png",
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "No completed orders yet!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Delivered orders will appear here.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // ✅ सिर्फ delivered वाले orders filter करो
                  var completedOrders = snapshot.data!
                      .where((o) => o["status"]?.toLowerCase() == "delivered")
                      .toList();

                  if (completedOrders.isEmpty) {
                    return const Center(
                      child: Text(
                        "No completed orders yet!",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: completedOrders.length,
                    itemBuilder: (context, index) {
                      var order = completedOrders[index];
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

  /// 🔹 Single order card
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = (order["status"] ?? "N/A").toString();
    final statusColor = _statusColor(status);
    final distance = _parseDouble(order["distance"]);
    final amount = _parseDouble(order["total"]);

    // Format timestamp similar to EarningsScreen
    String formattedDate = "N/A";
    try {
      if (order["deliveredAt"] is Timestamp) {
        formattedDate = DateFormat("dd MMM yyyy, hh:mm a")
            .format(order["deliveredAt"].toDate());
      } else {
        debugPrint("Invalid deliveredAt for order ${order["id"]}");
      }
    } catch (e) {
      debugPrint("Error formatting deliveredAt for order ${order["id"]}: $e");
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor, width: 1.2),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order["customerName"] ?? "Unknown",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 4, horizontal: 12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              order["restaurantName"] ?? "",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order["address"] ?? "",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.navigation, size: 16),
                    const SizedBox(width: 4),
                    Text("$distance km"),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 4),
                    Text(formattedDate), // Use formatted date instead of order["time"]
                  ],
                ),
                Text(
                  "₹$amount",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}