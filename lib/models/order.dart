class OrderItem {
  final int? id;
  final String supplier; // التاجر/المورد
  final String details; // صيانة، برمجة، قطع غيار
  final double expectedCost;
  final String status; // 'تم الطلب', 'مكتمل'

  OrderItem({
    this.id,
    required this.supplier,
    required this.details,
    required this.expectedCost,
    this.status = 'تم الطلب',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier': supplier,
      'details': details,
      'expectedCost': expectedCost,
      'status': status,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      supplier: map['supplier'],
      details: map['details'],
      expectedCost: map['expectedCost']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'تم الطلب',
    );
  }
}
