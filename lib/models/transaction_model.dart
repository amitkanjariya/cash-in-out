class TransactionModel {
  final String amount;
  final String detail;
  final String type;
  final String createdAt;
  final String contactName;
  final String contactPhone;

  TransactionModel({
    required this.amount,
    required this.detail,
    required this.type,
    required this.createdAt,
    required this.contactName,
    required this.contactPhone,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      amount: json['amount'].toString(),
      detail: json['detail'] ?? '',
      type: json['type'],
      createdAt: json['created_at'],
      contactName: json['contact_name'] ?? 'Unknown',
      contactPhone: json['contact_phone'] ?? '',
    );
  }
}
