import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ondoor/auth/login_page.dart';
import 'package:ondoor/delivery.dart'; // make sure DashboardScreen is imported

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase initialization
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDVLjv3V3LU6h_MbAgjyDiY_Y1yt5Ov-wk",
      appId: "1:1066214452856:android:7792460cb825c5add6478d",
      messagingSenderId: "1066214452856",
      projectId: "deliveryapp-b595e",
      storageBucket: "deliveryapp-b595e.firebasestorage.app",
    ),
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is already logged in
    User? currentUser = FirebaseAuth.instance.currentUser;

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: currentUser != null
          ? const DashboardScreen() // auto-redirect to dashboard
          : const DeliveryLoginPage(), // show login page if not signed in
    );
  }
}
