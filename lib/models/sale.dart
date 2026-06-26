class Sale {
  final int? id;
  final double total;
  final String date;

  Sale({
    this.id,
    required this.total,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total': total,
      'date': date,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      total: map['total'],
      date: map['date'],
    );
  }
}
