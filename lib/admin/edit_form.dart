import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dapur_anita/konstanta.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dapur_anita/model/kategori.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';

class KategoriModel {
  final int idKategori;
  final String namaKategori;
  KategoriModel({required this.idKategori, required this.namaKategori});
}

class EditForm extends StatefulWidget {
  final String idBarang;

  const EditForm({super.key, required this.idBarang});

  @override
  State<EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<EditForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController namaProdukController = TextEditingController();
  final TextEditingController hargaProdukController = TextEditingController();
  final TextEditingController stokController = TextEditingController();
  final TextEditingController beratController = TextEditingController();
  final TextEditingController deskripsiController = TextEditingController();
  
  // List kategori statis
  List<KategoriModel> kategoriList = [
    KategoriModel(idKategori: 1, namaKategori: 'Daging Ayam'),
    KategoriModel(idKategori: 2, namaKategori: 'Daging Kambing'),
    KategoriModel(idKategori: 3, namaKategori: 'Daging Sapi'),
  ];
  KategoriModel? selectedKategori;
  bool isLoading = false;
  XFile? _imageFile;
  Uint8List? _webImage;
  final picker = ImagePicker();
  String? existingImage;

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/editApi/${widget.idBarang}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final produkData = data is Map && data.containsKey('user') ? data['user'] : data;
        if (produkData == null) {
          throw Exception('Data produk tidak ditemukan');
        }
        setState(() {
          namaProdukController.text = produkData['nama_produk']?.toString() ?? '';
          hargaProdukController.text = produkData['harga_produk']?.toString() ?? '';
          stokController.text = produkData['stok']?.toString() ?? '';
          beratController.text = produkData['berat']?.toString() ?? '';
          deskripsiController.text = produkData['deskripsi_produk']?.toString() ?? '';
          existingImage = produkData['foto_produk']?.toString();
          // Set selected kategori dari kategoriList statis
          final kategoriId = int.tryParse(produkData['id_kategori'].toString());
          if (kategoriId != null && kategoriList.isNotEmpty) {
            selectedKategori = kategoriList.firstWhere(
              (kategori) => kategori.idKategori == kategoriId,
              orElse: () => kategoriList.first,
            );
          }
        });
      } else {
        throw Exception('Gagal memuat data produk. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        showError('Gagal memuat data produk: ${e.toString()}');
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        if (kIsWeb) {
          var bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _imageFile = pickedFile;
          });
        } else {
          setState(() {
            _imageFile = pickedFile;
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      showError('Gagal memilih gambar');
    }
  }

  Widget _buildImagePreview() {
    if (_imageFile == null && _webImage == null && existingImage != null) {
      return Stack(
        children: [
          Image.network(
            '$baseUrl/produk/$existingImage',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'Gagal memuat gambar',
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap untuk memilih gambar baru',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              );
            },
            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              );
            },
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: EdgeInsets.all(4),
              child: Text(
                'Tap untuk mengubah',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_imageFile == null && _webImage == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload, color: Colors.red, size: 48),
          SizedBox(height: 8),
          Text(
            'Upload Foto Produk',
            style: TextStyle(color: Colors.red),
          ),
          SizedBox(height: 4),
          Text(
            'Tap untuk memilih gambar',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      );
    }

    if (kIsWeb && _webImage != null) {
      return Stack(
        children: [
          Image.memory(
            _webImage!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: EdgeInsets.all(4),
              child: Text(
                'Gambar baru dipilih',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (!kIsWeb && _imageFile != null) {
      return Stack(
        children: [
          Image.file(
            File(_imageFile!.path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: EdgeInsets.all(4),
              child: Text(
                'Gambar baru dipilih',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox();
  }

  Future<void> updateData() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (selectedKategori == null) {
      showError('Silakan pilih kategori produk');
      return;
    }

    setState(() => isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/updateApi/${widget.idBarang}'),
      );
      
      request.fields.addAll({
        'nama_produk': namaProdukController.text,
        'kategori_produk': selectedKategori!.idKategori.toString(),
        'stok_produk': stokController.text,
        'berat_produk': beratController.text,
        'harga_produk': hargaProdukController.text,
        'deskripsi_produk': deskripsiController.text,
        'foto_lama': existingImage ?? '',
        '_method': 'PUT',
      });

      if (kIsWeb) {
        if (_webImage != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'img1',
              _webImage!,
              filename: 'product_image.jpg',
            ),
          );
        }
      } else {
        if (_imageFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'img1',
              _imageFile!.path,
            ),
          );
        }
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      print('Response body: $responseData');

      if (response.statusCode == 200) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 48,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Berhasil!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Produk berhasil diperbarui',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[400],
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context, true); // Return to previous screen with refresh flag
                      },
                      child: Text(
                        'Kembali',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        showError('Gagal memperbarui produk: $responseData');
      }
    } catch (e) {
      showError('Gagal memperbarui produk: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Edit Produk',
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Data Produk',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 24),
              
              // Nama Produk
              TextFormField(
                controller: namaProdukController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Nama Produk',
                  labelStyle: TextStyle(color: Colors.red),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama produk tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Kategori Dropdown statis
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<KategoriModel>(
                    dropdownColor: Colors.white,
                    isExpanded: true,
                    value: selectedKategori,
                    hint: Text(
                      'Pilih Kategori Produk',
                      style: TextStyle(color: Colors.red),
                    ),
                    items: kategoriList.map((KategoriModel kategori) {
                      return DropdownMenuItem<KategoriModel>(
                        value: kategori,
                        child: Text(
                          kategori.namaKategori,
                          style: TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),
                    onChanged: (KategoriModel? newValue) {
                      setState(() {
                        selectedKategori = newValue;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Stok dan Berat dalam satu row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: stokController,
                      style: TextStyle(color: Colors.black),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Stok Produk',
                        labelStyle: TextStyle(color: Colors.red),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Stok tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: beratController,
                      style: TextStyle(color: Colors.black),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Berat (gram)',
                        labelStyle: TextStyle(color: Colors.red),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Berat tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Harga Produk
              TextFormField(
                controller: hargaProdukController,
                style: TextStyle(color: Colors.black),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Harga Produk',
                  labelStyle: TextStyle(color: Colors.red),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Deskripsi Produk
              TextFormField(
                controller: deskripsiController,
                style: TextStyle(color: Colors.black),
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Deskripsi Produk',
                  labelStyle: TextStyle(color: Colors.red),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deskripsi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Upload Foto Button
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImagePreview(),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : updateData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Update',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}