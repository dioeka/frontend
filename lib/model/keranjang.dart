import 'package:flutter/material.dart';
import 'package:dapur_anita/konstanta.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dapur_anita/auth/alamat_page.dart';

class CartItem {
  final int id;
  final String name;
  final String image;
  final int price;
  final String variant;
  int quantity;
  bool isSelected;

  CartItem({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.variant,
    required this.quantity,
    this.isSelected = true,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? 0,
      name: json['nama_produk'] ?? '',
      image: json['foto_produk'] ?? '',
      price: json['harga_produk'] ?? 0,
      variant: json['berat']?.toString() ?? '',
      quantity: json['jumlah'] ?? 1,
      isSelected: true,
    );
  }
}

Future<bool> addToCart(BuildContext context, int productId, int quantity) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('id');
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/keranjang'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'id_user': userId,
        'id_produk': productId,
        'jumlah': quantity,
      }),
    );

    print('Request URL: $baseUrl/api/keranjang');
    print('Request Body: ${json.encode({
      'id_user': userId,
      'id_produk': productId,
      'jumlah': quantity,
    })}');

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil menambahkan ke keranjang'),
          backgroundColor: Colors.green,
        ),
      );
      return true;
    } else {
      print('Error Response: ${response.body}');
      print('Status Code: ${response.statusCode}');
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal menambahkan ke keranjang');
    }
  } catch (e) {
    print('Exception: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }
}

class KeranjangPage extends StatefulWidget {
  const KeranjangPage({super.key});

  @override
  State<KeranjangPage> createState() => _KeranjangPageState();
}

class _KeranjangPageState extends State<KeranjangPage> {
  List<CartItem> cartItems = [];
  bool selectAll = true;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('id');
      
      if (userId == null) {
        setState(() {
          error = "Silakan login terlebih dahulu";
          isLoading = false;
        });
        return;
      }

      print('Fetching cart items for user $userId');
      final response = await http.get(
        Uri.parse('$baseUrl/api/keranjang/$userId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          cartItems = data.map((item) => CartItem.fromJson(item)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Gagal memuat keranjang: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching cart items: $e');
      setState(() {
        error = "Terjadi kesalahan: $e";
        isLoading = false;
      });
    }
  }

  Future<void> updateCartItemQuantity(int itemId, int quantity) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('id');

      if (userId == null) return;

      final response = await http.put(
        Uri.parse('$baseUrl/api/keranjang/$itemId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'quantity': quantity,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal mengupdate jumlah');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void updateQuantity(int index, bool increment) async {
    final item = cartItems[index];
    final newQuantity = increment ? item.quantity + 1 : item.quantity - 1;
    
    if (newQuantity < 1) return;

    setState(() {
      cartItems[index].quantity = newQuantity;
    });

    await updateCartItemQuantity(item.id, newQuantity);
  }

  Future<void> deleteSelectedItems() async {
    try {
      for (var item in cartItems.where((item) => item.isSelected)) {
        final response = await http.delete(
          Uri.parse('$baseUrl/api/keranjang/${item.id}'),
          headers: {
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            cartItems.removeWhere((cartItem) => cartItem.id == item.id);
          });
        } else {
          throw Exception('Gagal menghapus item');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void toggleSelectAll() {
    setState(() {
      selectAll = !selectAll;
      for (var item in cartItems) {
        item.isSelected = selectAll;
      }
    });
  }

  void toggleSelectItem(int index) {
    setState(() {
      cartItems[index].isSelected = !cartItems[index].isSelected;
      selectAll = cartItems.every((item) => item.isSelected);
    });
  }

  int get totalPrice {
    return cartItems
        .where((item) => item.isSelected)
        .fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  int get selectedCount {
    return cartItems.where((item) => item.isSelected).length;
  }

  Future<void> checkoutSelectedItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('id');
    final selectedItems = cartItems.where((item) => item.isSelected).toList();

    if (userId == null || selectedItems.isEmpty) return;

    final items = selectedItems.map((item) => {
      'id_produk': item.id,
      'jumlah': item.quantity,
    }).toList();

    final alamatUser = {
      'nama_penerima': 'Budi',
      'alamat': 'Jl. Mawar No. 1',
      'no_telp': '08123456789',
      'provinsi': 'Jawa Barat',
      'kota': 'Bandung',
      'kodepos': '40123',
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/checkout'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id_user': userId,
        'items': items,
        'total_harga': totalPrice,
        ...alamatUser,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        cartItems.removeWhere((item) => item.isSelected);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checkout berhasil!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout gagal: ${response.body}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Keranjang'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchCartItems,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Keranjang', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: IconThemeData(color: Colors.red),
        elevation: 1,
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Text(
                'Keranjang kosong',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: fetchCartItems,
                    color: Colors.red,
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.red.withOpacity(0.5)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: item.isSelected,
                                  onChanged: (_) => toggleSelectItem(index),
                                  activeColor: Colors.red,
                                  checkColor: Colors.white,
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    '$gambarUrl/produk/${item.image}',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[200],
                                        child: Icon(Icons.error, color: Colors.red),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.red,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      if (item.variant.isNotEmpty) ...[
                                        Text(
                                          item.variant,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      Text(
                                        'Rp${item.price}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.remove, color: Colors.red),
                                            onPressed: () => updateQuantity(index, false),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          Container(
                                            margin: EdgeInsets.symmetric(horizontal: 8),
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.red.withOpacity(0.5)),
                                            ),
                                            child: Text(
                                              '${item.quantity}',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.add, color: Colors.red),
                                            onPressed: () => updateQuantity(index, true),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.08),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: selectAll,
                              onChanged: (_) => toggleSelectAll(),
                              activeColor: Colors.red,
                              checkColor: Colors.white,
                            ),
                            Text(
                              'Pilih Semua',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Rp$totalPrice',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: selectedCount > 0
                              ? checkoutSelectedItems
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Beli ($selectedCount)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
