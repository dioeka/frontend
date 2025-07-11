import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:dapur_anita/konstanta.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;

  Future<void> register() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      showError("Semua field harus diisi");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      showError("Password tidak cocok");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      print('Sending registration request to: $apiUrl/register');
      print('Request data: ${nameController.text}, ${emailController.text}');
      
      final response = await http.post(
        Uri.parse('$apiUrl/register'),
        headers: {
          'Accept': 'application/json',
        },
        body: {
          'name': nameController.text,
          'email': emailController.text,
          'password': passwordController.text,
          'password_confirmation': confirmPasswordController.text,
        }
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (!mounted) return;
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Registrasi Berhasil"),
            content: const Text("Silakan login dengan akun yang telah dibuat"),
            actions: [
              TextButton(
                child: const Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      } else {
        final responseData = json.decode(response.body);
        String errorMessage = "Gagal mendaftar";
        
        if (responseData is Map) {
          if (responseData.containsKey('errors')) {
            final errors = responseData['errors'];
            if (errors is Map) {
              errorMessage = errors.values.first.first ?? "Validasi gagal";
            } else if (responseData.containsKey('message')) {
              errorMessage = responseData['message'];
            }
          } else if (responseData.containsKey('message')) {
            errorMessage = responseData['message'];
          }
        }
        
        showError(errorMessage);
      }
    } on TimeoutException {
      showError("Koneksi timeout. Periksa koneksi internet Anda");
    } catch (e) {
      showError("Terjadi kesalahan: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Registrasi Gagal"),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Ok'),
            onPressed: () => Navigator.of(context).pop(),
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
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo1.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text(
                  'Daftar Akun Baru',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Silakan isi data di bawah ini',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nama Lengkap',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameController,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama lengkap',
                        hintStyle: TextStyle(color: Colors.red[200]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: emailController,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Masukkan email',
                        hintStyle: TextStyle(color: Colors.red[200]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: passwordController,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Masukkan password',
                        hintStyle: TextStyle(color: Colors.red[200]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Konfirmasi Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: confirmPasswordController,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Masukkan ulang password',
                        hintStyle: TextStyle(color: Colors.red[200]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      obscureText: true,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isLoading)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        else ...[
                          const Text(
                            'Daftar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
