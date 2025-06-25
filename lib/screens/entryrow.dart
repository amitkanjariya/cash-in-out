import 'package:flutter/material.dart';

class EntryRow extends StatelessWidget {
  final String name;
  final String date;
  final String gave;
  final String got;

  const EntryRow({
    Key? key,
    required this.name,
    required this.date,
    required this.gave,
    required this.got,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasGave = gave.isNotEmpty && gave != "0";
    final String gaveDisplay = hasGave ? "₹ $gave" : "";
    final String gotDisplay = (got.isEmpty || got == "0") ? "" : "₹ $got";

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          flex: 3,
          child: Container(
            color: Colors.red.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            alignment: Alignment.centerRight,
            child: Text(
              gaveDisplay,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),

        Expanded(
          flex: 3,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            alignment: Alignment.centerRight,
            child: Text(
              gotDisplay,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
