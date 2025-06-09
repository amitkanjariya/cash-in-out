import 'dart:convert';
import 'dart:typed_data';
import 'package:cashinout/utils/helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cashinout/utils/constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CustomerReportPage extends StatefulWidget {
  final String customerId;
  final String userId;

  const CustomerReportPage({
    super.key,
    required this.customerId,
    required this.userId,
  });

  @override
  State<CustomerReportPage> createState() => _CustomerReportPageState();
}

class _CustomerReportPageState extends State<CustomerReportPage> {
  String customerName = 'Loading...';
  List<Map<String, dynamic>> entries = [];
  double totalGave = 0.0;
  double totalGot = 0.0;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    fetchCustomerDetails();
    fetchCustomerEntries();
  }

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => startDate = picked);
      fetchCustomerEntries();
    }
  }

  Future<void> pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => endDate = picked);
      fetchCustomerEntries();
    }
  }

  Future<void> fetchCustomerDetails() async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/get_customer_details.php'),
        body: {'user_id': widget.userId, 'customer_id': widget.customerId},
      );

      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success'] == true) {
        final data = jsonResponse['data'];
        setState(() => customerName = data['name'] ?? 'No Name');
      } else {
        setState(() => customerName = 'Error loading');
      }
    } catch (e) {
      setState(() => customerName = 'Failed to load');
    }
  }

  Future<void> fetchCustomerEntries() async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/get_customer_transactions.php'),
        body: {'user_id': widget.userId, 'customer_id': widget.customerId},
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true && data['data'] is List) {
        List<Map<String, dynamic>> filtered = [];
        double gave = 0.0, got = 0.0, balance = 0.0;
        final List transactions = data['data'];

        for (var i = transactions.length - 1; i >= 0; i--) {
          var item = transactions[i];
          String createdAt = item['created_at'] ?? '';
          DateTime entryDate = DateTime.tryParse(createdAt) ?? DateTime.now();

          if (startDate != null && entryDate.isBefore(startDate!)) continue;
          if (endDate != null &&
              entryDate.isAfter(endDate!.add(const Duration(days: 1))))
            continue;

          String type = item['type'] ?? '';
          String amountStr = item['amount'] ?? '0';
          double amount = double.tryParse(amountStr) ?? 0.0;

          String entryGave = '', entryGot = '';
          if (type == 'plus') {
            entryGot = amountStr;
            got += amount;
            balance += amount;
          } else if (type == 'minus') {
            entryGave = amountStr;
            gave += amount;
            balance -= amount;
          }

          filtered.insert(0, {
            'date': createdAt,
            'gave': entryGave,
            'got': entryGot,
            'balance': balance.toStringAsFixed(2),
            'note': item['detail'] ?? '',
          });
        }

        setState(() {
          entries = filtered;
          totalGave = gave;
          totalGot = got;
        });
      } else {
        setState(() {
          entries = [];
          totalGave = 0;
          totalGot = 0;
        });
      }
    } catch (e) {
      setState(() {
        entries = [];
        totalGave = 0;
        totalGot = 0;
      });
    }
  }

  Future<Uint8List> generatePdf() async {
    final pdf = pw.Document();
    final netBalance = totalGot - totalGave;

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Customer Report: $customerName',
                  style: pw.TextStyle(fontSize: 18),
                ),
              ),
              pw.Text('Net Balance: Rs. ${netBalance.toStringAsFixed(2)}'),
              pw.Text('Total Gave: Rs. ${totalGave.toStringAsFixed(2)}'),
              pw.Text('Total Got: Rs. ${totalGot.toStringAsFixed(2)}'),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Date', 'Gave', 'Got', 'Balance', 'Note'],
                data:
                    entries.map((e) {
                      return [
                        e['date'],
                        e['gave'],
                        e['got'],
                        e['balance'],
                        e['note'],
                      ];
                    }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                border: pw.TableBorder.all(width: 0.5),
              ),
            ],
      ),
    );

    return pdf.save();
  }

  Future<void> downloadPdf() async {
    final pdfBytes = await generatePdf();
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }

  Future<void> sharePdf() async {
    final pdfBytes = await generatePdf();
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'report_${customerName.replaceAll(" ", "_")}.pdf',
    );
  }

  String formatDateOnly(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    double netBalance = totalGot - totalGave;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        title: Text('Report of $customerName'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // date filter
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: pickStartDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      startDate == null
                          ? "START DATE"
                          : formatDateOnly(startDate!),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: pickEndDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      endDate == null ? "END DATE" : formatDateOnly(endDate!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Net Balance', style: TextStyle(fontSize: 18)),
                Text(
                  '₹ ${netBalance.abs().toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18,
                    color: netBalance >= 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Totals
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'TOTAL\n${entries.length} Entries',
                  style: const TextStyle(fontSize: 12),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'YOU GAVE',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                    Text(
                      '₹ ${totalGave.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'YOU GOT',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                    Text(
                      '₹ ${totalGot.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Entry headers
          Container(
            color: Colors.grey[300],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: const [
                Expanded(flex: 2, child: Text('Date')),
                Expanded(child: Text('You Gave', textAlign: TextAlign.right)),
                Expanded(child: Text('You Got', textAlign: TextAlign.right)),
              ],
            ),
          ),
          // Entry list
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final e = entries[index];
                return Container(
                  color: index % 2 == 0 ? Colors.white : Colors.grey[100],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formatDateTimeHelper(e['date'])),
                            Text(
                              'Bal. ₹ ${e['balance']}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    double.parse(e['balance']) >= 0
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e['gave'].isNotEmpty ? '₹ ${e['gave']}' : '',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e['got'].isNotEmpty ? '₹ ${e['got']}' : '',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('DOWNLOAD'),
                    onPressed: downloadPdf,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('SHARE'),
                    onPressed: sharePdf,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
