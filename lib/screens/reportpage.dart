import 'dart:convert';
import 'package:cashinout/models/transaction_model.dart';
import 'package:cashinout/utils/constants.dart';
import 'package:cashinout/utils/helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'entryrow.dart';

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
    filteredTransactions =
        transactions.where((tx) {
          DateTime txDate = DateTime.tryParse(tx.createdAt) ?? DateTime(2000);
          if (startDate != null && txDate.isBefore(startDate!)) return false;
          if (endDate != null &&
              txDate.isAfter(endDate!.add(const Duration(days: 1))))
            return false;

          if (searchQuery.isNotEmpty &&
              !(tx.contactName.toLowerCase().contains(searchQuery) ||
                  tx.contactPhone.toLowerCase().contains(searchQuery) ||
                  tx.amount.toLowerCase().contains(searchQuery)))
            return false;
          return true;
        }).toList();

    sortTransactions(selectedSort);

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
        applyFilters();
      });
    }
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
      ),
      body: Column(
        children: [
          buildTopCard(context),
          buildSearchbar(),
          buildBalanceCard(),
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: pickStartDate,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                startDate == null ? 'Start Date' : formatDate(startDate!),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: pickEndDate,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(endDate == null ? 'End Date' : formatDate(endDate!)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
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
            "₹ ${(totalGet - totalGive).toStringAsFixed(2)}",
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Entries",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                "${filteredTransactions.length}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "You Gave",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                "₹ ${totalGive.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "You Got",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                "₹ ${totalGet.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
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
            child: Text(
              'YOU GOT',
              style: TextStyle(fontWeight: FontWeight.bold),
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
            date: formatDateTime(tx.createdAt),
            gave: tx.type == 'minus' ? tx.amount : '',
            got: tx.type == 'plus' ? tx.amount : '',
          );
        },
      );
    }
  }

  Widget buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download),
              label: const Text('Download'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share),
              label: const Text('Share'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSearchbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                sortTransactions(value);
              });
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem(value: 'Name (A-Z)', child: Text('Name (A-Z)')),
                  PopupMenuItem(value: 'Name (Z-A)', child: Text('Name (Z-A)')),
                  PopupMenuItem(value: 'Time ↑', child: Text('Time Ascending')),
                  PopupMenuItem(
                    value: 'Time ↓',
                    child: Text('Time Descending'),
                  ),
                ],
          ),
        ],
      ),
    );
  }
}
