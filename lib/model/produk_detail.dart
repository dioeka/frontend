import 'package:flutter/material.dart';
import 'package:dapur_anita/konstanta.dart';
import 'package:dapur_anita/model/produk.dart';
import 'package:dapur_anita/model/keranjang.dart';

class SuccessDialog extends StatefulWidget {
  const SuccessDialog({Key? key}) : super(key: key);

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.6, 1.0, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
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
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Transform.scale(
                        scale: _checkAnimation.value,
                        child: Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      children: [
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
                          'Produk telah ditambahkan ke keranjang',
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
                            Navigator.pop(context); // Go back to previous screen
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ProdukDetailPage extends StatefulWidget {
  final ProdukResponModel produk;

  const ProdukDetailPage({
    super.key,
    required this.produk,
  });

  @override
  State<ProdukDetailPage> createState() => _ProdukDetailPageState();
}

class _ProdukDetailPageState extends State<ProdukDetailPage> {
  int quantity = 1;
  bool isLoading = false;

  void incrementQuantity() {
    if (quantity < (widget.produk.stok ?? 0)) {
      setState(() {
        quantity++;
      });
    }
  }

  void decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  Future<void> handleAddToCart() async {
    setState(() {
      isLoading = true;
    });

    try {
      final success = await addToCart(
        context,
        widget.produk.idProduk!,
        quantity,
      );

      if (success) {
        setState(() {
          isLoading = false;
        });
        
        // Show animated success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => SuccessDialog(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Detail Produk', style: TextStyle(color: Colors.red)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.red),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                image: DecorationImage(
                  image: NetworkImage(
                    '$gambarUrl/produk/${widget.produk.fotoProduk}',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: Text(
                      'Nastar Nanas',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    widget.produk.namaProduk ?? '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Rp ${widget.produk.hargaProduk}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[400],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Deskripsi:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'enak bangett njirr',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Sekilas Info:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    'Pesanan Akan Langsung Di buat apabila ada pesanan',
                  ),
                  _buildInfoItem(
                    'Pembuatan Pesanan Berdasarkan First Order First Serve',
                  ),
                  _buildInfoItem(
                    'Jaminan Kualitas Bahan dan Proses Pembuatan',
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Text(
                        'Stok: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${widget.produk.stok}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF2D2D2D),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber[400]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[900],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: decrementQuantity,
                    icon: Icon(Icons.remove, color: Colors.amber[400]),
                    padding: const EdgeInsets.all(4),
                  ),
                  Text(
                    '$quantity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: incrementQuantity,
                    icon: Icon(Icons.add, color: Colors.amber[400]),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: isLoading ? null : handleAddToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[400],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Masukan Keranjang',
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

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.amber[400],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 