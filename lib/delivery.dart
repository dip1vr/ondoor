import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pages/earningpage.dart';
import 'pages/locationpage.dart';
import 'pages/orderpage.dart';
import 'pages/profilepage.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isOnline = false;

  late final List<Widget> _widgetOptions;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot>? _orderSubscription;

  String get _uid => _auth.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      _buildHomeTab(),
      EarningsScreen(),
      OrdersHistoryScreen(),
      ProfileScreen(),
    ];

    // 🔹 Firestore se online status load karlo (refresh ke baad bhi same rahe)
    _firestore.collection("deliveryBoys").doc(_uid).get().then((doc) {
      if (doc.exists && doc["isOnline"] == true) {
        setState(() => _isOnline = true);
        _subscribeToOrders();
      }
    });
  }

  /// 🔹 Online/Offline toggle
  Future<void> _toggleOnline() async {
    final newStatus = !_isOnline;
    setState(() => _isOnline = newStatus);

    await _firestore.collection("deliveryBoys").doc(_uid).set({
      "isOnline": newStatus,
      "lastUpdated": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (newStatus) {
      _subscribeToOrders();
    } else {
      _unsubscribeFromOrders();
    }
  }

  /// 🔹 Listen for new pending orders
  void _subscribeToOrders() {
    _orderSubscription = _firestore
        .collection('orders')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var order = change.doc.data()!;
          _showOrderDialog(change.doc.id, order);
        }
      }
    });
  }

  void _unsubscribeFromOrders() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
  }

  /// 🔹 Stats Stream
  Stream<Map<String, dynamic>> _getStats() {
    return _firestore
        .collection("orders")
        .where("deliveryBoyId", isEqualTo: _uid)
        .snapshots()
        .map((snapshot) {
      int active = 0;
      int completed = 0;
      int earnings = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();
        final total = data['total'] ?? 0;

        if (status == 'completed' || status == 'delivered') {
          completed += 1;
          earnings += (total as num).toInt();
        } else if (status == 'accepted' || status == 'pickup' || status == 'picked up' || status == 'on the way') {
          active += 1;
        }
      }
      _firestore.collection("deliveryBoys").doc(_uid).set({
        "earnings": earnings,
        "activeOrders": active,
        "completedOrders": completed,
        "lastUpdated": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return {
        "earnings": earnings,
        "active": active,
        "completed": completed,
      };
    });
  }

  /// 🔹 Active Orders Stream
  Stream<List<Map<String, dynamic>>> _getActiveOrders() {
    return _firestore
        .collection("orders")
        .where("deliveryBoyId", isEqualTo: _uid)
        .where("status", whereIn: ["accepted", "pickup", "picked up", "on the way"])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// 🔹 New order dialog
  void _showOrderDialog(String orderId, Map<String, dynamic> order) {
    if (!_isOnline) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderBottomSheet(
        order: order,
        orderId: orderId,
        uid: _uid,
        firestore: _firestore,
      ),
    );
  }

  /// 🔹 Home Tab
  Widget _buildHomeTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Online/Offline Toggle Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.purple, width: 1.5),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isOnline ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isOnline ? "Online" : "Offline",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _toggleOnline,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isOnline ? Colors.red : Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _isOnline ? "Go Offline" : "Go Online",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Stats Row
          StreamBuilder<Map<String, dynamic>>(
            stream: _getStats(),
            builder: (context, snapshot) {
              var stats = snapshot.data ?? {
                "earnings": 0,
                "active": 0,
                "completed": 0,
              };
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.attach_money,
                      color: Colors.green,
                      title: "Earnings",
                      value: "₹${stats["earnings"]}",
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.access_time,
                      color: Colors.orange,
                      title: "Active",
                      value: "${stats["active"]}",
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle,
                      color: Colors.blue,
                      title: "Completed",
                      value: "${stats["completed"]}",
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 8),
          const Divider(color: Colors.grey),
          const Text("Active Orders", style: TextStyle(fontSize: 18)),
          const Divider(color: Colors.grey),
          const SizedBox(height: 8),

          // Scrollable Active Orders
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getActiveOrders(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset("lib/assets/noorder_ass.png", fit: BoxFit.cover),
                          const SizedBox(height: 20),
                          const Text(
                            "No active orders yet!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Relax! You will get orders soon.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                var orders = snapshot.data!;
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    var order = orders[index];
                    return _buildOrderCard(order);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 1.5),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    // Determine color based on status
    Color statusColor;
    switch ((order["status"] ?? "").toLowerCase()) {
      case "accepted":
        statusColor = Colors.orange.shade400;
        break;
      case "pickup":
        statusColor = Colors.yellow.shade700;
        break;
      case "picked up":
        statusColor = Colors.lightBlue.shade300;
        break;
      case "on the way":
        statusColor = Colors.green.shade400;
        break;
      default:
        statusColor = Colors.grey; // fallback
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor, width: 1.5),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LocationScreen(orderId: order['id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order["customerName"] ?? "Unknown",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order["status"] ?? "N/A",
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
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
                  Text(
                    order["address"] ?? "",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                      Text("${order["distance"] ?? 0} km"),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 4),
                      Text(order["time"] ?? "N/A"),
                    ],
                  ),
                  Text(
                    "Total: ₹${order['total'] ?? 0}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  void dispose() {
    _unsubscribeFromOrders();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.grey[100],
          body: _selectedIndex == 0
              ? _buildHomeTab()
              : _widgetOptions[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.attach_money), label: 'Earnings'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.delivery_dining), label: 'Orders'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Profile'),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}

class _OrderBottomSheet extends StatefulWidget {
  final Map<String, dynamic> order;
  final String orderId;
  final String uid;
  final FirebaseFirestore firestore;

  const _OrderBottomSheet({
    required this.order,
    required this.orderId,
    required this.uid,
    required this.firestore,
  });

  @override
  _OrderBottomSheetState createState() => _OrderBottomSheetState();
}

class _OrderBottomSheetState extends State<_OrderBottomSheet> with TickerProviderStateMixin {
  double _sliderValue = 0;
  int _secondsRemaining = 60; // ⏱️ 1 minute
  Timer? _timer;
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late AnimationController _sliderAnimationController;
  late Animation<double> _sliderAnimation;

  @override
  void initState() {
    super.initState();

    // Start 60-second timer
   _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
  if (_secondsRemaining > 0) {
    setState(() => _secondsRemaining--);
  } else {
    timer.cancel();

    // 🔹 Agar order abhi bhi pending hai -> Firestore me expire kar do
    final doc = await widget.firestore.collection('orders').doc(widget.orderId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      if ((data['status'] ?? '').toLowerCase() == 'pending') {
        await widget.firestore.collection('orders').doc(widget.orderId).update({
          'status': 'expired',
          'expiredAt': FieldValue.serverTimestamp(), // optional
        });
      }
    }
  }
});


    // Initialize progress animation (countdown circle)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..forward();
    _progressAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    // Initialize slider animation controller
    _sliderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _sliderAnimationController.addListener(() {
      setState(() {
        _sliderValue = _sliderAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _sliderAnimationController.dispose();
    super.dispose();
  }

  void _snapSlider(double value) {
    if (value > 0.6) {
      // Animate slider to 1.0 if past 60%
      _sliderAnimation = Tween<double>(begin: value, end: 1.0).animate(
        CurvedAnimation(parent: _sliderAnimationController, curve: Curves.easeOut),
      );
      _sliderAnimationController.forward(from: 0).then((_) async {
        final orderDoc = widget.firestore.collection('orders').doc(widget.orderId);
        await widget.firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(orderDoc);
          if (!snapshot.exists) throw Exception("Order no longer exists");

          final data = snapshot.data()!;
          if (data['status'] != 'pending') {
            throw Exception("Order already taken");
          }

          transaction.update(orderDoc, {
            'status': 'accepted',
            'deliveryBoyId': widget.uid,
          });
        }).then((_) {
          Navigator.pop(context);
        }).catchError((e) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed: ${e.toString()}")),
          );
        });
        _sliderAnimationController.reset();
        setState(() {
          _sliderValue = 0; // Reset slider value
        });
      });
    } else {
      // Animate slider back to 0.0 if below threshold
      _sliderAnimation = Tween<double>(begin: value, end: 0.0).animate(
        CurvedAnimation(parent: _sliderAnimationController, curve: Curves.easeOut),
      );
      _sliderAnimationController.forward(from: 0).then((_) {
        _sliderAnimationController.reset();
        setState(() {
          _sliderValue = 0;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: widget.firestore.collection('orders').doc(widget.orderId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final orderData = snapshot.data!.data() as Map<String, dynamic>;
        final status = (orderData['status'] ?? '').toString().toLowerCase();
        final acceptedBy = orderData['deliveryBoyId'];

        // Order is missed if it's not pending and not assigned to this delivery boy
        // OR if the timer has reached zero while still pending
        final isMissed = (status != 'pending' && acceptedBy != widget.uid) ||
                         (_secondsRemaining == 0 && status == 'pending');

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grabber Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Timer and Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isMissed ? "Order Closed" : "New Order",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            // Show countdown timer if order is still open
                            if (!isMissed)
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: AnimatedBuilder(
                                      animation: _progressAnimation,
                                      builder: (context, child) => CircularProgressIndicator(
                                        value: _progressAnimation.value,
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.orange.shade600),
                                        backgroundColor: Colors.grey.shade200,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "$_secondsRemaining",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.grey.shade600, size: 28),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Order Details
                    _buildDetailRow(
                      icon: Icons.person,
                      label: "Customer",
                      value: orderData['customerName'] ?? 'N/A',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.location_on,
                      label: "Address",
                      value: orderData['address'] ?? 'N/A',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.currency_rupee,
                      label: "Total",
                      value: "₹${orderData['total'] ?? 0}",
                    ),
                    const SizedBox(height: 24),
                    // Display "missed" UI or the accept slider
                    if (isMissed)
                      Center(
                        child: Text(
                          "❌ You missed this order",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          _buildSliderAccept(),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              "Slide to Accept",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🔹 Accept Slider Widget
  Widget _buildSliderAccept() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade100, Colors.green.shade200],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 56,
          thumbColor: Colors.green.shade600,
          activeTrackColor: Colors.green.shade400,
          inactiveTrackColor: Colors.transparent,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 22),
        ),
        child: Slider(
          value: _sliderValue,
          min: 0,
          max: 1,
          onChanged: (value) => setState(() => _sliderValue = value),
          onChangeEnd: _snapSlider,
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueGrey.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}