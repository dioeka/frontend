import 'package:flutter/material.dart';
import 'package:dapur_anita/konstanta.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PesananPage extends StatefulWidget {
  const PesananPage({Key? key}) : super(key: key);

  @override
  State<PesananPage> createState() => _PesananPageState();
}

class _PesananPageState extends State<PesananPage> {
  String selectedStatus = "Semua";
  List<String> statusFilters = ["Semua", "Menunggu", "Diproses", "Dikirim", "Selesai", "Dibatalkan"];
  List<Map<String, dynamic>> pesananList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPesanan();
  }

  Future<void> fetchPesanan() async {
    setState(() => isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('id');
      
      if (userId == null) {
        setState(() {
          isLoading = false;
          pesananList = [];
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/pesanan/$userId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          pesananList = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        pesananList = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          'Pesanan Saya',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: Colors.red),
        elevation: 1,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: statusFilters.map((status) {
                  bool isSelected = selectedStatus == status;
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(status),
                      onSelected: (bool selected) {
                        setState(() {
                          selectedStatus = status;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.red,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.red,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.red : Colors.red.withOpacity(0.3),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  )
                : pesananList.isEmpty
                    ? _buildEmptyPesananView()
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: pesananList.length,
                        itemBuilder: (context, index) {
                          final pesanan = pesananList[index];
                          return Card(
                            color: Colors.white,
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.red),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Pesanan #${pesanan['id_pesanan']}',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      _buildStatusChip(pesanan['status']),
                                    ],
                                  ),
                                  Divider(color: Colors.grey[800]),
                                  Text(
                                    'Total: Rp${pesanan['total_harga']}',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tanggal: ${pesanan['tanggal_pesanan']}',
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status.toLowerCase()) {
      case 'menunggu':
        chipColor = Colors.orange;
        break;
      case 'diproses':
        chipColor = Colors.blue;
        break;
      case 'dikirim':
        chipColor = Colors.purple;
        break;
      case 'selesai':
        chipColor = Colors.green;
        break;
      case 'dibatalkan':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyPesananView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_outlined,
            size: 100,
            color: Colors.red,
          ),
          SizedBox(height: 16),
          Text(
            'Belum Ada Pesanan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Hanya pesanan yang kamu buat\ndalam 1 tahun terakhir yang muncul di sini',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
} 