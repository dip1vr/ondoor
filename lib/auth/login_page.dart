import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hungry/pages/dashbord.dart'; // Assuming this is your dashboard page

class BottomNavController extends GetxController {
  var selectedIndex = 0.obs;
  var cartItemCount = 0.obs; // Dynamic cart item count for badge

  void changeIndex(int index) {
    selectedIndex.value = index;
  }

  void updateCartCount(int count) {
    cartItemCount.value = count;
  }
}

class BottomNavPage extends StatelessWidget {
  BottomNavPage({super.key});

  final BottomNavController controller = Get.put(BottomNavController());

  final List<Widget> pages = [
    const Dash(), // Menu/Home
    const Center(child: Text("Orders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
    const Center(child: Text("Cart", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
    const Center(child: Text("Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200), // Subtle fade transition
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: IndexedStack(
            key: ValueKey<int>(controller.selectedIndex.value),
            index: controller.selectedIndex.value,
            children: pages,
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8E1), // Warm, creamy background for food app vibe
              border: Border(
                top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5), // Thinner divider
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: controller.selectedIndex.value,
              onTap: controller.changeIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent, // Transparent to use container color
              selectedItemColor: const Color(0xFFD81B60), // Richer pink for selected items
              unselectedItemColor: const Color(0xFF424242), // Darker grey for unselected
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              showUnselectedLabels: true,
              elevation: 0,
              items: [
                _buildNavItem(Icons.restaurant_menu_rounded, "Menu", controller.selectedIndex.value == 0, null),
                _buildNavItem(Icons.receipt_rounded, "Orders", controller.selectedIndex.value == 1, null),
                _buildNavItem(Icons.shopping_bag_rounded, "Cart", controller.selectedIndex.value == 2, controller.cartItemCount.value),
                _buildNavItem(Icons.person_rounded, "Profile", controller.selectedIndex.value == 3, null),
              ],
            ),
          ),
        ),
      );
    });
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, bool isSelected, int? badgeCount) {
    return BottomNavigationBarItem(
      icon: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: isSelected ? 30 : 26,
              color: isSelected ? const Color(0xFFD81B60) : const Color(0xFF424242),
            ),
          ),
          if (badgeCount != null && badgeCount > 0)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF3D00), // Bright red-orange badge for visibility
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      label: label,
    );
  }
}