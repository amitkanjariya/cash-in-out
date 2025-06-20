import 'package:cashinout/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditTransactionPage extends StatefulWidget {
  final String transactionId;
  final String initialType;
  final String initialAmount;
  final String initialNote;
  final String initialDate;

  const EditTransactionPage({
    super.key,
    required this.transactionId,
    required this.initialType,
    required this.initialAmount,
    required this.initialNote,
    required this.initialDate,
  });

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late String _transactionType;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.initialAmount);
    _noteController = TextEditingController(text: widget.initialNote);
    _selectedDate = DateTime.parse(widget.initialDate);
    _transactionType = widget.initialType;

    _amountController.addListener(() {
      setState(() {}); // Rebuilds to reflect amount change in AppBar title
    });
  }

  void _saveTransaction() async {
    final amountText = _amountController.text.trim();
    final noteText = _noteController.text.trim();
    final dateText = _selectedDate.toIso8601String().substring(0, 10);

    if (amountText.isEmpty || double.tryParse(amountText) == 0) {
      _showError("Please enter a valid amount greater than 0");
      return;
    }

    final originalAmount = widget.initialAmount.trim();
    final originalNote = widget.initialNote.trim();
    final originalDate = widget.initialDate.substring(0, 10);

    if (amountText == originalAmount &&
        noteText == originalNote &&
        dateText == originalDate) {
      _showError("Please make a change before saving");
      return;
    }

    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/update_transaction.php'),
      body: {
        'transaction_id': widget.transactionId,
        'amount': amountText,
        'detail': noteText,
        'created_at': dateText,
      },
    );

    try {
      final result = json.decode(response.body);
      if (result['success'] == true) {
        Navigator.pop(context);
        Navigator.pop(context);
      } else {
        _showError(result['message']);
      }
    } catch (e) {
      _showError("Unexpected response from server: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpense = _transactionType == 'minus';
    final Color primaryColor = isExpense ? Colors.red : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${isExpense ? "Expense" : "Income"} - ₹ ${_amountController.text}',
          style: TextStyle(color: primaryColor),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: primaryColor),
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                prefixText: "₹ ",
                prefixStyle: TextStyle(color: primaryColor, fontSize: 20),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryColor),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: "Detail",
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryColor),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: _pickDate,
                icon: Icon(Icons.calendar_month, color: primaryColor),
                label: Text(
                  '${_selectedDate.day} ${_monthName(_selectedDate.month)}, ${_selectedDate.year.toString().substring(2)}',
                  style: const TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  side: BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Save",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const List<String> months = [
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
    return months[month - 1];
  }
}
