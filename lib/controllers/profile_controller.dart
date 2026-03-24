import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ondoor/services/imgbb_service.dart';
import 'package:ondoor/widgets/shimmer_helper.dart';
import 'package:ondoor/theme/app_theme.dart';

class ProfileController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String get uid => _auth.currentUser?.uid ?? "";

  Rx<Map<String, dynamic>> userProfile = Rx<Map<String, dynamic>>({});
  final ImagePicker _picker = ImagePicker();
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (uid.isNotEmpty) {
      _bindProfileStream();
    }
  }

  void _bindProfileStream() {
    _firestore.collection('deliveryBoys').doc(uid).snapshots().listen((
      snapshot,
    ) {
      if (snapshot.exists) {
        userProfile.value = snapshot.data()!;
      }
    });
  }

  // Generic Update
  Future<void> updateProfileField(String field, dynamic value) async {
    try {
      if (uid.isEmpty) return;
      isLoading.value = true;
      await _firestore.collection('deliveryBoys').doc(uid).update({
        field: value,
      });
      // For simple profile updates (name/phone), we usually close dialog manually in UI onSave
      // but showing a snackbar is good.
      Get.snackbar(
        "Success",
        "$field updated",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update $field: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Update Map Fields (Vehicle/Bank)
  Future<void> updateNestedProfileField(
    String rootField,
    Map<String, dynamic> data,
  ) async {
    try {
      if (uid.isEmpty) return;
      isLoading.value = true;
      // Merge with existing data
      await _firestore.collection('deliveryBoys').doc(uid).set({
        rootField: data,
      }, SetOptions(merge: true));

      Get.back(); // Close dialog on success
      Get.snackbar(
        "Success",
        "$rootField updated successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update $rootField: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Upload Profile Picture
  Future<void> uploadProfilePicture() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      Get.dialog(ShimmerHelper.buildUploadShimmer(), barrierDismissible: false);

      // Upload to ImgBB
      String? url = await ImgBBService.uploadImage(image);

      if (url != null) {
        // Save URL to Firestore directly to avoid double snackbars/navigation issues
        await _firestore.collection('deliveryBoys').doc(uid).update({
          'profilePic': url,
        });

        Get.back(); // Close loading dialog

        Get.snackbar(
          "Success",
          "Profile picture updated successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
        );
      } else {
        throw Exception("Failed to get image URL");
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        "Error",
        "Image upload failed: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  // Change Password
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      if (isLoading.value) return;
      isLoading.value = true;
      User? user = _auth.currentUser;
      if (user == null) return;

      String email = user.email!;
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      Get.back();
      Get.snackbar(
        "Success",
        "Password changed successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Error",
        e.message ?? "Password change failed",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // --- Dialogs ---

  void showFetchEditDialog({
    required BuildContext context,
    required String title,
    required Future<Map<String, dynamic>> Function() fetchdata,
    required Widget Function(Map<String, dynamic> data, void Function() close)
    contentBuilder,
    required Future<void> Function(Map<String, dynamic> data) onSave,
  }) {
    // Local state for fetching and saving
    final RxBool isFetching = true.obs;
    final RxBool isSaving = false.obs;
    final Rx<Map<String, dynamic>> fetchedData = Rx({});

    // Trigger fetch on open
    fetchdata()
        .then((data) {
          fetchedData.value = data;
          isFetching.value = false;
        })
        .catchError((e) {
          isFetching.value = false;
          Get.back();
          Get.snackbar("Error", "Failed to load data");
        });

    Get.dialog(
      Obx(() {
        if (isSaving.value) {
          return ShimmerHelper.buildUploadShimmer();
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: isFetching.value
                        ? ShimmerHelper.buildEditFieldsShimmer()
                        : contentBuilder(fetchedData.value, () => Get.back()),
                  ),
                ),
                if (!isFetching.value) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text(
                          "Cancel",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          isSaving.value = true;
                          await onSave(
                            fetchedData.value,
                          ); // Pass ref if needed, but mostly relying on controller refs
                          isSaving.value = false;
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Save Changes"),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      }),
      barrierDismissible: false,
    );
  }

  Widget buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[400]),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryBlue),
          ),
          filled: true,
          fillColor: AppTheme.backgroundDark,
        ),
      ),
    );
  }
}
