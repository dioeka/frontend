class KategoriModel {
int? idKategori;
String? namaKategori;
String? deskripsiKategori;
String? createdAt;
String? updatedAt;
KategoriModel(
{this.idKategori,
this.namaKategori,
this.deskripsiKategori,
this.createdAt,
this.updatedAt});
KategoriModel.fromJson(Map<String, dynamic> json) {
idKategori = json['id_kategori'];
namaKategori = json['nama_kategori'];
deskripsiKategori = json['deskripsi_kategori'];
createdAt = json['created_at'];
updatedAt = json['updated_at'];
}
Map<String, dynamic> toJson() {
final Map<String, dynamic> data = new Map<String, dynamic>();
data['id_kategori'] = this.idKategori;
data['nama_kategori'] = this.namaKategori;
data['deskripsi_kategori'] = this.deskripsiKategori;
data['created_at'] = this.createdAt;
data['updated_at'] = this.updatedAt;
return data;
}
}