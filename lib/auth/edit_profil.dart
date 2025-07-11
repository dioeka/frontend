import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dapur_anita/konstanta.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class EditProfilPage extends StatefulWidget {
  const EditProfilPage({super.key});

  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  bool isLoading = false;
  String? profileImageUrl;
  dynamic _imageFile; // Can be File or Uint8List
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      nameController.text = prefs.getString('name') ?? '';
      emailController.text = prefs.getString('email') ?? '';
      phoneController.text = prefs.getString('phone') ?? '';
      profileImageUrl = prefs.getString('profile_image');
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          // For web, read as bytes
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _imageFile = bytes;
          });
        } else {
          // For mobile, use File
          setState(() {
            _imageFile = File(pickedFile.path);
          });
        }
      }
    } catch (e) {
      showError("Error picking image: $e");
    }
  }

  void _showImageSourceDialog() {
    if (kIsWeb) {
      // On web, directly open file picker since camera is not available
      _pickImage(ImageSource.gallery);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2D2D2D),
        title: Text('Pilih Sumber Foto', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.amber[400]),
              title: Text('Kamera', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.amber[400]),
              title: Text('Galeri', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> updateProfile() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty) {
      showError("Nama dan email harus diisi");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('id');
      
      // Use the correct API endpoint for customer updates
      final uri = Uri.parse('$baseUrl/api/customers/$userId');

      // Create form data
      var formData = {
        'name': nameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
      };

      if (kIsWeb) {
        // Handle web upload
        if (_imageFile != null) {
          // Convert Uint8List to base64
          final base64Image = base64Encode(_imageFile as Uint8List);
          formData['profile_image'] = 'data:image/jpeg;base64,$base64Image';
        }

        // Make a regular PUT request for web
        final response = await http.put(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(formData),
        );

        if (response.statusCode == 200) {
          try {
            final decodedData = json.decode(response.body);
            await _updateLocalData(decodedData);
          } catch (e) {
            throw Exception('Invalid response format from server');
          }
        } else {
          String errorMessage = 'Failed to update profile';
          try {
            final errorData = json.decode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (_) {
            // If can't parse error message, use default
          }
          throw Exception(errorMessage);
        }
      } else {
        // Handle mobile upload
        var request = http.MultipartRequest('PUT', uri);
        request.headers['Accept'] = 'application/json';
        
        // Add text fields
        request.fields.addAll(formData);

        if (_imageFile != null) {
          // For mobile, _imageFile is File
          request.files.add(
            await http.MultipartFile.fromPath(
              'profile_image',
              (_imageFile as File).path,
            ),
          );
        }

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          try {
            final decodedData = json.decode(response.body);
            await _updateLocalData(decodedData);
          } catch (e) {
            throw Exception('Invalid response format from server');
          }
        } else {
          String errorMessage = 'Failed to update profile';
          try {
            final errorData = json.decode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (_) {
            // If can't parse error message, use default
          }
          throw Exception(errorMessage);
        }
      }

      if (!mounted) return;
      showSuccess("Profil berhasil diperbarui");
    } catch (e) {
      if (!mounted) return;
      showError("Terjadi kesalahan: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _updateLocalData(Map<String, dynamic> data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', nameController.text);
    await prefs.setString('email', emailController.text);
    await prefs.setString('phone', phoneController.text);
    if (data['profile_image'] != null) {
      await prefs.setString('profile_image', data['profile_image']);
    }
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
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
        title: Text("Sukses"),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
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
          'Edit Profil',
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
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.amber[400]!,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: _buildProfileImage(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.amber[400],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Nama Lengkap',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: nameController,
              style: TextStyle(color: Colors.white),
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
            Text(
              'Email',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: emailController,
              style: TextStyle(color: Colors.white),
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
            Text(
              'Nomor Telepon',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: phoneController,
              style: TextStyle(color: Colors.white),
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
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : updateProfile,
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
                        'Simpan Perubahan',
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

  Widget _buildProfileImage() {
    if (_imageFile != null) {
      if (kIsWeb) {
        // For web, _imageFile is Uint8List
        return Image.memory(
          _imageFile as Uint8List,
          fit: BoxFit.cover,
          width: 100,
          height: 100,
        );
      } else {
        // For mobile, _imageFile is File
        return Image.file(
          _imageFile as File,
          fit: BoxFit.cover,
          width: 100,
          height: 100,
        );
      }
    } else if (profileImageUrl != null) {
      return Image.network(
        '$baseUrl/storage/$profileImageUrl',
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.person,
          size: 50,
          color: Colors.amber[400],
        ),
      );
    } else {
      return Icon(
        Icons.person,
        size: 50,
        color: Colors.amber[400],
      );
    }
  }
} 