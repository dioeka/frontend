import 'package:flutter/material.dart';
import 'package:dapur_anita/konstanta.dart';
import 'package:dapur_anita/model/keranjang.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:dapur_anita/model/pesanan_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PaymentUploadPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final int totalPrice;
  final Map<String, String> alamat;

  const PaymentUploadPage({
    super.key,
    required this.cartItems,
    required this.totalPrice,
    required this.alamat,
  });

  @override
  State<PaymentUploadPage> createState() => _PaymentUploadPageState();
}

class _PaymentUploadPageState extends State<PaymentUploadPage> {
  XFile? _imageFile;
  Uint8List? _webImage;
  final picker = ImagePicker();
  bool isLoading = false;
  late int ongkir;
  late int totalOngkir;

  @override
  void initState() {
    super.initState();
    // Calculate ongkir (12% from total price)
    ongkir = (widget.totalPrice * 0.12).round();
    totalOngkir = widget.totalPrice + ongkir;
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });

        if (kIsWeb) {
          var bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      showError('Gagal memilih gambar: $e');
    }
  }

  Future<void> _uploadPayment() async {
    if (_imageFile == null) {
      showError('Silakan pilih bukti pembayaran terlebih dahulu');
      return;
    }

    setState(() => isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('id');

      if (userId == null) {
        showError('Silakan login terlebih dahulu');
        return;
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/checkout'),
      );

      // Add all required fields exactly matching the database schema
      request.fields.addAll({
        'id_produk': widget.cartItems.first.id.toString(),
        'id_user': userId.toString(),
        'quantity': widget.cartItems.first.quantity.toString(),
        'harga_total_bayar': widget.totalPrice.toString(),  // Harga produk saja
        'ongkir': ongkir.toString(),
        'total_ongkir': totalOngkir.toString(),
        'bukti_bayar': '', // Will be filled by file upload
        'total_dp': '', // Nullable
        'bukti_bayar_dp': '', // Nullable
        'bukti_bayar_dp_lunas': '', // Nullable
        'dp_status': '', // Nullable
        'status': '0', // Belum dibayar
        'tipe_pembayaran': 'full',
      });

      print('Debug - Request fields:');
      request.fields.forEach((key, value) {
        print('$key: $value');
      });

      // Add file
      if (kIsWeb) {
        if (_webImage != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'bukti_bayar',
              _webImage!,
              filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          );
        }
      } else {
        var file = File(_imageFile!.path);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'bukti_bayar',
              file.path,
              filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          );
        } else {
          throw Exception('File tidak ditemukan');
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (!mounted) return;
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Color(0xFF2D2D2D),
            title: Text(
              'Pembayaran Berhasil',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Pesanan Anda sedang diproses',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                child: Text(
                  'Lihat Pesanan',
                  style: TextStyle(color: Colors.amber[400]),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const PesananPage()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        );
      } else {
        var errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal mengupload bukti pembayaran');
      }
    } catch (e) {
      print('Error uploading payment: $e');
      showError('Gagal mengupload bukti pembayaran: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2D2D2D),
        title: Text('Error', style: TextStyle(color: Colors.white)),
        content: Text(message, style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            child: Text('OK', style: TextStyle(color: Colors.amber[400])),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageFile == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            color: Colors.amber[400],
            size: 48,
          ),
          SizedBox(height: 8),
          Text(
            'Pilih Foto',
            style: TextStyle(
              color: Colors.amber[400],
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    return FutureBuilder<Uint8List>(
      future: _imageFile!.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[400]!),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading image',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
          );
        }

        return Container();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Upload Bukti Pembayaran',
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
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Pembayaran:',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Harga Produk: Rp${widget.totalPrice}',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
            Text(
              'Ongkir (12%): Rp$ongkir',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
            Text(
              'Total Pembayaran: Rp$totalOngkir',
              style: TextStyle(
                color: Colors.red,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Upload Bukti Pembayaran',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[400]!.withOpacity(0.5)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImagePreview(),
                ),
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : _uploadPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[400],
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Upload Bukti Pembayaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 