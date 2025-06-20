import 'dart:convert';
import 'package:cashinout/utils/helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cashinout/utils/constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
  String userPhone = '';
  String customerName = 'Loading...';
  List<Map<String, dynamic>> entries = [];
  double totalGave = 0.0;
  double totalGot = 0.0;
  String searchQuery = '';
  String selectedSort = 'None';
  DateTime? startDate;
  DateTime? endDate;
  String selectedFilter = 'All'; // For filtering (date/income/expense)
  bool isLoading = true;
  ScrollController _scrollController = ScrollController();
  bool _showHeader = true;
  double _previousOffset = 0;

  @override
  void initState() {
    super.initState();
    initUserData();
    fetchCustomerDetails();
    fetchCustomerEntries();
    _scrollController.addListener(() {
      final currentOffset = _scrollController.offset;

      if (currentOffset > _previousOffset && _showHeader) {
        setState(() => _showHeader = false);
      } else if (currentOffset < _previousOffset && !_showHeader) {
        setState(() => _showHeader = true);
      }

      _previousOffset = currentOffset;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> initUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userPhone = prefs.getString('phone') ?? '';
    if (userPhone.isEmpty) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not found in SharedPreferences'),
        ),
      );
      return;
    }
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
    setState(() => isLoading = true);
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

          // Date filter
          if (startDate != null && entryDate.isBefore(startDate!)) continue;
          if (endDate != null &&
              entryDate.isAfter(endDate!.add(const Duration(days: 1))))
            continue;

          String type = item['type'] ?? '';
          if (selectedFilter == 'Income' && type != 'plus') continue;
          if (selectedFilter == 'Expense' && type != 'minus') continue;

          String amountStr = item['amount'] ?? '0';
          double amount = double.tryParse(amountStr) ?? 0.0;
          String note = (item['detail'] ?? '').toLowerCase();

          // Search filter
          String query = searchQuery.trim().toLowerCase();
          if (query.isNotEmpty &&
              !note.contains(query) &&
              !amountStr.contains(query)) {
            continue;
          }

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No transactions found')),
          );
        });
      }
    } catch (e) {
      setState(() {
        entries = [];
        totalGave = 0;
        totalGot = 0;
      });
    } finally {
      setState(() => isLoading = false); // hide loading
    }
  }

  void applyFilters() {
    DateTime now = DateTime.now();

    switch (selectedFilter) {
      case 'All':
        startDate = null;
        endDate = null;
        break;
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = now;
        break;
      case 'Last Week':
        startDate = now.subtract(const Duration(days: 7));
        endDate = now;
        break;
      case 'Last Month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        endDate = now;
        break;
      case 'Last 3 Months':
        startDate = DateTime(now.year, now.month - 3, now.day);
        endDate = now;
        break;
      case 'Last 6 Months':
        startDate = DateTime(now.year, now.month - 6, now.day);
        endDate = now;
        break;
      case 'Last Year':
        startDate = DateTime(now.year - 1, now.month, now.day);
        endDate = now;
        break;
      case 'Income':
      case 'Expense':
        // no date range change
        break;
    }

    fetchCustomerEntries(); // Refresh entries based on selected filter
  }

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      applyFilters();
    });
  }

  Future<pw.Document> generatePdf() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final now = DateTime.now();
    final formattedNow =
        "${DateFormat.jm().format(now)} | ${DateFormat("dd MMM yy").format(now)}";
    String dateRange;
    if (startDate == null && endDate == null) {
      dateRange = "All Transactions";
    } else if (startDate == null) {
      dateRange = "Until ${DateFormat("dd MMM yy").format(endDate!)}";
    } else if (endDate == null) {
      dateRange = "From ${DateFormat("dd MMM yy").format(startDate!)}";
    } else {
      dateRange =
          "${DateFormat("dd MMM yy").format(startDate!)} - ${DateFormat("dd MMM yy").format(endDate!)}";
    }
    final netBalance = totalGot - totalGave;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(7),
        header:
            (context) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              color: PdfColors.blue900,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '+91$userPhone',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.white,
                      font: font,
                    ),
                  ),
                  pw.Text(
                    'CashInOut',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.white,
                      font: boldFont,
                    ),
                  ),
                ],
              ),
            ),
        footer:
            (context) => pw.Container(
              margin: const pw.EdgeInsets.only(top: 16),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Report Generated : $formattedNow',
                    style: pw.TextStyle(fontSize: 10, font: font),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(fontSize: 10, font: font),
                  ),
                ],
              ),
            ),

        build:
            (context) => [
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'Account Statement Of $customerName',
                  style: pw.TextStyle(fontSize: 18, font: boldFont),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  '($dateRange)',
                  style: pw.TextStyle(fontSize: 11, font: font),
                ),
              ),
              pw.SizedBox(height: 16),

              // Summary Boxes
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPdfSummaryBox(
                      "Total Debit(-)",
                      totalGave,
                      font,
                      boldFont,
                      color: PdfColors.red800,
                    ),
                    _buildPdfSummaryBox(
                      "Total Credit(+)",
                      totalGot,
                      font,
                      boldFont,
                      color: PdfColors.green800,
                    ),
                    _buildPdfSummaryBox(
                      "Net Balance",
                      netBalance,
                      font,
                      boldFont,
                      color:
                          netBalance >= 0
                              ? PdfColors.green800
                              : PdfColors.red800,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                "No. of Entries: ${entries.length}",
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 10),
                child: pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(font: boldFont, fontSize: 11),
                  cellStyle: pw.TextStyle(font: font, fontSize: 10),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  cellAlignment: pw.Alignment.centerLeft,
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.5),
                    1: const pw.FlexColumnWidth(3.5),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(2),
                    4: const pw.FlexColumnWidth(2),
                  },
                  headers: ['Date', 'Note', 'Balance', 'Debit', 'Credit'],
                  data:
                      entries.map((e) {
                        final date = DateFormat(
                          'dd MMM yy',
                        ).format(DateTime.parse(e['date']));
                        final debit = formatAmount(e['gave']);
                        final credit = formatAmount(e['got']);

                        return [date, e['note'], e['balance'], debit, credit];
                      }).toList(),
                  cellDecoration: (columnIndex, rowIndex, cellData) {
                    if (rowIndex == 0) {
                      return const pw.BoxDecoration(
                        color: PdfColors.blueGrey100,
                      );
                    }
                    if (columnIndex == 3) {
                      return const pw.BoxDecoration(color: PdfColors.pink50);
                    }
                    if (columnIndex == 4) {
                      return const pw.BoxDecoration(color: PdfColors.green50);
                    }
                    return const pw.BoxDecoration();
                  },
                  border: pw.TableBorder.all(width: 0.5),
                ),
              ),
              // Grand Total Row
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: PdfColors.grey200,
                      child: pw.Row(
                        children: [
                          pw.Text(
                            "Grand Total  ",
                            style: pw.TextStyle(font: boldFont, fontSize: 10),
                          ),
                          pw.Text(
                            formatAmount(totalGave.toStringAsFixed(2)),
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 10,
                              color: PdfColors.red,
                            ),
                          ),
                          pw.SizedBox(width: 20),
                          pw.Text(
                            formatAmount(totalGot.toStringAsFixed(2)),
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 10,
                              color: PdfColors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfSummaryBox(
    String title,
    double amount,
    pw.Font font,
    pw.Font boldFont, {
    required PdfColor color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(font: font, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text(
            "${formatAmount(amount.toString())}",
            style: pw.TextStyle(font: boldFont, fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  Future<void> downloadPdf() async {
    final pdf = await generatePdf();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> sharePdf() async {
    final pdf = await generatePdf();
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'report.pdf');
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
        backgroundColor: Color(0xFF468585),
        title: Text(
          'Report of $customerName',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showHeader ? null : 0,
            child: Column(children: [_buildDateFilterRow(), buildSearchbar()]),
          ),
          _buildSummaryBox(netBalance),
          const Divider(height: 1),
          _buildTotalSummary(),
          const Divider(height: 1),
          _buildEntryHeader(),
          Expanded(child: _buildTransactionList()),

          _buildDownloadShareButtons(),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF468585), // 👈 your custom color
        ),
      );
    }

    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'No transactions found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: entries.length,
      itemBuilder: (context, index) => _buildEntryRow(index),
    );
  }

  Widget _buildDateFilterRow() {
    return Container(
      color: Color(0xFF468585),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: pickStartDate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                startDate == null ? "START DATE" : formatDateOnly(startDate!),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: pickEndDate,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                endDate == null ? "END DATE" : formatDateOnly(endDate!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(double netBalance) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Net Balance', style: TextStyle(fontSize: 18)),
          Text(
            '₹ ${formatAmount(netBalance.abs().toString())}',
            style: TextStyle(
              fontSize: 18,
              color:
                  netBalance > 0
                      ? Colors.green
                      : netBalance < 0
                      ? Colors.red
                      : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSummary() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'TOTAL\n${entries.length} Entries',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
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
                '₹ ${formatAmount(totalGave.toString())}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
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
                '₹ ${formatAmount(totalGot.toString())}',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntryHeader() {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: const [
          Expanded(flex: 2, child: Text('Date')),
          Expanded(child: Text('You Gave', textAlign: TextAlign.right)),
          Expanded(child: Text('You Got', textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildEntryRow(int index) {
    final e = entries[index];
    return Container(
      color: index % 2 == 0 ? Colors.white : Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  'Bal. ₹ ${formatAmount(e['balance'])}',
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
              e['gave'].isNotEmpty ? '₹ ${formatAmount(e['gave'])}' : '',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              e['got'].isNotEmpty ? '₹ ${formatAmount(e['got'])}' : '',
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
  }

  Widget _buildDownloadShareButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text(
                'DOWNLOAD',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: downloadPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text('SHARE', style: TextStyle(color: Colors.white)),
              onPressed: sharePdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSearchbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: updateSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search Entries',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort, color: Colors.black54),
            onSelected: (value) {
              setState(() {
                selectedFilter = value;
                applyFilters();
              });
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem(value: 'All', child: Text('All')),
                  PopupMenuItem(value: 'Expense', child: Text('Expense')),
                  PopupMenuItem(value: 'Income', child: Text('Income')),
                  PopupMenuItem(value: 'Today', child: Text('Today')),
                  PopupMenuItem(value: 'Last Week', child: Text('Last Week')),
                  PopupMenuItem(value: 'Last Month', child: Text('Last Month')),
                  PopupMenuItem(
                    value: 'Last 3 Months',
                    child: Text('Last 3 Months'),
                  ),
                  PopupMenuItem(
                    value: 'Last 6 Months',
                    child: Text('Last 6 Months'),
                  ),
                  PopupMenuItem(value: 'Last Year', child: Text('Last Year')),
                ],
          ),
        ],
      ),
    );
  }
}
