import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ondoor/controllers/dashboard_controller.dart';
import 'package:ondoor/theme/app_theme.dart';
import 'package:ondoor/widgets/genz_card.dart';
import 'package:ondoor/widgets/shimmer_helper.dart';
import 'package:ondoor/pages/earningpage.dart';
import 'package:ondoor/pages/locationpage.dart';
import 'package:ondoor/pages/orderpage.dart';
import 'package:ondoor/pages/profilepage.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundDark,
              Color(0xFF1E293B), // Slate 800
            ],
          ),
        ),
        child: Stack(
          children: [
            Obx(
              () => IndexedStack(
                index: controller.selectedIndex.value,
                children: [
                  _buildHomeTab(context, controller),
                  EarningsScreen(),
                  OrdersHistoryScreen(),
                  ProfileScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildGlassBottomNav(context, controller),
    );
  }

  Widget _buildHomeTab(BuildContext context, DashboardController controller) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome Back,",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "Delivery Partner",
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryBlue, width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage('lib/assets/cat.png'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Online Toggle
            Obx(() {
              final isOnline = controller.isOnline.value;
              return GenZCard(
                onTap: controller.toggleOnline,
                color: isOnline
                    ? AppTheme.statusOnTheWay.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? AppTheme.statusOnTheWay
                                : Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isOnline
                                            ? AppTheme.statusOnTheWay
                                            : Colors.red)
                                        .withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isOnline
                                ? Icons.power_settings_new
                                : Icons.power_off,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOnline ? "You are Online" : "You are Offline",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              isOnline
                                  ? "Ready for orders..."
                                  : "Go online to receive jobs",
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: isOnline,
                      onChanged: (_) => controller.toggleOnline(),
                      activeColor: AppTheme.statusOnTheWay,
                      activeTrackColor: AppTheme.statusOnTheWay.withOpacity(
                        0.3,
                      ),
                      inactiveThumbColor: Colors.red,
                      inactiveTrackColor: Colors.red.withOpacity(0.3),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Stats
            StreamBuilder<Map<String, dynamic>>(
              stream: controller.statsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Row(
                    children: [
                      ShimmerHelper.buildStatsCardShimmer(),
                      const SizedBox(width: 12),
                      ShimmerHelper.buildStatsCardShimmer(),
                      const SizedBox(width: 12),
                      ShimmerHelper.buildStatsCardShimmer(),
                    ],
                  );
                }
                final data = snapshot.data ?? {};
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        "Earnings",
                        "₹${(double.tryParse((data['earnings'] ?? 0).toString()) ?? 0.0).toStringAsFixed(1)}",
                        Icons.attach_money,
                        AppTheme.statusOnTheWay,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        "Active",
                        "${data['active'] ?? 0}",
                        Icons.electric_moped,
                        AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        "Done",
                        "${data['completed'] ?? 0}",
                        Icons.check_circle_outline,
                        AppTheme.accentAmber,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Active Orders",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Active Orders List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: controller.activeOrdersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ShimmerHelper.buildListShimmer(
                      itemCount: 3,
                      itemBuilder: (index) =>
                          ShimmerHelper.buildActiveOrderCardShimmer(),
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
                            color: Colors.grey.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No active orders",
                            style: TextStyle(
                              color: Colors.grey.withOpacity(0.5),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final order = snapshot.data![index];
                      return _buildActiveOrderCard(order);
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

  Widget _buildActiveOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? "Pending";
    final statusColor = AppTheme.getStatusColor(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GenZCard(
        onTap: () => Get.to(() => LocationScreen(orderId: order['id'])),
        // Tint the entire card background based on status
        color: statusColor.withOpacity(0.15),
        child: Container(
          decoration: BoxDecoration(
            // Optional: Add a left border for extra indication
            border: Border(left: BorderSide(color: statusColor, width: 4)),
          ),
          padding: const EdgeInsets.only(
            left: 12,
          ), // Indent content slightly due to left border
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order['customerName'] ?? "Unknown",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: Colors.grey[400]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order['deliveryAddress'] ?? "No address",
                      style: TextStyle(color: Colors.grey[300], fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Amount",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "₹${(double.tryParse((order['totalAmount'] ?? 0).toString()) ?? 0.0).toStringAsFixed(1)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white,
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

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return GenZCard(
      padding: const EdgeInsets.all(16),
      color: AppTheme.cardDark,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildGlassBottomNav(
    BuildContext context,
    DashboardController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.8), // Slate 800
              borderRadius: BorderRadius.circular(30),
            ),
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(context, Icons.home_rounded, 0, controller),
                  _buildNavItem(
                    context,
                    Icons.account_balance_wallet_rounded,
                    1,
                    controller,
                  ),
                  _buildNavItem(context, Icons.history_rounded, 2, controller),
                  _buildNavItem(context, Icons.person_rounded, 3, controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    int index,
    DashboardController controller,
  ) {
    final isSelected = controller.selectedIndex.value == index;
    return GestureDetector(
      onTap: () => controller.changeTabIndex(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.2)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? AppTheme.primaryBlue : Colors.grey,
          size: 26,
        ),
      ),
    );
  }
}
