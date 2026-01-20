class PembelianModel {
  int? id;
  String fakturPemb;
  int? penjualId;
  int? productId;
  int total;
  DateTime createdAt;

  PembelianModel({
    this.id,
    required this.fakturPemb,
    this.penjualId,
    this.productId,
    required this.total,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'faktur_pemb': fakturPemb,
      'penjual_id': penjualId,
      'product_id': productId,
      'total': total,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PembelianModel.fromMap(Map<String, dynamic> map) {
    return PembelianModel(
      id: map['id'],
      fakturPemb: map['faktur_pemb'],
      penjualId: map['penjual_id'],
      productId: map['product_id'],
      total: map['total'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
