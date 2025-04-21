import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopify_flutter/homepage.dart';

import 'customer/customer_model.dart';
import 'customer/customer_orders.dart';
import 'customer/customer_profile.dart';
import 'main.dart';

class SettingsPage extends StatelessWidget {
  final String userName; // Pass the user's name from API
  final String userEmail; // Pass the user's email from API

  const SettingsPage({
    Key? key,
    required this.userName,
    required this.userEmail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: seedColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildSettingsOption(
              icon: Icons.person,
              title: "My Account",
                onTap: () async {
                  await Future.delayed(const Duration(milliseconds: 200));
                  if (context.mounted) {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                        const CustomerProfile(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin =
                          Offset(3.0, 0.0); // Slide in from the right
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;

                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          var offsetAnimation = animation.drive(tween);

                          return SlideTransition(
                            position: offsetAnimation,
                            child: child,
                          );
                        },
                      ),
                    );
                  }
                },),

            _buildSettingsOption(
              icon: Icons.favorite,
              title: "Wishlist",
              onTap: () {
                // Navigate to Wishlist Page
              },
            ),
            _buildSettingsOption(
              icon: Icons.shopping_cart,
              title: "Cart",
              onTap: () {
                // Navigate to Cart Page
              },
            ),
            _buildSettingsOption(
              icon: Icons.history,
              title: "Order History",
                onTap: () async {
                  await Future.delayed(const Duration(milliseconds: 200));
                  if (context.mounted) {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                        const CustomerOrders(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin =
                          Offset(3.0, 0.0); // Slide in from the right
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;

                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          var offsetAnimation = animation.drive(tween);

                          return SlideTransition(
                            position: offsetAnimation,
                            child: child,
                          );
                        },
                      ),
                    );
                  }
                }),


            _buildSettingsOption(
              icon: Icons.notifications,
              title: "Notifications",
              onTap: () {
                // Manage Notifications
              },
            ),
            _buildSettingsOption(
              icon: Icons.payment,
              title: "Payment Methods",
              onTap: () {
                // Manage Payment Methods
              },
            ),
            const Divider(height: 40, thickness: 1, color: Colors.grey),
            _buildSettingsOption(
              icon: Icons.logout,
              title: "Logout",
              onTap: () {
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: seedColor,
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[200],
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : "?",
          style: const TextStyle(
            fontSize: 45,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),)          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName, // User name fetched from API
                style: const TextStyle(
                  fontSize: 20,
                   fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userEmail, // User email fetched from API
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          "Logout",
          style: TextStyle(color: Colors.black),
        ),
        content: const Text(
          "Are you sure you want to logout?",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await Future.delayed(const Duration(milliseconds: 200));
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              await context.read<CustomerModel>().logout(context);

              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out')));
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>MyHomePage()));

            },
            child: const Text("Logout", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
