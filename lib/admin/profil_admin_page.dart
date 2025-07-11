import 'package:flutter/material.dart';
import 'package:dapur_anita/konstanta.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dapur_anita/auth/login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilAdminPage extends StatefulWidget {
  const ProfilAdminPage({Key? key}) : super(key: key);

  @override
  State<ProfilAdminPage> createState() => _ProfilAdminPageState();
}

class _ProfilAdminPageState extends State<ProfilAdminPage> {
  String? profileImage;
  String? adminName;
  String? adminEmail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAdminData();
  }

  Future<void> loadAdminData() async {
    setState(() => isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('id');

      if (userId != null) {
        final response = await http.get(
          Uri.parse('$apiUrl/admin/profile/$userId'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            setState(() {
              adminName = data['data']['name'];
              adminEmail = data['data']['email'];
              profileImage = data['data']['foto_profile'];
              isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading admin data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> logOut() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const PageLogin()),
        (route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header with Image and Info
              Container(
                width: double.infinity,
                color: Colors.white,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: profileImage != null
                                  ? Image.network(
                                      '$baseUrl/foto_profile/$profileImage',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Icon(Icons.person, size: 30, color: Colors.red),
                                    )
                                  : Icon(Icons.person, size: 30, color: Colors.red),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  adminName ?? 'Admin',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  adminEmail ?? 'admin@email.com',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Akun Saya Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Akun Saya',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.edit, color: Colors.red),
                      title: const Text(
                        'Edit Profil',
                        style: TextStyle(color: Colors.red),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.red),
                      onTap: () {
                        // TODO: Navigate to edit profile
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.assessment, color: Colors.red),
                      title: const Text(
                        'Laporan',
                        style: TextStyle(color: Colors.red),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.red),
                      onTap: () {
                        // TODO: Navigate to reports
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.account_balance_wallet, color: Colors.red),
                      title: const Text(
                        'Rekening',
                        style: TextStyle(color: Colors.red),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.red),
                      onTap: () {
                        // TODO: Navigate to bank accounts
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Pengaturan Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Pengaturan',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.notifications_outlined, color: Colors.red),
                      title: const Text(
                        'Notifikasi',
                        style: TextStyle(color: Colors.red),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.red),
                      onTap: () {
                        // TODO: Navigate to notifications
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        currentIndex: 3, // Admin tab
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Admin',
          ),
        ],
        onTap: (index) {
          // Handle navigation
        },
      ),
    );
  }
} 