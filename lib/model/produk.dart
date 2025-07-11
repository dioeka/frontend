class produk {
  int? idProduk;
  String? namaProduk;
  int? idKategori;
  String? berat;
  int? stok;
  int? hargaProduk;
  String? deskripsiProduk;
  String? fotoProduk;
  String? createdAt;
  String? updatedAt;
  String? namaKategori;

  produk(
      {this.idProduk,
      this.namaProduk,
      this.idKategori,
      this.berat,
      this.stok,
      this.hargaProduk,
      this.deskripsiProduk,
      this.fotoProduk,
      this.createdAt,
      this.updatedAt,
      this.namaKategori});

  produk.fromJson(Map<String, dynamic> json) {
    idProduk = json['id_produk'];
    namaProduk = json['nama_produk'];
    idKategori = json['id_kategori'];
    berat = json['berat'];
    stok = json['stok'];
    hargaProduk = json['harga_produk'];
    deskripsiProduk = json['deskripsi_produk'];
    fotoProduk = json['foto_produk'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    namaKategori = json['nama_kategori'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id_produk'] = this.idProduk;
    data['nama_produk'] = this.namaProduk;
    data['id_kategori'] = this.idKategori;
    data['berat'] = this.berat;
    data['stok'] = this.stok;
    data['harga_produk'] = this.hargaProduk;
    data['deskripsi_produk'] = this.deskripsiProduk;
    data['foto_produk'] = this.fotoProduk;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['nama_kategori'] = this.namaKategori;
    return data;
  }
}

class ProdukResponModel {
  final int? idProduk;
  final String? namaProduk;
  final int? hargaProduk;
  final int? stok;
  final String? fotoProduk;

  ProdukResponModel({
    this.idProduk,
    this.namaProduk,
    this.hargaProduk,
    this.stok,
    this.fotoProduk,
  });

  factory ProdukResponModel.fromJson(Map<String, dynamic> json) {
    return ProdukResponModel(
      idProduk: json['id_produk'],
      namaProduk: json['nama_produk'],
      hargaProduk: json['harga_produk'],
      stok: json['stok'],
      fotoProduk: json['foto_produk'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_produk': idProduk,
      'nama_produk': namaProduk,
      'harga_produk': hargaProduk,
      'stok': stok,
      'foto_produk': fotoProduk,
    };
  }
}