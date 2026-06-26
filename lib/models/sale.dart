class Sale {
  final int? id;
  final double total;
  final double profit;
  final String date;
  final int? customerId;

  Sale({
    this.id,
    required this.total,
    required this.profit,
    required this.date,
    this.customerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total': total,
      'profit': profit,
      'date': date,
      'customerId': customerId,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      total: map['total'],
      profit: map['profit'] ?? 0.0,
      date: map['date'],
      customerId: map['customerId'],
    );
  }
}
