import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EarningsScreen extends StatelessWidget {
  EarningsScreen({super.key});

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  /// Fetch total earnings for this user
  Stream<Map<String, dynamic>> _getStats() {
    return _firestore.collection("deliveryBoys").doc(_uid).snapshots().map(
          (snapshot) {
        if (!snapshot.exists) {
          return {"earnings": 0.0};
        }
        return {
          "earnings": snapshot.data()?["earnings"]?.toDouble() ?? 0.0,
        };
      },
    );
  }

  /// Fetch earning history (completed or delivered orders)
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
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Earnings Card
            StreamBuilder<Map<String, dynamic>>(
              stream: _getStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var earnings = snapshot.data?["earnings"] ?? 0.0;
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
                            Icon(Icons.attach_money,
                                color: Colors.green, size: 28),
                            SizedBox(width: 6),
                            Text(
                              "Total Earnings",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "₹${earnings.toStringAsFixed(2)}",
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
              "Earnings History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Divider(color: Colors.grey),
            const SizedBox(height: 8),

            // Earnings History List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getEarningHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    // Log the error for debugging
                    debugPrint("Error fetching earnings history: ${snapshot.error}");
                    return const Center(
                      child: Text(
                        "Error loading earnings history.",
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
                            "lib/assets/earning_ass.png",
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "No earnings yet!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Complete deliveries to earn money.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
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
                          formattedDate = DateFormat("dd MMM yyyy, hh:mm a")
                              .format(order["deliveredAt"].toDate());
                        } else {
                          debugPrint("Invalid deliveredAt for order ${order["id"]}");
                        }
                      } catch (e) {
                        debugPrint("Error formatting deliveredAt for order ${order["id"]}: $e");
                      }

                      return _buildEarningTile(
                        order["restaurantName"] ?? "Unknown Restaurant",
                        order["status"]?.toString() ?? "N/A",
                        "₹${(order["total"]?.toDouble() ?? 0.0).toStringAsFixed(2)}",
                        formattedDate,
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

  // Reusable earning tile
  Widget _buildEarningTile(
      String restaurant, String status, String amount, String date) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blueAccent.shade100),
      ),
      elevation: 3,
      child: ListTile(
        leading: const Icon(Icons.restaurant, color: Colors.blue, size: 28),
        title: Text(
          restaurant,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("Status: $status\nDate: $date"),
        trailing: Text(
          amount,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}