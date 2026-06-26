class StoreInfo {
  final int? id;
  final String name;
  final String? logoPath;
  final String phone;
  final String address;
  final String welcomeMessage;

  StoreInfo({
    this.id,
    required this.name,
    this.logoPath,
    required this.phone,
    required this.address,
    required this.welcomeMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoPath': logoPath,
      'phone': phone,
      'address': address,
      'welcomeMessage': welcomeMessage,
    };
  }

  factory StoreInfo.fromMap(Map<String, dynamic> map) {
    return StoreInfo(
      id: map['id'],
      name: map['name'],
      logoPath: map['logoPath'],
      phone: map['phone'],
      address: map['address'],
      welcomeMessage: map['welcomeMessage'],
    );
  }
}
