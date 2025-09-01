import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  final TextEditingController _vehicleController = TextEditingController();

  /// 🔹 Fetch user profile and stats
  Stream<Map<String, dynamic>> _getProfileData() {
    return _firestore.collection('delivery_boys').doc(_uid).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) {
        return {
          "name": "Unknown",
          "email": "unknown@example.com",
          "phone": "+91 XXXXXXXX",
          "profilePic": null,
          "totalDeliveries": 0,
          "rating": 0.0,
          "vehicleNumber": "",
        };
      }
      var data = snapshot.data()!;
      _vehicleController.text = data["vehicleNumber"] ?? "";
      return {
        "name": data["name"] ?? "Unknown",
        "email": data["email"] ?? "unknown@example.com",
        "phone": data["phone"] ?? "+91 XXXXXXXX",
        "profilePic": data["profilePic"],
        "totalDeliveries": data["totalDeliveries"] ?? 0,
        "rating": data["rating"] ?? 0.0,
        "vehicleNumber": data["vehicleNumber"] ?? "",
      };
    });
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _getProfileData(),
        builder: (context, snapshot) {
          var data =
              snapshot.data ??
              {
                "name": "Devendra Verma", // default name
                "email": "devendra@example.com", // default email
                "phone": "+91 9876543210", // default phone
                "profilePic": null, // default picture (will use Asset)
                "totalDeliveries": 0, // default stats
                "rating": 0.0,
                "vehicleNumber": "hr",
              };

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile picture
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundImage: data["profilePic"] != null
                          ? NetworkImage(data["profilePic"])
                          : const AssetImage('lib/assets/cat.png')
                                as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Name
                  Text(
                    data["name"],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Email
                  Text(
                    data["email"],
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  // Phone
                  Text(
                    data["phone"],
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard(
                        "Total Deliveries",
                        data["totalDeliveries"].toString(),
                        Colors.blue,
                      ),
                      _buildStatCard(
                        "Rating",
                        "${data["rating"]} ★",
                        Colors.amber,
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // Vehicle Info Card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Vehicle Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _vehicleController,
                            decoration: InputDecoration(
                              labelText: "Vehicle Number",
                              prefixIcon: const Icon(Icons.directions_car),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                _firestore
                                    .collection('delivery_boys')
                                    .doc(_uid)
                                    .update({
                                      "vehicleNumber": _vehicleController.text,
                                    });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Vehicle info updated successfully",
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Colors.blue,
                              ),
                              child: const Text(
                                "Update Vehicle Info",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Settings List
                  _buildSettingsTile(Icons.person, Colors.blue, "Edit Profile"),
                  _buildSettingsTile(
                    Icons.lock,
                    Colors.orange,
                    "Change Password",
                  ),
                  _buildSettingsTile(Icons.settings, Colors.grey, "Settings"),

                  const SizedBox(height: 25),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _auth.signOut();
                        // Navigate to login screen if needed
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, Color color, String title) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }
}
