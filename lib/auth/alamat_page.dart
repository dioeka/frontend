import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dapur_anita/konstanta.dart';
import 'package:dapur_anita/model/keranjang.dart';
import 'package:dapur_anita/model/payment_upload_page.dart';

class AlamatPage extends StatefulWidget {
  final List<CartItem>? cartItems;
  final int? totalPrice;
  
  const AlamatPage({
    super.key,
    this.cartItems,
    this.totalPrice,
  });

  @override
  State<AlamatPage> createState() => _AlamatPageState();
}

class _AlamatPageState extends State<AlamatPage> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();
  final TextEditingController kodeposController = TextEditingController();
  final TextEditingController telpController = TextEditingController();
  bool isLoading = false;
  bool isLoadingProvinsi = true;
  bool isLoadingKota = true;

  List<Map<String, dynamic>> provinsiList = [];
  List<Map<String, dynamic>> kotaList = [];
  Map<String, dynamic>? selectedProvinsi;
  Map<String, dynamic>? selectedKota;

  @override
  void initState() {
    super.initState();
    fetchProvinsi();
    getAlamatData();
  }

  Future<void> fetchProvinsi() async {
    setState(() => isLoadingProvinsi = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/provinsi'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          provinsiList = List<Map<String, dynamic>>.from(data);
          isLoadingProvinsi = false;
        });
      } else {
        throw Exception('Gagal memuat data provinsi');
      }
    } catch (e) {
      setState(() => isLoadingProvinsi = false);
      showError("Error memuat provinsi: $e");
    }
  }

  Future<void> fetchKota(String provinsiId) async {
    setState(() => isLoadingKota = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/kota/$provinsiId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          kotaList = List<Map<String, dynamic>>.from(data);
          isLoadingKota = false;
        });
      } else {
        throw Exception('Gagal memuat data kota');
      }
    } catch (e) {
      setState(() => isLoadingKota = false);
      showError("Error memuat kota: $e");
    }
  }

  Future<void> getAlamatData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      namaController.text = prefs.getString('nama_penerima') ?? '';
      alamatController.text = prefs.getString('alamat') ?? '';
      kodeposController.text = prefs.getString('kodepos') ?? '';
      telpController.text = prefs.getString('telp') ?? '';
      
      // Restore selected provinsi and kota if available
      String? savedProvinsiId = prefs.getString('provinsi_id');
      String? savedKotaId = prefs.getString('kota_id');
      
      if (savedProvinsiId != null) {
        fetchKota(savedProvinsiId);
      }
    });
  }

  Future<void> saveAlamat() async {
    if (namaController.text.isEmpty || alamatController.text.isEmpty || 
        selectedProvinsi == null || selectedKota == null) {
      showError("Semua field bertanda * harus diisi");
      return;
    }

    setState(() => isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('id');

      if (userId == null) {
        showError("Silakan login terlebih dahulu");
        return;
      }

      print('Saving address with data:');
      print('User ID: $userId');
      print('Nama: ${namaController.text}');
      print('Alamat: ${alamatController.text}');
      print('Provinsi: ${selectedProvinsi!['province_id']}|${selectedProvinsi!['province']}');
      print('Kota: ${selectedKota!['city_id']}|${selectedKota!['city_name']}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/saveAlamat/$userId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'nama_penerima': namaController.text,
          'alamat': alamatController.text,
          'provinsi': '${selectedProvinsi!['province_id']}|${selectedProvinsi!['province']}',
          'kota': '${selectedKota!['city_id']}|${selectedKota!['city_name']}',
          'kodepos': kodeposController.text,
          'telp': telpController.text,
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        await prefs.setString('nama_penerima', namaController.text);
        await prefs.setString('alamat', alamatController.text);
        await prefs.setString('provinsi_id', selectedProvinsi!['province_id'].toString());
        await prefs.setString('provinsi_nama', selectedProvinsi!['province']);
        await prefs.setString('kota_id', selectedKota!['city_id'].toString());
        await prefs.setString('kota_nama', selectedKota!['city_name']);
        await prefs.setString('kodepos', kodeposController.text);
        await prefs.setString('telp', telpController.text);

        if (!mounted) return;
        
        if (widget.cartItems != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentUploadPage(
                cartItems: widget.cartItems!,
                totalPrice: widget.totalPrice!,
                alamat: {
                  'nama_penerima': namaController.text,
                  'alamat': alamatController.text,
                  'provinsi': selectedProvinsi!['province'],
                  'kota': selectedKota!['city_name'],
                  'kodepos': kodeposController.text,
                  'telp': telpController.text,
                },
              ),
            ),
          );
        } else {
          showSuccess("Alamat berhasil disimpan");
        }
      } else {
        final errorData = json.decode(response.body);
        showError(errorData['message'] ?? "Gagal menyimpan alamat");
      }
    } catch (e) {
      print('Error saving address: $e');
      showError("Terjadi kesalahan: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2D2D2D),
        title: Text("Error", style: TextStyle(color: Colors.white)),
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

  void showSuccess(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2D2D2D),
        title: Text("Sukses", style: TextStyle(color: Colors.white)),
        content: Text(message, style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            child: Text('OK', style: TextStyle(color: Colors.amber[400])),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to profile page
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Color(0xFF2D2D2D),
        title: Text(
          widget.cartItems != null ? 'Alamat Pengiriman' : 'Pengaturan Alamat',
          style: TextStyle(color: Colors.amber[400]),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.amber[400]),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputField(
              label: 'Nama Penerima',
              controller: namaController,
              required: true,
            ),
            _buildDropdownField(
              label: 'Provinsi',
              required: true,
              isLoading: isLoadingProvinsi,
              value: selectedProvinsi,
              items: provinsiList.map((provinsi) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: provinsi,
                  child: Text(
                    provinsi['province'],
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedProvinsi = value as Map<String, dynamic>?;
                  selectedKota = null;
                  if (selectedProvinsi != null) {
                    fetchKota(selectedProvinsi!['province_id'].toString());
                  }
                });
              },
            ),
            _buildDropdownField(
              label: 'Kota / Kabupaten',
              required: true,
              isLoading: isLoadingKota,
              value: selectedKota,
              items: kotaList.map((kota) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: kota,
                  child: Text(
                    kota['city_name'],
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: selectedProvinsi == null
                  ? null
                  : (value) {
                      setState(() {
                        selectedKota = value as Map<String, dynamic>?;
                      });
                    },
            ),
            _buildInputField(
              label: 'Kode Pos',
              controller: kodeposController,
              keyboardType: TextInputType.number,
            ),
            _buildInputField(
              label: 'Nomor Telepon',
              controller: telpController,
              keyboardType: TextInputType.phone,
            ),
            _buildInputField(
              label: 'Alamat Lengkap',
              controller: alamatController,
              required: true,
              maxLines: 3,
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveAlamat,
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
                        'Simpan Alamat',
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

  Widget _buildDropdownField({
    required String label,
    required bool isLoading,
    required Map<String, dynamic>? value,
    required List<DropdownMenuItem<Map<String, dynamic>>> items,
    required Function(Map<String, dynamic>?)? onChanged,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber[400]!),
          ),
          child: isLoading
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[400]!),
                    ),
                  ),
                )
              : DropdownButton<Map<String, dynamic>>(
                  value: value,
                  isExpanded: true,
                  dropdownColor: Colors.grey[900],
                  underline: Container(),
                  hint: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Pilih $label',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                  items: items,
                  onChanged: onChanged,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.amber[400]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.amber[400]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.amber[400]!, width: 2),
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
} 