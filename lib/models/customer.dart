class Customer {
  final int? id;
  final String name;
  final String phone;
  final double debt;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.debt = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'debt': debt,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      debt: map['debt']?.toDouble() ?? 0.0,
    );
  }
}
