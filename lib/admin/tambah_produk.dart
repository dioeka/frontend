import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:dapur_anita/konstanta.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dapur_anita/model/kategori.dart';
import 'dart:async';

class KategoriModel {
  final int idKategori;
  final String namaKategori;
  KategoriModel({required this.idKategori, required this.namaKategori});
}

class TambahProdukPage extends StatefulWidget {
  const TambahProdukPage({super.key});

  @override
  State<TambahProdukPage> createState() => _TambahProdukPageState();
}

class _TambahProdukPageState extends State<TambahProdukPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaProdukController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();
  final TextEditingController _beratController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  
  // List kategori dari API
  List<KategoriModel> kategoriList = [];
  bool kategoriLoading = true;
  KategoriModel? selectedKategori;
  bool isLoading = false;
  XFile? _imageFile;
  Uint8List? _webImage;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchKategori();
  }

  Future<void> fetchKategori() async {
    setState(() { kategoriLoading = true; });
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/kategoriApi'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          kategoriList = data.map((item) => KategoriModel(
            idKategori: int.parse(item['id_kategori'].toString()),
            namaKategori: item['nama_kategori'],
          )).toList();
        });
      } else {
        showError('Gagal memuat kategori: ${response.statusCode}');
      }
    } catch (e) {
      showError('Gagal memuat kategori: $e');
    } finally {
      setState(() { kategoriLoading = false; });
    }
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_imageFile == null && _webImage == null) {
      showError('Silakan pilih foto produk terlebih dahulu');
      return;
    }

    if (selectedKategori == null) {
      showError('Silakan pilih kategori produk');
      return;
    }

    setState(() => isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/storeApi'),
      );
      
      request.fields.addAll({
        'nama_produk': _namaProdukController.text,
        'kategori_produk': selectedKategori!.idKategori.toString(),
        'stok_produk': _stokController.text,
        'berat_produk': _beratController.text,
        'harga_produk': _hargaController.text,
        'deskripsi_produk': _deskripsiController.text,
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

      if (response.statusCode == 200) {
        if (!mounted) return;

        // Show success dialog
        await showDialog(
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
                      'Produk berhasil ditambahkan',
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
        throw Exception('Gagal menambahkan produk: ${response.statusCode}');
      }
    } catch (e) {
      showError('Gagal menambahkan produk: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildImagePreview() {
    if (_imageFile == null && _webImage == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_upload,
            color: Colors.amber[400],
            size: 48,
          ),
          SizedBox(height: 8),
          Text(
            'Upload Foto Produk',
            style: TextStyle(
              color: Colors.amber[400],
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    if (kIsWeb && _webImage != null) {
      return Image.memory(
        _webImage!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (!kIsWeb && _imageFile != null) {
      return Image.file(
        File(_imageFile!.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return SizedBox();
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
          'Tambah Barang',
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
                'Mohon Di Perhatikan Baik Baik Pengisian Form Barang',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 24),
              // Nama Produk
              TextFormField(
                controller: _namaProdukController,
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
              // Kategori Dropdown dinamis
              kategoriLoading
                  ? Center(child: CircularProgressIndicator())
                  : Container(
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
                      controller: _stokController,
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
                      controller: _beratController,
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
                controller: _hargaController,
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
                controller: _deskripsiController,
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
              // Simpan Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Simpan',
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