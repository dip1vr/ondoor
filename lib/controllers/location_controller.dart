import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ondoor/theme/app_theme.dart';

class LocationController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String orderId;
  LocationController(this.orderId);

  Rx<Map<String, dynamic>?> orderData = Rx<Map<String, dynamic>?>(null);
  RxBool isLoading = true.obs;
  RxBool isUpdating = false.obs;

  // Timer
  RxString timeElapsed = "00:00".obs;
  Rx<Duration> elapsedDuration = Duration.zero.obs;
  Stream<int>? _timerStream;

  final List<String> steps = [
    "accepted",
    "pickup",
    "picked up",
    "on the way",
    "delivered",
  ];

  @override
  void onInit() {
    super.onInit();
    _bindOrderStream();
  }

  @override
  void onClose() {
    // Stream cancels automatically? Actually Stream.periodic needs cancelling if subscription kept.
    // using GetX workers usually safe but let's be clean.
    super.onClose();
  }

  void _bindOrderStream() {
    _firestore.collection('orders').doc(orderId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        data['id'] = snapshot.id;
        orderData.value = data;

        _checkAndStartTimer(data);
      } else {
        orderData.value = null;
      }
      isLoading.value = false;
    });
  }

  void _checkAndStartTimer(Map<String, dynamic> data) {
    if (data['status'] == 'pending') {
      timeElapsed.value = "00:00";
      elapsedDuration.value = Duration.zero;
      return;
    }

    // Determine start time (prioritize acceptedAt, fallback to createdAt)
    Timestamp? startTime = data['acceptedAt'] as Timestamp?;
    startTime ??= data['createdAt'] as Timestamp?;

    if (startTime != null) {
      final start = startTime.toDate();
      // If delivered, stop timer at deliveredAt
      if (data['status'] == 'delivered' && data['deliveredAt'] != null) {
        final end = (data['deliveredAt'] as Timestamp).toDate();
        final diff = end.difference(start);
        timeElapsed.value = _formatDuration(diff);
        elapsedDuration.value = diff;
      } else {
        // Live timer
        if (_timerStream == null) {
          _timerStream = Stream.periodic(const Duration(seconds: 1), (i) => i);
          _timerStream!.listen((_) {
            final now = DateTime.now();
            final diff = now.difference(start);
            timeElapsed.value = _formatDuration(diff);
            elapsedDuration.value = diff;
          });
        }
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  // Next status helper
  String getNextStatus(String currentStatus) {
    int index = steps.indexOf(currentStatus.toLowerCase());
    if (index == -1) return steps.first;
    if (index < steps.length - 1) return steps[index + 1];
    return "completed"; // or keep at delivered?
  }

  bool get isDelivered {
    return (orderData.value?['status'] ?? '').toLowerCase() == 'delivered';
  }

  Future<void> updateStatus(String newStatus) async {
    isUpdating.value = true;
    try {
      Map<String, dynamic> updateData = {
        'status': newStatus,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus.toLowerCase() == "delivered") {
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);

      Get.snackbar(
        "Success",
        "Order status updated to ${newStatus.toUpperCase()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
        colorText: AppTheme.primaryBlue,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update status",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> cancelOrder(String reason) async {
    isUpdating.value = true;
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledBy': 'delivery_boy',
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        "Order Cancelled",
        "The order has been cancelled successfully.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );

      // Navigate back to dashboard since order is cancelled
      Get.offAllNamed('/dashboard');
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to cancel order: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isUpdating.value = false;
    }
  }

  Color getStatusColor(String status) {
    return AppTheme.getStatusColor(status);
  }
}
