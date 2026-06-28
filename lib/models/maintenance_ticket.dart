class MaintenanceTicket {
  final int? id;
  final String customerName;
  final String customerPhone;
  final String deviceModel;
  final String imei;
  final String passcode;
  final String taskType; // Software / Hardware
  final String accessories; // comma separated
  final double estimatedCost;
  final String initialNotes;
  final String status; // Received, In Progress, Awaiting Approval, Ready, Cannot be fixed, Delivered
  final String dateReceived;

  MaintenanceTicket({
    this.id,
    required this.customerName,
    required this.customerPhone,
    required this.deviceModel,
    required this.imei,
    required this.passcode,
    required this.taskType,
    required this.accessories,
    required this.estimatedCost,
    required this.initialNotes,
    required this.status,
    required this.dateReceived,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deviceModel': deviceModel,
      'imei': imei,
      'passcode': passcode,
      'taskType': taskType,
      'accessories': accessories,
      'estimatedCost': estimatedCost,
      'initialNotes': initialNotes,
      'status': status,
      'dateReceived': dateReceived,
    };
  }

  factory MaintenanceTicket.fromMap(Map<String, dynamic> map) {
    return MaintenanceTicket(
      id: map['id'],
      customerName: map['customerName'],
      customerPhone: map['customerPhone'],
      deviceModel: map['deviceModel'],
      imei: map['imei'],
      passcode: map['passcode'],
      taskType: map['taskType'],
      accessories: map['accessories'],
      estimatedCost: map['estimatedCost'] is int ? (map['estimatedCost'] as int).toDouble() : map['estimatedCost'],
      initialNotes: map['initialNotes'],
      status: map['status'],
      dateReceived: map['dateReceived'],
    );
  }
}
