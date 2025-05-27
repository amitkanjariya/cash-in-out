// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';

// Future<Map<String, dynamic>> fetchReportData(
//   String phone,
//   String? startDate,
//   String? endDate,
// ) async {
//   final response = await http.post(
//     Uri.parse('https://yourdomain.com/get_report.php'),
//     body: {
//       'phone': phone,
//       'start_date': startDate ?? '',
//       'end_date': endDate ?? '',
//     },
//   );

//   if (response.statusCode == 200) {
//     return json.decode(response.body);
//   } else {
//     throw Exception('Failed to load report');
//   }
// }

// class ReportPage extends StatefulWidget {
//   const ReportPage({super.key});

//   @override
//   State<ReportPage> createState() => _ReportPageState();
// }

// class _ReportPageState extends State<ReportPage> {

//   String netBalance = '';
//   List<dynamic> entries = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     fetchData();
//   }

//   void fetchData() async {
//     final data = await fetchReportData(
//       '1234567890',
//       startDate?.toIso8601String().substring(0, 10),
//       endDate?.toIso8601String().substring(0, 10),
//     );
//     setState(() {
//       netBalance = data['net_balance'];
//       entries = data['entries'];
//       isLoading = false;
//     });
//   }

//   DateTime? startDate;
//   DateTime? endDate;

//   void generatePdf() async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.Page(
//         build: (pw.Context context) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Text('Report', style: pw.TextStyle(fontSize: 24)),
//               pw.SizedBox(height: 10),
//               pw.Text('Net Balance: $netBalance'),
//               pw.SizedBox(height: 10),
//               ...entries.map(
//                 (e) => pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Text(e['date']),
//                     if (e['gave'].isNotEmpty) pw.Text("You Gave: ${e['gave']}"),
//                     if (e['got'].isNotEmpty) pw.Text("You Got: ${e['got']}"),
//                     if (e['note'].isNotEmpty) pw.Text("Note: ${e['note']}"),
//                     pw.Text("Balance: ${e['balance']}"),
//                     pw.Divider(),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );

