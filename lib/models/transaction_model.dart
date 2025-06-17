import 'package:cashinout/utils/constants.dart';

class TransactionModel {
  final String amount;
  final String detail;
  final String type;
  final String createdAt;
  final String contactId;
  final String contactName;
  final String contactPhone;
  final String contactProfileImage;

  TransactionModel({
    required this.amount,
    required this.detail,
    required this.type,
    required this.createdAt,
    required this.contactId,
    required this.contactName,
    required this.contactPhone,
    required this.contactProfileImage,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      amount: json['amount'].toString(),
      detail: json['detail'] ?? '',
      type: json['type'],
      createdAt: json['created_at'],
      contactId: json['to_id']?.toString() ?? '',
      contactName: json['contact_name'] ?? 'Unknown',
      contactPhone: json['contact_phone'] ?? '',
      contactProfileImage:
          json['contact_profile_image'] != null &&
                  json['contact_profile_image'].toString().isNotEmpty
              ? '${Constants.baseUrl}/upload/${json['contact_profile_image']}'
              : '',
    );
  }
}
