import 'dart:convert';
import 'package:cashinout/models/transaction_model.dart';
import 'package:cashinout/utils/constants.dart';
import 'package:cashinout/utils/helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'entryrow.dart';
import 'package:intl/intl.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String userPhone = '';
  String userId = '';
  bool isLoading = true;
  List<TransactionModel> transactions = [];
  List<TransactionModel> filteredTransactions = [];
  double totalGive = 0;
  double totalGet = 0;
  String searchQuery = '';
  String selectedSort = 'None';
  DateTime? startDate;
  DateTime? endDate;
  String selectedFilter = 'All'; // For filtering (date/income/expense)

  @override
  void initState() {
    super.initState();
    initUserData();
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

    final userIdRes = await http.post(
      Uri.parse('${Constants.baseUrl}/get_user_id_by_phone.php'),
      body: {'phone': userPhone},
    );
    final idData = jsonDecode(userIdRes.body);
    if (idData['success'] == true) {
      userId = idData['user_id'].toString();
      fetchTransactions();
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get user ID: ${idData['message']}')),
      );
    }
  }

  Future<void> fetchTransactions() async {
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/get_transactions.php'),
      body: {'user_id': userId},
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['success'] == true && responseBody['data'] is List) {
        final fetchedTransactions =
            (responseBody['data'] as List)
                .map((item) => TransactionModel.fromJson(item))
                .toList();

        setState(() {
          transactions = fetchedTransactions;
          applyFilters();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No transactions found')));
      }
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load transactions')),
      );
    }
  }

  void applyFilters() {
    DateTime now = DateTime.now();
    if (selectedFilter != 'Custom') {
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
      }
    }
    filteredTransactions =
        transactions.where((tx) {
          DateTime txDate = DateTime.tryParse(tx.createdAt) ?? DateTime(2000);

          // Date filter
          if (startDate != null && txDate.isBefore(startDate!)) return false;
          if (endDate != null &&
              txDate.isAfter(endDate!.add(const Duration(days: 1)))) {
            return false;
          }

          // Text search filter
          if (searchQuery.isNotEmpty &&
              !(tx.contactName.toLowerCase().contains(searchQuery) ||
                  tx.contactPhone.toLowerCase().contains(searchQuery) ||
                  tx.amount.toLowerCase().contains(searchQuery))) {
            return false;
          }

          // Income/Expense filter
          if (selectedFilter == 'Expense' && tx.type != 'minus') return false;
          if (selectedFilter == 'Income' && tx.type != 'plus') return false;

          return true;
        }).toList();

    totalGive = 0;
    totalGet = 0;
    for (var tx in filteredTransactions) {
      double amt = double.tryParse(tx.amount) ?? 0;
      if (tx.type == 'minus') totalGive += amt;
      if (tx.type == 'plus') totalGet += amt;
    }
  }

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      applyFilters();
    });
  }

  void sortTransactions(String criteria) {
    selectedSort = criteria;
    switch (criteria) {
      case 'Name (A-Z)':
        filteredTransactions.sort(
          (a, b) => a.contactName.compareTo(b.contactName),
        );
        break;
      case 'Name (Z-A)':
        filteredTransactions.sort(
          (a, b) => b.contactName.compareTo(a.contactName),
        );
        break;
      case 'Time ↑':
        filteredTransactions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Time ↓':
        filteredTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
  }

  Future<void> pickStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
        selectedFilter = 'Custom';
        applyFilters();
      });
    }
  }

  Future<void> pickEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        endDate = picked;
        selectedFilter = 'Custom';
        applyFilters();
      });
    }
  }

  Future<void> sharePDF() async {
    final pdf = await _buildPDF();
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'report.pdf');
  }

  Future<pw.Document> _buildPDF() async {
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

    double totalDebit = 0;
    double totalCredit = 0;

    for (var tx in filteredTransactions) {
      final amount = double.tryParse(tx.amount) ?? 0;
      if (tx.type == 'minus') {
        totalDebit += amount;
      } else {
        totalCredit += amount;
      }
    }

    final netBalance = totalCredit - totalDebit;

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
                      font: font,
                      fontSize: 12,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.Text(
                    'CashInOut',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 16,
                      color: PdfColors.white,
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
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ),
            ),
        build:
            (context) => [
              pw.SizedBox(height: 20),

              // Title & Date Range
              pw.Center(
                child: pw.Text(
                  'Account Statement',
                  style: pw.TextStyle(font: boldFont, fontSize: 18),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  '($dateRange)',
                  style: pw.TextStyle(font: font, fontSize: 11),
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
                    _buildSummaryBox(
                      "Total Debit(-)",
                      totalDebit,
                      font,
                      boldFont,
                      color: PdfColors.red800,
                    ),
                    _buildSummaryBox(
                      "Total Credit(+)",
                      totalCredit,
                      font,
                      boldFont,
                      color: PdfColors.green800,
                    ),
                    _buildSummaryBox(
                      "Net Balance",
                      netBalance,
                      font,
                      boldFont,
                      color:
                          netBalance >= 0
                              ? PdfColors.green800
                              : PdfColors.red800,
                      suffix: netBalance >= 0 ? " Cr" : " Dr",
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              pw.Text(
                "No. of Entries: ${filteredTransactions.length}",
                style: pw.TextStyle(font: font, fontSize: 10),
              ),

              // Table
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
                    1: const pw.FlexColumnWidth(3),
                    2: const pw.FlexColumnWidth(3),
                    3: const pw.FlexColumnWidth(2),
                    4: const pw.FlexColumnWidth(2),
                  },
                  headers: ["Date", "Name", "Details", "Debit(-)", "Credit(+)"],
                  data:
                      filteredTransactions.map((tx) {
                        final date = DateFormat(
                          'dd MMM yy',
                        ).format(DateTime.parse(tx.createdAt));
                        final isDebit = tx.type == 'minus';
                        final debit = isDebit ? formatAmount(tx.amount) : '';
                        final credit = !isDebit ? formatAmount(tx.amount) : '';
                        return [date, tx.contactName, tx.detail, debit, credit];
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
                            formatAmount(totalDebit.toStringAsFixed(2)),
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 10,
                              color: PdfColors.red,
                            ),
                          ),
                          pw.SizedBox(width: 20),
                          pw.Text(
                            formatAmount(totalCredit.toStringAsFixed(2)),
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

  pw.Widget _buildSummaryBox(
    String title,
    double amount,
    pw.Font font,
    pw.Font boldFont, {
    required PdfColor color,
    String suffix = "",
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(font: font, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text(
            "${formatAmount(amount.toString())}$suffix",
            style: pw.TextStyle(font: boldFont, fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  Future<void> generateAndDownloadPDF() async {
    final pdf = await _buildPDF();

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        title: const Text('View Report', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          buildTopCard(context),
          buildSearchbar(),
          buildBalanceCard(),
          const Divider(height: 1),

          buildStickyHeaderSummary(),
          buildHeaderRow(),
          const Divider(height: 1),
          Expanded(child: buildTransactionList()),
        ],
      ),
      bottomNavigationBar: buildBottomButtons(),
    );
  }

  Widget buildTopCard(BuildContext context) {
    return Container(
      color: Colors.blue[800],
      padding: const EdgeInsets.symmetric(
        vertical: 0,
        horizontal: 8,
      ).copyWith(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: pickStartDate,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                startDate == null ? 'Start Date' : formatDateHelper(startDate!),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: pickEndDate,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                endDate == null ? 'End Date' : formatDateHelper(endDate!),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
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

  Widget buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Net Balance",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            "₹ ${formatAmount((totalGet - totalGive).abs().toStringAsFixed(2))}",
            style: TextStyle(
              fontSize: 18,
              color: (totalGet - totalGive) >= 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStickyHeaderSummary() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // ENTRIES (left-aligned)
          Expanded(
            flex: 2,
            child: buildSummaryColumn(
              "Total Entries",
              "${filteredTransactions.length}",
            ),
          ),
          // YOU GAVE (center-aligned)
          Expanded(
            child: Center(
              child: buildSummaryColumn(
                "You Gave",
                "₹ ${formatAmount(totalGive.toStringAsFixed(0))}",
                color: Colors.red,
              ),
            ),
          ),
          // YOU GOT (right-aligned)
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: buildSummaryColumn(
                "You Got",
                "₹ ${formatAmount(totalGet.toStringAsFixed(0))}",
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryColumn(String title, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black,
          ),
        ),
      ],
    );
  }

  Widget buildHeaderRow() {
    return Container(
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
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'YOU GOT',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTransactionList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (filteredTransactions.isEmpty) {
      return const Center(child: Text('No transactions found'));
    } else {
      return ListView.builder(
        itemCount: filteredTransactions.length,
        itemBuilder: (context, index) {
          final tx = filteredTransactions[index];
          return EntryRow(
            name: tx.contactName,
            date: formatDateTimeHelper(tx.createdAt),
            gave: tx.type == 'minus' ? formatAmount(tx.amount) : '',
            got: tx.type == 'plus' ? formatAmount(tx.amount) : '',
          );
        },
      );
    }
  }

  Widget buildBottomButtons() {
    final isDisabled = filteredTransactions.isEmpty;
    void showNoTransactionMessage(String action) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No transactions to $action')));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  isDisabled
                      ? () => showNoTransactionMessage('download')
                      : generateAndDownloadPDF,
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text(
                'Download',
                style: TextStyle(color: Colors.white),
              ),
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
              onPressed:
                  isDisabled
                      ? () => showNoTransactionMessage('share')
                      : sharePDF,
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text('Share', style: TextStyle(color: Colors.white)),
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
                hintText: 'Search Customer',
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