//     await Printing.layoutPdf(onLayout: (format) async => pdf.save());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: Colors.blue[800],
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text('View Report', style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           // Date Pickers
//           Container(
//             color: Colors.blue[800],
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton(
//                   onPressed: () async {
//                     final picked = await showDatePicker(
//                       context: context,
//                       initialDate: DateTime.now(),
//                       firstDate: DateTime(2000),
//                       lastDate: DateTime(2100),
//                     );
//                     if (picked != null) setState(() => startDate = picked);
//                   },
//                   child: Text(
//                     startDate == null
//                         ? 'Start Date'
//                         : startDate!.toLocal().toString().split(' ')[0],
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () async {
//                     final picked = await showDatePicker(
//                       context: context,
//                       initialDate: DateTime.now(),
//                       firstDate: DateTime(2000),
//                       lastDate: DateTime(2100),
//                     );
//                     if (picked != null) setState(() => endDate = picked);
//                   },
//                   child: Text(
//                     endDate == null
//                         ? 'End Date'
//                         : endDate!.toLocal().toString().split(' ')[0],
//                   ),
//                 ),
//               ],
//             ),

//             // Row(
//             //   children: [
//             //     Expanded(
//             //       child: ElevatedButton.icon(
//             //         onPressed: () {},
//             //         icon: const Icon(Icons.calendar_today, size: 16),
//             //         label: const Text('Start Date'),
//             //         style: ElevatedButton.styleFrom(
//             //           backgroundColor: Colors.white,
//             //           foregroundColor: Colors.black,
//             //         ),
//             //       ),
//             //     ),
//             //     const SizedBox(width: 12),
//             //     Expanded(
//             //       child: ElevatedButton.icon(
//             //         onPressed: () {},
//             //         icon: const Icon(Icons.calendar_today, size: 16),
//             //         label: const Text('End Date'),
//             //         style: ElevatedButton.styleFrom(
//             //           backgroundColor: Colors.white,
//             //           foregroundColor: Colors.black,
//             //         ),
//             //       ),
//             //     ),
//             //   ],
//             // ),
//           ),

//           // Search & Filter
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       hintText: 'Search Entries',
//                       filled: true,
//                       fillColor: Colors.white,
//                       prefixIcon: const Icon(Icons.search),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   decoration: BoxDecoration(
//                     color: Colors.blue[100],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: DropdownButtonHideUnderline(
//                     child: DropdownButton<String>(
//                       value: 'All',
//                       icon: const Icon(Icons.arrow_drop_down),
//                       style: const TextStyle(color: Colors.black),
//                       dropdownColor: Colors.white,
//                       onChanged: (String? value) {
//                         // UI only — add logic if needed later
//                       },
//                       items: const [
//                         DropdownMenuItem(value: 'All', child: Text('All')),
//                         DropdownMenuItem(
//                           value: 'This Month',
//                           child: Text('This Month'),
//                         ),
//                         DropdownMenuItem(
//                           value: 'Last Week',
//                           child: Text('Last Week'),
//                         ),
//                         DropdownMenuItem(
//                           value: 'Last Month',
//                           child: Text('Last Month'),
//                         ),
//                         DropdownMenuItem(
//                           value: 'Single Day',
//                           child: Text('Single Day'),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Net Balance
//           Container(
//             width: double.infinity,
//             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(8),
//               boxShadow: const [
//                 BoxShadow(color: Colors.black12, blurRadius: 4),
//               ],
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: const [
//                 Text(
//                   "Net Balance",
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                 ),
//                 Text(
//                   "₹ 400",
//                   style: TextStyle(
//                     fontSize: 18,
//                     color: Colors.red,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Header Row
//           Container(
//             color: Colors.grey[200],
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: const Row(
//               children: [
//                 Expanded(
//                   flex: 2,
//                   child: Text(
//                     'ENTRIES',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 Expanded(
//                   child: Text(
//                     'YOU GAVE',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 Expanded(
//                   child: Text(
//                     'YOU GOT',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const Divider(height: 1),

//           // Entry List
//           Expanded(
//             child: ListView(
//               children: const [
//                 EntryRow(
//                   date: '16 May 25 • 12:29 PM',
//                   balance: '₹ 400',
//                   gave: '',
//                   got: '₹ 100',
//                 ),
//                 EntryRow(
//                   date: '16 May 25 • 12:27 PM',
//                   balance: '₹ 500',
//                   gave: '₹ 500',
//                   got: '',
//                   note: 'Food',
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),

//       // Bottom Buttons
//       bottomNavigationBar: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         child: Row(
//           children: [
//             Expanded(
//               child: ElevatedButton.icon(
//                 icon: Icon(Icons.download),
//                 label: Text("Download"),
//                 onPressed: generatePdf,
//               ),
//               // ElevatedButton.icon(
//               //   onPressed: () {},
//               //   icon: const Icon(Icons.download),
//               //   label: const Text('Download'),
//               //   style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
//               // ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: () {},
//                 icon: const Icon(Icons.share),
//                 label: const Text('Share'),
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class EntryRow extends StatelessWidget {
//   final String date;
//   final String balance;
//   final String gave;
//   final String got;
//   final String? note;

//   const EntryRow({
//     super.key,
//     required this.date,
//     required this.balance,
//     required this.gave,
//     required this.got,
//     this.note,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         boxShadow: [
//           BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 2),
//         ],
//       ),
//       child: Row(
//         children: [
//           // ENTRIES column
//           Expanded(
//             flex: 2,
//             child: Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(date, style: const TextStyle(fontSize: 12)),
//                   const SizedBox(height: 2),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 6,
//                       vertical: 2,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Text(
//                       'Bal. $balance',
//                       style: const TextStyle(fontSize: 10, color: Colors.grey),
//                     ),
//                   ),
//                   if (note != null) ...[
//                     const SizedBox(height: 4),
//                     Text(note!, style: const TextStyle(fontSize: 12)),
//                   ],
//                 ],
//               ),
//             ),
//           ),

//           // YOU GAVE
//           Expanded(
//             child: Container(
//               padding: const EdgeInsets.all(12),
//               color: gave.isNotEmpty ? Colors.white : Colors.grey[100],
//               child:
//                   gave.isNotEmpty
//                       ? Align(
//                         alignment: Alignment.center,
//                         child: Text(
//                           gave,
//                           style: const TextStyle(
//                             color: Colors.red,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       )
//                       : const SizedBox.shrink(),
//             ),
//           ),

//           // YOU GOT
//           Expanded(
//             child: Container(
//               padding: const EdgeInsets.all(12),
//               color: got.isNotEmpty ? Colors.white : Colors.grey[100],
//               child:
//                   got.isNotEmpty
//                       ? Align(
//                         alignment: Alignment.center,
//                         child: Text(
//                           got,
//                           style: const TextStyle(
//                             color: Colors.green,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       )
//                       : const SizedBox.shrink(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<Map<String, dynamic>> fetchReportData(
  String phone,
  String? startDate,
  String? endDate,
) async {
  final response = await http.post(
    Uri.parse('https://yourdomain.com/get_report.php'),
    body: {
      'phone': phone,
      'start_date': startDate ?? '',
      'end_date': endDate ?? '',
    },
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load report');
  }
}

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String netBalance = '';
  List<dynamic> entries = [];
  List<dynamic> filteredEntries = [];
  bool isLoading = true;
  String searchQuery = '';
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> sharePdfReport() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Report', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 10),
              pw.Text('Net Balance: ₹$netBalance'),
              pw.SizedBox(height: 10),
              ...filteredEntries.map(
                (e) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(e['date'] ?? ''),
                    if ((e['gave'] ?? '').isNotEmpty)
                      pw.Text("You Gave: ${e['gave']}"),
                    if ((e['got'] ?? '').isNotEmpty)
                      pw.Text("You Got: ${e['got']}"),
                    if ((e['note'] ?? '').isNotEmpty)
                      pw.Text("Note: ${e['note']}"),
                    pw.Text("Balance: ${e['balance']}"),
                    pw.Divider(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/report.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Shared Report - Net Balance: ₹$netBalance');
  }

  void fetchData() async {
    try {
      setState(() => isLoading = true);
      final data = await fetchReportData(
        '1234567890',
        startDate?.toIso8601String().substring(0, 10),
        endDate?.toIso8601String().substring(0, 10),
      );
      setState(() {
        netBalance = data['net_balance'];
        entries = data['entries'];
        applySearchFilter();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to fetch report: $e')));
    }
  }

  void applySearchFilter() {
    setState(() {
      filteredEntries =
          entries.where((entry) {
            final date = entry['date']?.toString().toLowerCase() ?? '';
            final note = entry['note']?.toString().toLowerCase() ?? '';
            return date.contains(searchQuery.toLowerCase()) ||
                note.contains(searchQuery.toLowerCase());
          }).toList();
    });
  }

  void generatePdf() async {
    final pdf = pw.Document();

    // Load a font that supports ₹ symbol
    final font = await PdfGoogleFonts.notoSansDevanagariRegular();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Report', style: pw.TextStyle(fontSize: 24, font: font)),
              pw.SizedBox(height: 10),
              pw.Text(
                'Net Balance: ₹$netBalance',
                style: pw.TextStyle(font: font),
              ),
              pw.SizedBox(height: 10),
              ...filteredEntries.map(
                (e) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(e['date'] ?? '', style: pw.TextStyle(font: font)),
                    if ((e['gave'] ?? '').isNotEmpty)
                      pw.Text(
                        "You Gave: ₹${e['gave']}",
                        style: pw.TextStyle(font: font),
                      ),
                    if ((e['got'] ?? '').isNotEmpty)
                      pw.Text(
                        "You Got: ₹${e['got']}",
                        style: pw.TextStyle(font: font),
                      ),
                    if ((e['note'] ?? '').isNotEmpty)
                      pw.Text(
                        "Note: ${e['note']}",
                        style: pw.TextStyle(font: font),
                      ),
                    pw.Text(
                      "Balance: ₹${e['balance']}",
                      style: pw.TextStyle(font: font),
                    ),
                    pw.Divider(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('View Report', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchData),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blue[801],
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => startDate = picked);
                  },
                  child: Text(
                    startDate == null
                        ? 'Start Date'
                        : startDate!.toLocal().toString().split(' ')[0],
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => endDate = picked);
                  },
                  child: Text(
                    endDate == null
                        ? 'End Date'
                        : endDate!.toLocal().toString().split(' ')[0],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      searchQuery = value;
                      applySearchFilter();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search Entries',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: 'All',
                      icon: const Icon(Icons.arrow_drop_down),
                      style: const TextStyle(color: Colors.black),
                      dropdownColor: Colors.white,
                      onChanged: (String? value) {
                        // Logic placeholder
                      },
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        DropdownMenuItem(
                          value: 'This Month',
                          child: Text('This Month'),
                        ),
                        DropdownMenuItem(
                          value: 'Last Week',
                          child: Text('Last Week'),
                        ),
                        DropdownMenuItem(
                          value: 'Last Month',
                          child: Text('Last Month'),
                        ),
                        DropdownMenuItem(
                          value: 'Single Day',
                          child: Text('Single Day'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Net Balance",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  "₹ $netBalance",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'ENTRIES',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'YOU GAVE',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'YOU GOT',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: filteredEntries.length,
                      itemBuilder: (context, index) {
                        final item = filteredEntries[index];
                        return EntryRow(
                          date: item['date'],
                          balance: item['balance'],
                          gave: item['gave'],
                          got: item['got'],
                          note: item['note'],
                        );
                      },
                    ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text("Download"),
                onPressed: generatePdf,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: sharePdfReport,
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EntryRow extends StatelessWidget {
  final String date;
  final String balance;
  final String gave;
  final String got;
  final String? note;

  const EntryRow({
    super.key,
    required this.date,
    required this.balance,
    required this.gave,
    required this.got,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 2),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Bal. $balance',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                  if (note != null && note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(note!, style: const TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              color: gave.isNotEmpty ? Colors.white : Colors.grey[100],
              child:
                  gave.isNotEmpty
                      ? Align(
                        alignment: Alignment.center,
                        child: Text(
                          gave,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              color: got.isNotEmpty ? Colors.white : Colors.grey[100],
              child:
                  got.isNotEmpty
                      ? Align(
                        alignment: Alignment.center,
                        child: Text(
                          got,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
