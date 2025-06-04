import 'package:flutter/material.dart';

class EntryDetailCard extends StatelessWidget {
  final String date;
  final String gave;
  final String got;
  final String balance;
  final String? note;

  const EntryDetailCard({
    Key? key,
    required this.date,
    required this.gave,
    required this.got,
    required this.balance,
    this.note,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gaveAmount = gave.isNotEmpty ? gave : null;
    final gotAmount = got.isNotEmpty ? got : null;
    final balanceValue = double.tryParse(balance) ?? 0.0;

    Color balanceColor = Colors.grey;
    if (balanceValue > 0) {
      balanceColor = Colors.green;
    } else if (balanceValue < 0) {
      balanceColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date & Balance Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                Text(
                  'Balance: ₹$balance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: balanceColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Gave / Got amounts
            Row(
              children: [
                if (gaveAmount != null) ...[
                  Chip(
                    label: Text(
                      'Gave: ₹$gaveAmount',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                ],
                if (gotAmount != null) ...[
                  if (gaveAmount != null) const SizedBox(width: 12),
                  Chip(
                    label: Text(
                      'Got: ₹$gotAmount',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                  ),
                ],
              ],
            ),
            if (note != null && note!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Note:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(note!, style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }
}
