class Favorite {
  final String id;
  final String customerId;
  final String productId;
  final DateTime createdAt;

  Favorite({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['ID'].toString(),
      customerId: json['CustomerID'].toString(),
      productId: json['ProductID'].toString(),
      createdAt: DateTime.parse(json['CreatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'CustomerID': customerId,
      'ProductID': productId,
      'CreatedAt': createdAt.toIso8601String(),
    };
  }
}
