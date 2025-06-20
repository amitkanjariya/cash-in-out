import 'package:cashinout/screens/homepage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cashinout/utils/constants.dart';

class YouGavePage extends StatefulWidget {
  final String? name;
  final String? phone;
  final String? customerId;
  const YouGavePage({super.key, this.name, this.phone, this.customerId});

  @override
  State<YouGavePage> createState() => _YouGavePageState();
}

class _YouGavePageState extends State<YouGavePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
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
        'type': 'minus',
        'created_at': _selectedDate.toIso8601String(),
      };

      // Add customer ID if available
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
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

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Add this method for month name
  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('You Gave ₹', style: TextStyle(color: Colors.white)),
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
                labelText: ' Details (Optional)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF4F4F4),
              ),
            ),
            const SizedBox(height: 10),

            // 📅 Date Picker Button
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: _pickDate,
                icon: Icon(Icons.calendar_month, color: Colors.red),
                label: Text(
                  '${_selectedDate.day} ${_monthName(_selectedDate.month)}, ${_selectedDate.year.toString().substring(2)}',
                  style: const TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  side: BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isLoading ? null : _submitTransaction,
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF468585), // 👈 your custom color
                        ),
                      )
                      : const Text(
                        'Done',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
