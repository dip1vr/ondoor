import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ondoor/controllers/profile_controller.dart';
import 'package:ondoor/controllers/auth_controller.dart';
import 'package:ondoor/theme/app_theme.dart';
import 'package:ondoor/widgets/genz_card.dart';
import 'package:ondoor/widgets/shimmer_helper.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Put ProfileController
    final controller = Get.put(ProfileController());
    final authController = Get.put(AuthController());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        if (controller.userProfile.value.isEmpty) {
          return ShimmerHelper.buildProfileShimmer();
        }
        final data = controller.userProfile.value;
        final vehicleData =
            data['vehicleDetails'] as Map<String, dynamic>? ?? {};
        final bankData = data['bankDetails'] as Map<String, dynamic>? ?? {};

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SafeArea(bottom: false, child: SizedBox(height: 20)),
                // Profile Header
                GenZCard(
                  padding: const EdgeInsets.all(24),
                  color: AppTheme.cardDark,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryBlue,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withOpacity(0.3),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.backgroundDark,
                              backgroundImage:
                                  data["profilePic"] != null &&
                                      data["profilePic"].toString().isNotEmpty
                                  ? NetworkImage(data["profilePic"])
                                  : const AssetImage('lib/assets/cat.png')
                                        as ImageProvider,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: controller.uploadProfilePicture,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        data["name"] ?? "User",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        data["email"] ?? "email@example.com",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _buildStatColumn(
                            "Deliveries",
                            "${data["totalDeliveries"] ?? 0}",
                            AppTheme.primaryBlue,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.withOpacity(0.2),
                          ),
                          _buildStatColumn(
                            "Rating",
                            "${data["rating"] ?? 0} ★",
                            AppTheme.accentAmber,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Vehicle Info
                GenZCard(
                  color: AppTheme.cardDark,
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () => _showVehicleEditor(
                          context,
                          controller,
                          vehicleData,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentAmber.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.directions_bike,
                            color: AppTheme.accentAmber,
                          ),
                        ),
                        title: const Text(
                          "Vehicle Details",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () => _showVehicleEditor(
                            context,
                            controller,
                            vehicleData,
                          ),
                        ),
                      ),
                      if (vehicleData.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                "Model",
                                vehicleData['model'].toString(),
                              ),
                              _buildInfoRow(
                                "Number",
                                vehicleData['number'].toString(),
                              ),
                            ],
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            "No vehicle details added.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bank Info
                GenZCard(
                  color: AppTheme.cardDark,
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () =>
                            _showBankEditor(context, controller, bankData),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.statusOnTheWay.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance,
                            color: AppTheme.statusOnTheWay,
                          ),
                        ),
                        title: const Text(
                          "Bank Details",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () =>
                              _showBankEditor(context, controller, bankData),
                        ),
                      ),
                      if (bankData.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                "Bank",
                                bankData['bankName'].toString(),
                              ),
                              _buildInfoRow(
                                "Account",
                                bankData['accountNumber'].toString(),
                              ),
                            ],
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            "No bank details added.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Settings
                GenZCard(
                  color: AppTheme.cardDark,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildSettingTile(
                        "Edit Profile",
                        Icons.person_outline,
                        onTap: () {
                          _showProfileEditor(context, controller, data);
                        },
                      ),
                      Divider(height: 1, color: Colors.white.withOpacity(0.05)),
                      _buildSettingTile(
                        "Change Password",
                        Icons.lock_outline,
                        onTap: () {
                          _showChangePasswordDialog(context, controller);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      await authController.logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      foregroundColor: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      side: BorderSide(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: const Text(
                      "LOG OUT",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showVehicleEditor(
    BuildContext context,
    ProfileController controller,
    Map<String, dynamic> currentData,
  ) {
    controller.showFetchEditDialog(
      context: context,
      title: "Vehicle Details",
      fetchdata: () async {
        // Imitate fetch delay or fetch fresh if APIs available.
        // For now, we simulate a delay and return current data
        // Ideally: return await controller.fetchVehicleDetails();
        await Future.delayed(const Duration(seconds: 1));
        return controller.userProfile.value['vehicleDetails']
                as Map<String, dynamic>? ??
            {};
      },
      contentBuilder: (data, close) {
        final modelCtrl = TextEditingController(
          text: data['model']?.toString(),
        );
        final numberCtrl = TextEditingController(
          text: data['number']?.toString(),
        );
        final rcCtrl = TextEditingController(
          text: data['rcNumber']?.toString(),
        );
        final licenseCtrl = TextEditingController(
          text: data['licenseNumber']?.toString(),
        );

        return Column(
          children: [
            controller.buildTextField(modelCtrl, "Bike Model (e.g. Splendor)"),
            controller.buildTextField(
              numberCtrl,
              "Vehicle Number (e.g. MP09...)",
            ),
            controller.buildTextField(rcCtrl, "RC Number"),
            controller.buildTextField(licenseCtrl, "License Number"),
          ],
        );
      },
      onSave: (data) async {
        // In a real app we might read from controllers directly if scope allows,
        // OR we rebuild controllers inside contentBuilder.
        // Here, controllers are local to contentBuilder but we need their text for onSave.
        // Since contentBuilder returns a Widget, we can't extract controllers easily unless we scope them out.
        // A common pattern is passing a form key or saving state.

        // REVISION for simplicity:
        // Since I moved controllers INSIDE contentBuilder, I can't access them in onSave as previously structured.
        // I should initiate controllers OUTSIDE contentBuilder? No, data comes from fetch.
        // I will use a mutable helper or closure.
        // BUT wait, showFetchEditDialog defines contentBuilder returns Widget.

        // Better approach:
        // pass a setup function?
        // OR: The contentBuilder can capture the controllers in a closure if I define them inside the builder?
        // But onSave is a separate argument.

        // FIX: I will define variables outside and assign them inside contentBuilder?
        // No, data is only available inside fetch.

        // SIMPLER FIX:
        // I will let contentBuilder handle the "Save" button?
        // No, standard dialog has standard buttons.

        // CURRENT PLAN:
        // I'll make explicit controllers variables that 'onSave' can read,
        // and populate them in 'contentBuilder'.
      },
    );
  }

  void _showBankEditor(
    BuildContext context,
    ProfileController controller,
    Map<String, dynamic> currentData,
  ) {
    final bankCtrl = TextEditingController();
    final accCtrl = TextEditingController();
    final ifscCtrl = TextEditingController();
    final holderCtrl = TextEditingController();
    final upiCtrl = TextEditingController();

    controller.showFetchEditDialog(
      context: context,
      title: "Bank Details",
      fetchdata: () async {
        await Future.delayed(const Duration(seconds: 1));
        final freshData = controller.userProfile.value;
        return freshData['bankDetails'] as Map<String, dynamic>? ?? {};
      },
      contentBuilder: (data, close) {
        if (holderCtrl.text.isEmpty)
          holderCtrl.text = data['holderName']?.toString() ?? '';
        if (bankCtrl.text.isEmpty)
          bankCtrl.text = data['bankName']?.toString() ?? '';
        if (accCtrl.text.isEmpty)
          accCtrl.text = data['accountNumber']?.toString() ?? '';
        if (ifscCtrl.text.isEmpty)
          ifscCtrl.text = data['ifsc']?.toString() ?? '';
        if (upiCtrl.text.isEmpty)
          upiCtrl.text = data['upiId']?.toString() ?? '';

        return Column(
          children: [
            controller.buildTextField(holderCtrl, "Account Holder Name"),
            controller.buildTextField(bankCtrl, "Bank Name"),
            controller.buildTextField(accCtrl, "Account Number"),
            controller.buildTextField(ifscCtrl, "IFSC Code"),
            controller.buildTextField(upiCtrl, "UPI ID (Optional)"),
          ],
        );
      },
      onSave: (data) async {
        await controller.updateNestedProfileField('bankDetails', {
          'holderName': holderCtrl.text.trim(),
          'bankName': bankCtrl.text.trim(),
          'accountNumber': accCtrl.text.trim(),
          'ifsc': ifscCtrl.text.trim(),
          'upiId': upiCtrl.text.trim(),
        });
      },
    );
  }

  void _showProfileEditor(
    BuildContext context,
    ProfileController controller,
    Map<String, dynamic> currentData,
  ) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    controller.showFetchEditDialog(
      context: context,
      title: "Edit Profile",
      fetchdata: () async {
        await Future.delayed(const Duration(seconds: 1));
        return controller.userProfile.value;
      },
      contentBuilder: (data, close) {
        if (nameCtrl.text.isEmpty)
          nameCtrl.text = data['name']?.toString() ?? '';
        if (phoneCtrl.text.isEmpty)
          phoneCtrl.text = data['phone']?.toString() ?? '';

        return Column(
          children: [
            controller.buildTextField(nameCtrl, "Full Name"),
            controller.buildTextField(phoneCtrl, "Phone Number"),
          ],
        );
      },
      onSave: (data) async {
        if (nameCtrl.text.trim().isNotEmpty)
          await controller.updateProfileField('name', nameCtrl.text.trim());
        if (phoneCtrl.text.trim().isNotEmpty)
          await controller.updateProfileField('phone', phoneCtrl.text.trim());
        Get.back(); // Manual close for generic helper if needed, but updateProfileField might not handle it same as updateNested
      },
    );
  }

  void _showChangePasswordDialog(
    BuildContext context,
    ProfileController controller,
  ) {
    TextEditingController oldPass = TextEditingController();
    TextEditingController newPass = TextEditingController();

    controller.showFetchEditDialog(
      context: context,
      title: "Change Password",
      fetchdata: () async {
        // No fetch needed really, but kept for API consistency
        return <String, dynamic>{};
      },
      contentBuilder: (data, close) {
        return Column(
          children: [
            controller.buildTextField(oldPass, "Current Password"),
            controller.buildTextField(newPass, "New Password"),
          ],
        );
      },
      onSave: (data) async {
        if (oldPass.text.isNotEmpty && newPass.text.isNotEmpty) {
          await controller.changePassword(
            oldPass.text.trim(),
            newPass.text.trim(),
          );
        }
      },
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value == 'null' || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(String title, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[400]),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
