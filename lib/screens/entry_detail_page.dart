import 'package:cashinout/screens/edit_transaction_page.dart';
import 'package:flutter/material.dart';
import '../utils/helper.dart'; // Ensure formatAmount and formatDateTimeHelper are imported

class EntryDetailPage extends StatefulWidget {
  final String transactionId;
  final String name;
  final String dateTime;
  final String amount;
  final String type;
  final String note;

  const EntryDetailPage({
    super.key,
    required this.transactionId,
    required this.name,
    required this.dateTime,
    required this.amount,
    required this.type,
    required this.note,
  });

  @override
  State<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends State<EntryDetailPage> {
  late String updatedAmount;
  late String updatedNote;
  late String updatedDateTime;

  @override
  void initState() {
    super.initState();
    updatedAmount = widget.amount;
    updatedNote = widget.note;
    updatedDateTime = widget.dateTime;
  }

  @override
  Widget build(BuildContext context) {
    final bool isGot = widget.type == 'plus';
    print("transactionId: ${widget.transactionId}");

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF497E7E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Entry Details",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(widget.name),
                subtitle: Text(formatDateTimeHelper(updatedDateTime)),
                trailing: Text(
                  '₹ ${formatAmount(updatedAmount)}',
                  style: TextStyle(
                    color: isGot ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Details", style: TextStyle(color: Colors.grey)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(updatedNote),
                ),
              ),
              const Divider(),
              InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => EditTransactionPage(
                            transactionId: widget.transactionId,
                            initialType: widget.type,
                            initialAmount: updatedAmount,
                            initialNote: updatedNote,
                            initialDate: updatedDateTime,
                          ),
                    ),
                  );

                  if (result != null && result is Map) {
                    setState(() {
                      updatedAmount = result['amount'];
                      updatedNote = result['detail'];
                      updatedDateTime = result['created_at'];
                    });
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.teal),
                      SizedBox(width: 8),
                      Text(
                        'Edit Transaction',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
