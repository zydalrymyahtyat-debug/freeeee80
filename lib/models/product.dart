class Product {
  final int? id;
  final String name;
  final double price;
  final double cost;
  final int quantity;
  final int minQuantity;
  final String? barcode;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.cost,
    required this.quantity,
    this.minQuantity = 0,
    this.barcode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'cost': cost,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'barcode': barcode,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      cost: map['cost'],
      quantity: map['quantity'],
      minQuantity: map['minQuantity'] ?? 0,
      barcode: map['barcode'],
    );
  }
}
