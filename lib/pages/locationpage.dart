import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationScreen extends StatefulWidget {
  final String orderId; // Order ID to fetch from Firestore
  const LocationScreen({super.key, required this.orderId});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _isUpdating = false;

  // ✅ Use lowercase for consistency
  final List<String> _steps = [
    "accepted",
    "pickup",
    "picked up",
    "on the way",
    "delivered",
  ];
  int _currentStep = 0;

  /// 🔹 Update order status in Firestore
  /// 🔹 Update order status in Firestore with timestamp
  void _updateStatus(String orderId, String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      // Common update data
      Map<String, dynamic> updateData = {
        'status': newStatus,
        'statusUpdatedAt': FieldValue.serverTimestamp(), // ⏰ always update
      };

      // Agar order delivered ho gaya to alag se deliveredAt bhi store karo
      if (newStatus.toLowerCase() == "delivered") {
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update: ${e.toString()}")),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }


  /// 🔹 Build progress bar for order status
  Widget _buildOrderProgress(String status) {
    _currentStep = _steps.indexOf(status.toLowerCase());
    if (_currentStep == -1) _currentStep = 0; // Safety check

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_steps.length, (index) {
          bool isCompleted = index <= _currentStep;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      index < _currentStep ? Icons.check : Icons.circle,
                      color: isCompleted ? Colors.white : Colors.grey,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _steps[index].toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// 🔹 Get next status
  String _nextStatus(String currentStatus) {
    int index = _steps.indexOf(currentStatus.toLowerCase());
    if (index == -1) return _steps.first;
    if (index < _steps.length - 1) return _steps[index + 1];
    return _steps.last;
  }

  /// 🔹 Map status to color
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.grey;
      case "accepted":
        return Colors.orange.shade300;
      case "pickup":
        return Colors.orange;
      case "picked up":
        return Colors.blue;
      case "on the way":
        return Colors.green;
      case "delivered":
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  /// 🔹 Safe parsing for double values
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('orders').doc(widget.orderId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("Order not found")),
          );
        }

        final order = snapshot.data!.data() as Map<String, dynamic>;

        final customerName = order['customerName'] ?? 'N/A';
        final phoneNumber = order['phoneNumber'] ?? 'N/A';
        final address = order['address'] ?? 'N/A';
        final restaurantName = order['restaurantName'] ?? 'N/A';
        final distance = _parseDouble(order['distance']);
        final time = order['time'] ?? 'N/A';
        final orderAmount = _parseDouble(order['total']);
        final orderStatus = order['status'] ?? 'pending';

        final statusColor = _statusColor(orderStatus);

        return SafeArea(
          child: Scaffold(
            backgroundColor: Colors.grey[100],
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button and title
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const Text(
                        "Customer Location",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Customer Details Card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: statusColor, width: 1.5),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + Status Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                customerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  orderStatus.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            restaurantName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                phoneNumber,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  address,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
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
                                  Text(time),
                                ],
                              ),
                              Text(
                                "₹$orderAmount",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // 🔹 Order Progress Bar
                          _buildOrderProgress(orderStatus),
                          const SizedBox(height: 16),

                          // 🔹 Update Status Button
                          if (orderStatus.toLowerCase() != 'delivered')
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: statusColor,
                                ),
                                onPressed: _isUpdating
                                    ? null
                                    : () {
                                        String next = _nextStatus(orderStatus);
                                        _updateStatus(widget.orderId, next);
                                      },
                                child: _isUpdating
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Text(
                                        "Mark as ${_nextStatus(orderStatus).toUpperCase()}",
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.grey),
                  const Text(
                    "Location Map",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 8),

                  // Placeholder for Map
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.blue, width: 1.5),
                      ),
                      elevation: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "Map Placeholder\n(Live location will be shown here)",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
