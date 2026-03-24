import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:ondoor/pages/earningpage.dart';
import 'package:ondoor/pages/orderpage.dart';
import 'package:ondoor/pages/profilepage.dart';
import 'package:flutter/material.dart';
import 'package:ondoor/widgets/order_request_sheet.dart';

class DashboardController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  RxInt selectedIndex = 0.obs;
  RxBool isOnline = false.obs;
  Rxn<Timestamp> onlineAt = Rxn<Timestamp>();

  StreamSubscription<QuerySnapshot>? _orderSubscription;
  String get uid => _auth.currentUser?.uid ?? '';

  // Stats Observables
  RxInt earnings = 0.obs;
  RxInt activeOrdersCount = 0.obs;
  RxInt completedOrdersCount = 0.obs;
  RxString deliveryBoyName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadOnlineStatus();
  }

  @override
  void onClose() {
    _orderSubscription?.cancel();
    super.onClose();
  }

  void changeTabIndex(int index) {
    selectedIndex.value = index;
  }

  void _loadOnlineStatus() async {
    if (uid.isEmpty) return;

    final doc = await _firestore.collection("deliveryBoys").doc(uid).get();
    if (doc.exists && doc["isOnline"] == true) {
      isOnline.value = true;
      onlineAt.value = doc.data()?.containsKey('onlineAt') == true
          ? doc['onlineAt'] as Timestamp
          : Timestamp.now();

      if (doc.data()?.containsKey('name') == true) {
        deliveryBoyName.value = doc['name'];
      }

      _subscribeToOrders();
    }
  }

  Future<void> toggleOnline() async {
    isOnline.value = !isOnline.value;

    if (isOnline.value) {
      final now = Timestamp.now();
      onlineAt.value = now;

      await _firestore.collection("deliveryBoys").doc(uid).set({
        "isOnline": true,
        "onlineAt": FieldValue.serverTimestamp(),
        "lastUpdated": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _subscribeToOrders();
    } else {
      await _firestore.collection("deliveryBoys").doc(uid).set({
        "isOnline": false,
        "lastUpdated": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _unsubscribeFromOrders();
    }
  }

  void _subscribeToOrders() {
    _unsubscribeFromOrders(); // Ensure no duplicates

    _orderSubscription = _firestore
        .collection('orders')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              // strict offline check
              if (!isOnline.value) return;

              var order = change.doc.data()!;

              // Skip orders created before online
              if (onlineAt.value != null && order['createdAt'] != null) {
                final createdAt = order['createdAt'] as Timestamp;
                if (createdAt.compareTo(onlineAt.value!) < 0) {
                  return;
                }
              }

              // Skip if missed
              List<dynamic> missedBy = order['missedBy'] ?? [];
              if (missedBy.contains(uid)) {
                return;
              }

              // Trigger UI
              Get.bottomSheet(
                OrderRequestSheet(
                  order: order,
                  orderId: change.doc.id,
                  uid: uid,
                  deliveryBoyName: deliveryBoyName.value,
                ),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                enableDrag: true,
              );
            }
          }
        });
  }

  void _unsubscribeFromOrders() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
  }

  // Stats Stream
  Stream<Map<String, dynamic>> get statsStream {
    return _firestore
        .collection("orders")
        .where("deliveryBoyId", isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          int active = 0;
          int completed = 0;
          int totalEarnings = 0;

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final status = (data['status'] ?? '').toString().toLowerCase();
            final total = data['totalAmount'] ?? 0;

            if (status == 'completed' || status == 'delivered') {
              completed += 1;
              totalEarnings += (total as num).toInt();
            } else if ([
              'accepted',
              'pickup',
              'picked up',
              'on the way',
            ].contains(status)) {
              active += 1;
            }
          }

          // Update local observables suitable for UI if needed without StreamBuilder
          earnings.value = totalEarnings;
          activeOrdersCount.value = active;
          completedOrdersCount.value = completed;

          // Sync to Firestore (legacy logic)
          _firestore.collection("deliveryBoys").doc(uid).set({
            "earnings": totalEarnings,
            "activeOrders": active,
            "completedOrders": completed,
            "lastUpdated": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          return {
            "earnings": totalEarnings,
            "active": active,
            "completed": completed,
          };
        });
  }

  Stream<List<Map<String, dynamic>>> get activeOrdersStream {
    return _firestore
        .collection("orders")
        .where("deliveryBoyId", isEqualTo: uid)
        .where(
          "status",
          whereIn: ["accepted", "pickup", "picked up", "on the way"],
        )
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }
}
