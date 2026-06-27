class ShortageItem {
  final int? id;
  final String name;
  final String type; // e.g., لواصق, غلافات, إكسسوارات
  final int requestedQuantity;

  ShortageItem({
    this.id,
    required this.name,
    required this.type,
    required this.requestedQuantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'requestedQuantity': requestedQuantity,
    };
  }

  factory ShortageItem.fromMap(Map<String, dynamic> map) {
    return ShortageItem(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      requestedQuantity: map['requestedQuantity'],
    );
  }
}
