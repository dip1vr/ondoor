import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ondoor/theme/app_theme.dart';
import 'package:ondoor/widgets/genz_card.dart';

class OrderRequestSheet extends StatefulWidget {
  final Map<String, dynamic> order;
  final String orderId;
  final String uid;
  final String deliveryBoyName;

  const OrderRequestSheet({
    super.key,
    required this.order,
    required this.orderId,
    required this.uid,
    required this.deliveryBoyName,
  });

  @override
  State<OrderRequestSheet> createState() => _OrderRequestSheetState();
}

class _OrderRequestSheetState extends State<OrderRequestSheet>
    with TickerProviderStateMixin {
  int _secondsRemaining = 60;
  Timer? _timer;
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _markAsMissed();
      }
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..forward();

    _progressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  Future<void> _markAsMissed() async {
    final doc = await _firestore.collection('orders').doc(widget.orderId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      if ((data['status'] ?? '').toLowerCase() == 'pending') {
        await _firestore.collection('orders').doc(widget.orderId).update({
          'missedBy': FieldValue.arrayUnion([widget.uid]),
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _acceptOrder() async {
    final orderDoc = _firestore.collection('orders').doc(widget.orderId);
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(orderDoc);
        if (!snapshot.exists) throw Exception("Order no longer exists");

        final data = snapshot.data()!;
        if (data['status'] != 'pending') {
          throw Exception("Order already taken");
        }

        transaction.update(orderDoc, {
          'status': 'accepted',
          'deliveryBoyId': widget.uid,
          'deliveryBoyName': widget.deliveryBoyName,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed: ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('orders').doc(widget.orderId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final orderData = snapshot.data!.data() as Map<String, dynamic>;
        final status = (orderData['status'] ?? '').toString().toLowerCase();
        final acceptedBy = orderData['deliveryBoyId'];

        final isMissed =
            (status != 'pending' && acceptedBy != widget.uid) ||
            (_secondsRemaining == 0 && status == 'pending');

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isMissed ? "ORDER CLOSED" : "NEW ORDER REQUEST",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isMissed
                          ? AppTheme.statusCancelled
                          : AppTheme.primaryBlue,
                    ),
                  ),
                  if (!isMissed)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return CircularProgressIndicator(
                                value: _progressAnimation.value,
                                strokeWidth: 3,
                                color: _progressAnimation.value < 0.3
                                    ? AppTheme.statusCancelled
                                    : AppTheme.primaryBlue,
                                backgroundColor: Colors.white.withOpacity(0.1),
                              );
                            },
                          ),
                        ),
                        Text(
                          "$_secondsRemaining",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Details
              GenZCard(
                color: AppTheme.backgroundDark,
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.store,
                      orderData['vendorName'] ?? 'Unknown Vendor',
                      AppTheme.primaryBlue,
                    ),
                    Divider(color: Colors.white.withOpacity(0.05)),
                    _buildDetailRow(
                      Icons.person,
                      orderData['customerName'] ?? 'Unknown Customer',
                      AppTheme.accentAmber,
                    ),
                    Divider(color: Colors.white.withOpacity(0.05)),
                    _buildDetailRow(
                      Icons.location_on,
                      orderData['deliveryAddress'] ?? 'No Address',
                      AppTheme.statusOnTheWay,
                    ),
                    Divider(color: Colors.white.withOpacity(0.05)),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total Earnings",
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            "₹${(double.tryParse((orderData['totalAmount'] ?? 0).toString()) ?? 0.0).toStringAsFixed(1)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Slider Button
              if (!isMissed)
                SlideToAcceptButton(onAccept: _acceptOrder)
              else
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class SlideToAcceptButton extends StatefulWidget {
  final VoidCallback onAccept;
  const SlideToAcceptButton({required this.onAccept, super.key});

  @override
  State<SlideToAcceptButton> createState() => _SlideToAcceptButtonState();
}

class _SlideToAcceptButtonState extends State<SlideToAcceptButton> {
  double _sliderValue = 0.0;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double thumbSize = 56.0;
        final double padding = 4.0;
        final double trackWidth = maxWidth - thumbSize - (padding * 2);

        return GestureDetector(
          // Important: Use onPanUpdate instead of onHorizontalDragUpdate to prevent
          // the parent BottomSheet from stealing the gesture if the user drags
          // slightly diagonally.
          onPanStart: (details) {
            // Optional: You could use this to verify the start position if needed
          },
          onPanUpdate: (details) {
            if (_submitted) return;
            // Calculate new value based on horizontal movement
            // details.delta.dx is the amount moved in x direction
            double newValue = _sliderValue + (details.delta.dx / trackWidth);
            setState(() {
              _sliderValue = newValue.clamp(0.0, 1.0);
            });
          },
          onPanEnd: (details) {
            if (_submitted) return;
            if (_sliderValue > 0.85) {
              setState(() {
                _sliderValue = 1.0;
                _submitted = true;
              });
              widget.onAccept();
            } else {
              setState(() => _sliderValue = 0.0);
            }
          },
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
            ),
            child: Stack(
              children: [
                // Text Label
                Center(
                  child: Opacity(
                    opacity: (1.0 - _sliderValue).clamp(0.0, 1.0),
                    child: const Text(
                      "SLIDE TO ACCEPT",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 2.0,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),

                // Fill Background
                Container(
                  width:
                      (thumbSize + (padding * 2)) + (trackWidth * _sliderValue),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),

                // Thumb
                Align(
                  alignment: Alignment((_sliderValue * 2) - 1.0, 0.0),
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    margin: EdgeInsets.all(padding),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: _submitted
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
