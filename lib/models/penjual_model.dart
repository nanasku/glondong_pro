class Penjual {
  final int? id;
  final String nama;
  final String? alamat;
  final String? telepon;
  final String? email;
  final String? createdAt;

  Penjual({
    this.id,
    required this.nama,
    this.alamat,
    this.telepon,
    this.email,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'alamat': alamat,
      'telepon': telepon,
      'email': email,
      'created_at': createdAt,
    };
  }

  factory Penjual.fromMap(Map<String, dynamic> map) {
    return Penjual(
      id: map['id'],
      nama: map['nama'],
      alamat: map['alamat'],
      telepon: map['telepon'],
      email: map['email'],
      createdAt: map['created_at'],
    );
  }
}
