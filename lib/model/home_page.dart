import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dapur_anita/konstanta.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:dapur_anita/model/produk.dart';
import 'package:dapur_anita/admin/edit_form.dart';
import 'package:dapur_anita/auth/login_page.dart';
import 'package:dapur_anita/admin/tambah_produk.dart';
import 'package:dapur_anita/model/keranjang.dart';
import 'package:dapur_anita/model/produk_detail.dart';
import 'package:dapur_anita/auth/profil.dart';
import 'package:dapur_anita/model/pesanan_page.dart';
import 'package:dapur_anita/admin/dashboard_page.dart';
import 'package:dapur_anita/model/toko_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.id,
    this.name,
    this.email,
    this.type,
  });

  final int? id;
  final String? name;
  final String? email;
  final String? type;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  String? id;
  bool isAdmin = false;
  String? name;
  String? email;
  late TabController _tabController;
  TextEditingController searchController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    name = widget.name;
    email = widget.email;
    isAdmin = widget.type == "admin";
    fetchData();
    getTypeValue();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isAdmin) {
      return const AdminDashboardPage();
    }

    final List<Widget> pages = [
      // Beranda (Home)
      Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: null,
          actions: [
            IconButton(
              icon: Icon(Icons.shopping_cart, color: Colors.red),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => KeranjangPage()),
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Rekomendasi'),
              Tab(text: 'Terlaris'),
              Tab(text: 'Top Rating'),
            ],
            labelColor: Colors.red,
            unselectedLabelColor: Colors.grey[400],
            indicatorColor: Colors.red,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProductList(),
            _buildProductList(),
            _buildProductList(),
          ],
        ),
      ),
      // Pesanan Saya
      const PesananPage(),
      // Profil
      const ProfilPage(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: pages[_selectedIndex],
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
            icon: Icon(Icons.home),
            activeIcon: Icon(Icons.home, color: Colors.red),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            activeIcon: Icon(Icons.receipt, color: Colors.red),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            activeIcon: Icon(Icons.person, color: Colors.red),
            label: 'Profil',
          ),
        ],
        selectedLabelStyle: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(color: Colors.grey[400]),
        elevation: 8,
      ),
    );
  }

  Widget _buildFilterButton(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber[400]!, width: 1),
      ),
      child: Row(
        children: [
          Text(text, style: TextStyle(color: Colors.white)),
          SizedBox(width: 4),
          Icon(icon, size: 16, color: Colors.amber[400]),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return FutureBuilder<List<ProdukResponModel>>(
      future: fetchData(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var produk = snapshot.data![index];
              return Card(
                color: Colors.white,
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red, width: 1.5),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProdukDetailPage(produk: produk),
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                produk.namaProduk.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Rp ${produk.hargaProduk}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Stok: ${produk.stok}",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isAdmin)
                          IconButton(
                            icon: Icon(Icons.add_shopping_cart, color: Colors.red),
                            onPressed: () => addToCart(context, produk.idProduk!, 1),
                          )
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.red),
                                onPressed: () => goEdit(produk.idProduk.toString()),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => delete(produk.idProduk.toString()),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              '${snapshot.error}',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
          ),
        );
      },
    );
  }

  Future<List<ProdukResponModel>> fetchData() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/getProduk'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      List<ProdukResponModel> produkList = data.map((e) => ProdukResponModel.fromJson(e)).toList();
      return produkList;
    } else {
      throw Exception('Failed to load Produk');
    }
  }

  getTypeValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? stringValue = prefs.getString('type');
    String? nama = prefs.getString('name');
    String? email1 = prefs.getString('email');
    setState(() {
      fetchData();
      if (stringValue == "admin") {
        isAdmin = true;
        name = nama;
        email = email1;
      }
    });
  }

  logOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  goEdit(String idBarang) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditForm(idBarang: idBarang),
      ),
    );
  }

  Future<void> delete(String idBarang) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/deleteApi/$idBarang'));
      if (response.statusCode == 200) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Data Berhasil dihapus'),
              content: const Text("Data Berhasil dihapus"),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text('OK'),
                  onPressed: () {
                    setState(() {
                      fetchData();
                    });
                  },
                ),
              ],
            );
          },
        );
      } else {
        throw Exception('Failed to delete data');
      }
    } catch (error) {
      print(error);
    }
  }


}