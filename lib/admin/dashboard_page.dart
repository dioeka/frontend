import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dapur_anita/konstanta.dart';
import 'package:dapur_anita/model/pesanan_page.dart';
import 'package:dapur_anita/auth/profil.dart';
import 'package:intl/intl.dart';
import 'package:dapur_anita/admin/pesanan_admin_page.dart';
import 'package:dapur_anita/admin/tambah_produk.dart';
import 'package:dapur_anita/admin/edit_form.dart';
import 'package:dapur_anita/model/produk.dart';
import 'dart:math' as num;

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic> dashboardData = {
    'total_users': 0,
    'total_transactions': 0,
    'total_revenue': 0,
    'products_sold': 0,
  };
  int _selectedIndex = 0;
  bool isLoading = true;
  String errorMessage = '';
  
  // Add GlobalKey for RefreshIndicator
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      print('Fetching dashboard data from: $baseUrl/api/getDashboardData');
      final response = await http.get(
        Uri.parse('$baseUrl/api/getDashboardData'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Dashboard Response Status: ${response.statusCode}');
      print('Dashboard Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          dashboardData = {
            'total_users': data['total_users'] ?? 0,
            'total_transactions': data['total_transactions'] ?? 0,
            'total_revenue': double.parse(data['total_revenue'].toString()),
            'products_sold': data['products_sold'] ?? 0,
          };
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Gagal memuat data: Error ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
      setState(() {
        if (e.toString().contains('SocketException')) {
          errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda';
        } else {
          errorMessage = 'Gagal memuat data: $e';
        }
        isLoading = false;
      });
    }
  }

  String formatCurrency(dynamic amount) {
    // Convert amount to double safely
    double number;
    try {
      number = amount is double ? amount : double.parse(amount.toString());
    } catch (e) {
      number = 0;
    }
    
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(number);
  }

  Widget _buildDashboardHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.red, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text(
                'Selamat Datang, Admin!',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Pantau statistik dan kelola toko Anda',
            style: TextStyle(
              color: Colors.red[300],
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red[400]!),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[400],
              size: 60,
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                errorMessage,
                style: TextStyle(color: Colors.red[400]),
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
              ),
              onPressed: fetchDashboardData,
              child: Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchDashboardData,
      color: Colors.red[400],
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDashboardHeader(),
            SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                childAspectRatio: 1.3,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildNewStatCard(
                    'Pengguna Terdaftar',
                    dashboardData['total_users']?.toString() ?? '0',
                    Icons.people_outline,
                    [Color(0xFFD32F2F), Color(0xFFFF7043)],
                  ),
                  _buildNewStatCard(
                    'Total Transaksi Bulan Ini',
                    dashboardData['total_transactions']?.toString() ?? '0',
                    Icons.receipt_long,
                    [Color(0xFFB71C1C), Color(0xFFFF8A65)],
                  ),
                  _buildNewStatCard(
                    'Total Pendapatan',
                    formatCurrency(dashboardData['total_revenue']),
                    Icons.attach_money,
                    [Color(0xFFC62828), Color(0xFFFFA726)],
                  ),
                  _buildNewStatCard(
                    'Produk Terjual Bulan Ini',
                    dashboardData['products_sold']?.toString() ?? '0',
                    Icons.shopping_bag,
                    [Color(0xFFD84315), Color(0xFFFF7043)],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewStatCard(String title, String value, IconData icon, List<Color> gradientColors) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Icon background transparan
          Positioned(
            right: 8,
            top: 8,
            child: Icon(
              icon,
              size: 48,
              color: Colors.red.withOpacity(0.13),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        shadows: [
                          Shadow(
                            color: Colors.red.withOpacity(0.08),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    Icon(icon, color: Colors.red, size: 28),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<ProdukResponModel>> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/getProduk'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => ProdukResponModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> delete(String idBarang) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/deleteApi/$idBarang'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produk berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          // Refresh the product list
          fetchData();
        });
      } else {
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboardContent(),
      const PesananAdminPage(),
      Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Text(
            'Kelola Produk',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.red,
          child: Icon(Icons.add, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TambahProdukPage(),
              ),
            ).then((_) {
              setState(() {
                // This will trigger rebuild and fetch new data
              });
            });
          },
        ),
        body: RefreshIndicator(
          key: _refreshIndicatorKey,
          color: Colors.red,
          onRefresh: () async {
            setState(() {
              // This will trigger rebuild and fetch new data
            });
          },
          child: FutureBuilder<List<ProdukResponModel>>(
            future: fetchData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[400]),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'Tidak ada produk',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var produk = snapshot.data![index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red, width: 1.5),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Text(
                        produk.namaProduk.toString(),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatCurrency(produk.hargaProduk),
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Stok: ${produk.stok}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.red, size: 20),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditForm(
                                  idBarang: produk.idProduk.toString(),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  title: Text(
                                    'Hapus Produk',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  content: Text(
                                    'Yakin ingin menghapus produk ini?',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text(
                                        'Batal',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    TextButton(
                                      child: Text(
                                        'Hapus',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        delete(produk.idProduk.toString());
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      const ProfilPage(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 2 ? null : AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          _selectedIndex == 0 ? 'Dashboard Admin' :
          _selectedIndex == 1 ? 'Kelola Pesanan' :
          _selectedIndex == 3 ? 'Profil Admin' : '',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: Colors.red),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.red),
              onPressed: fetchDashboardData,
            ),
        ],
        elevation: 1,
      ),
      body: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.red.withOpacity(0.2), width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey[400],
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard, color: Colors.red),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long, color: Colors.red),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory, color: Colors.red),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person, color: Colors.red),
            label: 'Admin',
          ),
        ],
        selectedLabelStyle: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(color: Colors.grey[400]),
        elevation: 8,
      ),
    );
  }
} 