import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cashinout/utils/constants.dart';

class YouGotPage extends StatefulWidget {
  final String? name;
  final String? phone;
  final String? customerId;
  const YouGotPage({super.key, this.name, this.phone, this.customerId});

  @override
  State<YouGotPage> createState() => _YouGotPageState();
}

class _YouGotPageState extends State<YouGotPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitTransaction() async {
    final amount = _amountController.text.trim();
    final detail = _detailsController.text.trim();
    final customerPhone = widget.phone?.trim() ?? '';
    final customerName = widget.name?.trim() ?? '';
    final customerId = widget.customerId?.trim() ?? '';

    if (amount.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter an amount')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('phone');

      if (userPhone == null || userPhone.length != 10) {
        throw Exception('Logged-in user phone not found or invalid.');
      }

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/get_user_id_by_phone.php'),
        body: {'phone': userPhone},
      );

      final idData = jsonDecode(response.body);
      if (idData['success'] != true) {
        throw Exception('Failed to get user ID: ${idData['message']}');
      }

      final userId = idData['user_id'].toString();

      // Only add customer if both name and phone are present
      if (customerPhone.isNotEmpty && customerName.isNotEmpty) {
        final customerResponse = await http.post(
          Uri.parse('${Constants.baseUrl}/add_customer_contact.php'),
          body: {
            'user_id': userId,
            'phone': customerPhone,
            'name': customerName,
          },
        );

        final customerResult = jsonDecode(customerResponse.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(customerResult['message'] ?? 'Customer added'),
          ),
        );

        if (customerResult['success'] != true) {
          throw Exception(
            'Failed to add customer: ${customerResult['message']}',
          );
        }
      }

      final body = {
        'user_id': userId,
        'amount': amount,
        'detail': detail,
        'type': 'plus',
      };

      // Include customer ID if available
      if (customerId.isNotEmpty) {
        body['customer_id'] = customerId;
      }

      if (customerPhone.isNotEmpty) {
        body['customer_phone'] = customerPhone;
      }

      // Add transaction
      final transactionResponse = await http.post(
        Uri.parse('${Constants.baseUrl}/add_transaction.php'),
        body: body,
      );

      final transactionResult = jsonDecode(transactionResponse.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(transactionResult['message'] ?? 'Transaction saved'),
        ),
      );

      if (transactionResult['success'] == true) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.greenAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('You Got ₹', style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: '₹ Enter Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF4F4F4),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(
                labelText: 'Details (Optional)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF4F4F4),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _isLoading ? null : _submitTransaction,
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                        'Done',
                        style: TextStyle(color: Colors.black),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
