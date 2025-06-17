import 'package:cashinout/screens/edit_transaction_page.dart';
import 'package:flutter/material.dart';
import '../utils/helper.dart';

class EntryDetailPage extends StatefulWidget {
  final String transactionId;
  final String name;
  final String dateTime;
  final String amount;
  final String type;
  final String note;
  final String? profileImageUrl;

  const EntryDetailPage({
    super.key,
    required this.transactionId,
    required this.name,
    required this.dateTime,
    required this.amount,
    required this.type,
    required this.note,
    this.profileImageUrl,
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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
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
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.teal.shade100,
                    backgroundImage:
                        widget.profileImageUrl != null &&
                                widget.profileImageUrl!.isNotEmpty
                            ? NetworkImage(widget.profileImageUrl!)
                            : null,
                    child:
                        widget.profileImageUrl == null ||
                                widget.profileImageUrl!.isEmpty
                            ? const Icon(Icons.person, color: Colors.teal)
                            : null,
                  ),

                  title: Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    formatDateTimeHelper(updatedDateTime),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Text(
                    '₹ ${formatAmount(updatedAmount)}',
                    style: TextStyle(
                      color: isGot ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Note",
                    style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    updatedNote.isNotEmpty ? updatedNote : "(No details)",
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const Divider(height: 32),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.edit, color: Colors.teal),
                        SizedBox(width: 10),
                        Text(
                          'Edit Transaction',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
