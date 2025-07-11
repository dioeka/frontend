import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dapur_anita/auth/login_page.dart';
import 'package:dapur_anita/auth/edit_profil.dart';
import 'package:dapur_anita/auth/alamat_page.dart';
import 'package:dapur_anita/konstanta.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  String? name;
  String? email;
  String? profileImageUrl;
  
  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name');
      email = prefs.getString('email');
      profileImageUrl = prefs.getString('profile_image');
    });
  }

  Future<void> logOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const PageLogin()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Profil Saya',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: IconThemeData(color: Colors.red),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: profileImageUrl != null
                          ? Image.network(
                              '$baseUrl/storage/$profileImageUrl',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.red,
                                  ),
                            )
                          : Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.red,
                            ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name ?? 'Nama Pengguna',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          email ?? 'email@example.com',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            _buildMenuSection(
              title: 'Akun Saya',
              items: [
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: 'Edit Profil',
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfilPage(),
                      ),
                    ).then((_) => getUserData());
                  },
                ),
                _buildMenuItem(
                  icon: Icons.location_on_outlined,
                  title: 'Daftar Alamat',
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AlamatPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildMenuSection(
              title: 'Pengaturan',
              items: [
                _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifikasi',
                  color: Colors.red,
                  onTap: () {
                    // TODO: Navigate to notifications settings
                  },
                ),
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: 'Pusat Bantuan',
                  color: Colors.red,
                  onTap: () {
                    // TODO: Navigate to help center
                  },
                ),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: 'Keluar',
                  color: Colors.red,
                  onTap: logOut,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection({required String title, required List<Widget> items}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.red.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.red,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
