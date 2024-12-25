class CartItem {
  final String id;
  final String customerId;
  final String productId;
  int quantity;
  final DateTime createdAt;

  CartItem({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.quantity,
    required this.createdAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['ID'].toString(),
      customerId: json['CustomerID'].toString(),
      productId: json['ProductID'].toString(),
      quantity: json['Quantity'] as int,
      createdAt: DateTime.parse(json['CreatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'CustomerID': customerId,
      'ProductID': productId,
      'Quantity': quantity,
      'CreatedAt': createdAt.toIso8601String(),
    };
  }
}
