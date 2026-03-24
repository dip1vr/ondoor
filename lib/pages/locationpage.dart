import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ondoor/controllers/location_controller.dart';
import 'package:ondoor/theme/app_theme.dart';
import 'package:ondoor/widgets/genz_card.dart';
import 'package:ondoor/widgets/delivery_success_sheet.dart';
import 'package:ondoor/widgets/shimmer_helper.dart';
import 'map/map.dart';

class LocationScreen extends StatelessWidget {
  final String orderId;
  const LocationScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    // Inject Controller
    final controller = Get.put(LocationController(orderId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Obx(() {
        if (controller.isLoading.value) {
          return ShimmerHelper.buildLocationPageShimmer();
        }

        final order = controller.orderData.value;
        if (order == null) {
          return const Center(
            child: Text(
              "Order not found",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final customerName = order['customerName'] ?? 'N/A';
        final address = order['deliveryAddress'] ?? 'N/A';
        final restaurantName = order['vendorId'] ?? 'N/A';

        double parseDouble(dynamic val) {
          if (val == null) return 0.0;
          if (val is int) return val.toDouble();
          if (val is double) return val;
          return double.tryParse(val.toString()) ?? 0.0;
        }

        final distance = parseDouble(order['distance']);
        final orderAmount = parseDouble(order['totalAmount']);
        final orderStatus = (order['status'] ?? 'pending')
            .toString()
            .toLowerCase();

        final timeStr = order['createdAt'] is Timestamp
            ? DateFormat(
                'hh:mm a',
              ).format((order['createdAt'] as Timestamp).toDate())
            : 'N/A';

        final statusColor = AppTheme.getStatusColor(orderStatus);

        return SafeArea(
          child: Column(
            children: [
              // --- HEADER ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    GenZCard(
                      padding: const EdgeInsets.all(10),
                      color: AppTheme.cardDark,
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "Order Details",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        orderStatus.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- CUSTOMER CARD ---
                      GenZCard(
                        color: AppTheme.cardDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customerName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        restaurantName,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withOpacity(
                                      0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.phone,
                                    color: AppTheme.primaryBlue,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: AppTheme.accentAmber,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Divider(color: Colors.white.withOpacity(0.05)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildDetailItem(
                                  Icons.navigation,
                                  "$distance km",
                                ),
                                _buildDetailItem(Icons.access_time, timeStr),
                                Text(
                                  "₹${orderAmount.toStringAsFixed(1)}",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentAmber,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- PROGRESS STEPS ---
                      GenZCard(
                        color: AppTheme.cardDark,
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 12,
                        ),
                        child: _buildStepProgress(controller, orderStatus),
                      ),

                      const SizedBox(height: 24),

                      // --- DELIVERY TIMER & ACTION BUTTON ---
                      if (!controller.isDelivered) ...[
                        // TIMER BAR
                        if (controller.timeElapsed.value != "00:00")
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Delivery Time",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      controller.timeElapsed.value,
                                      style: const TextStyle(
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "monospace",
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    // Progress: Cap at 45 mins (2700 seconds) for visualization
                                    value:
                                        (controller
                                                    .elapsedDuration
                                                    .value
                                                    .inSeconds /
                                                2700)
                                            .clamp(0.0, 1.0),
                                    backgroundColor: Colors.grey[800],
                                    color: AppTheme.primaryBlue,
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: Obx(
                            () => ElevatedButton(
                              onPressed: controller.isUpdating.value
                                  ? null
                                  : () async {
                                      final nextStatus = controller
                                          .getNextStatus(orderStatus);
                                      await controller.updateStatus(nextStatus);
                                      if (nextStatus.toLowerCase() ==
                                          'delivered') {
                                        Get.bottomSheet(
                                          DeliverySuccessSheet(
                                            orderId: orderId,
                                          ),
                                          isScrollControlled: true,
                                          isDismissible: false,
                                          enableDrag: false,
                                          backgroundColor: Colors.transparent,
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: statusColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                shadowColor: statusColor.withOpacity(0.5),
                              ),
                              child: controller.isUpdating.value
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "MARK AS ${controller.getNextStatus(orderStatus).toUpperCase()}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        // --- CANCEL BUTTON ---
                        if (orderStatus != 'delivered' &&
                            orderStatus != 'cancelled')
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: controller.isUpdating.value
                                    ? null
                                    : () => _showCancelDialog(
                                        context,
                                        controller,
                                      ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: AppTheme.statusCancelled.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  "CANCEL ORDER",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.statusCancelled,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],

                      const SizedBox(height: 24),

                      const Text(
                        "Live Location",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // --- MAP PLACEHOLDER ---
                      Container(
                        height: 250,
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: GoogleMapPlacePicker(),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[300],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepProgress(
    LocationController controller,
    String currentStatus,
  ) {
    int currentIndex = controller.steps.indexOf(currentStatus.toLowerCase());
    if (currentIndex == -1) currentIndex = 0;

    return Row(
      children: List.generate(controller.steps.length, (index) {
        bool isCompleted = index <= currentIndex;
        bool isCurrent = index == currentIndex;
        final stepName = controller.steps[index];
        final shortLabel = stepName
            .toUpperCase()
            .replaceAll("PICKED UP", "PICKED\nUP")
            .replaceAll("ON THE WAY", "ON THE\nWAY");

        return Expanded(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.primaryBlue
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? AppTheme.primaryBlue
                        : Colors.grey[700]!,
                    width: 2,
                  ),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                shortLabel,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.w500,
                  color: isCompleted ? Colors.white : Colors.grey[600],
                  height: 1.1,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showCancelDialog(BuildContext context, LocationController controller) {
    final TextEditingController reasonController = TextEditingController();
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.statusCancelled.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AppTheme.statusCancelled,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Cancel Order",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                "Are you sure you want to cancel this order? This action cannot be undone.",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: reasonController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Reason for cancellation...",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: AppTheme.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text(
                        "Not Now",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (reasonController.text.trim().isEmpty) {
                          Get.snackbar(
                            "Required",
                            "Please enter a reason for cancellation",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red.withOpacity(0.1),
                            colorText: Colors.red,
                          );
                          return;
                        }
                        Get.back(); // Close dialog
                        controller.cancelOrder(reasonController.text.trim());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.statusCancelled,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        "Cancel Order",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
