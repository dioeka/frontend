import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dapur_anita/konstanta.dart';
import 'package:intl/intl.dart';

class PesananAdminPage extends StatefulWidget {
  const PesananAdminPage({Key? key}) : super(key: key);

  @override
  State<PesananAdminPage> createState() => _PesananAdminPageState();
}

class _PesananAdminPageState extends State<PesananAdminPage> {
  bool isLoading = true;
  String? errorMessage;
  Map<String, List<dynamic>> pesananData = {
    'pesanan_masuk': [],
    'pesanan_on_progress': [],
    'pesanan_pengiriman': []
  };

  @override
  void initState() {
    super.initState();
    fetchPesanan();
  }

  Future<void> fetchPesanan() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/getPesananByStatus'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Pesanan Response Status: ${response.statusCode}');
      print('Pesanan Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          pesananData = {
            'pesanan_masuk': List<dynamic>.from(data['pesanan_masuk']),
            'pesanan_on_progress': List<dynamic>.from(data['pesanan_on_progress']),
            'pesanan_pengiriman': List<dynamic>.from(data['pesanan_pengiriman'])
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
      print('Error fetching orders: $e');
      setState(() {
        errorMessage = 'Gagal memuat data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> updatePesananStatus(int pesananId, String newStatus) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/updatePesananStatus/$pesananId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        // Refresh pesanan list
        fetchPesanan();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status pesanan')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String formatCurrency(dynamic amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
        ),
      );
    }

    if (errorMessage != null) {
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
            Text(
              errorMessage!,
              style: TextStyle(color: Colors.red[400]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: fetchPesanan,
              child: Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchPesanan,
      color: Colors.red,
      child: ListView(
        children: [
          _buildPesananList(
            'Pesanan Masuk',
            pesananData['pesanan_masuk']!,
            showBadge: true,
          ),
          _buildPesananList(
            'Pesanan On Proses',
            pesananData['pesanan_on_progress']!,
          ),
          _buildPesananList(
            'Pesanan Dalam Pengiriman',
            pesananData['pesanan_pengiriman']!,
          ),
        ],
      ),
    );
  }

  Widget _buildPesananList(String title, List<dynamic> pesananList, {bool showBadge = false}) {
    return ExpansionTile(
      title: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showBadge && pesananList.isNotEmpty)
            Container(
              margin: EdgeInsets.only(left: 8),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${pesananList.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      children: pesananList.isEmpty
          ? [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Belum ada pesanan',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            ]
          : pesananList.map<Widget>((pesanan) {
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: ListTile(
                  title: Text(
                    pesanan['nama_pelanggan'] ?? 'Pelanggan',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatCurrency(pesanan['total_harga']),
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${pesanan['items']} item • ${pesanan['tanggal']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.red),
                    color: Colors.white,
                    onSelected: (String status) {
                      updatePesananStatus(pesanan['id'], status);
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'diproses',
                        child: Text('Proses Pesanan', style: TextStyle(color: Colors.red)),
                      ),
                      PopupMenuItem<String>(
                        value: 'dikirim',
                        child: Text('Kirim Pesanan', style: TextStyle(color: Colors.red)),
                      ),
                      PopupMenuItem<String>(
                        value: 'selesai',
                        child: Text('Selesaikan Pesanan', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
    );
  }
} 