import 'dart:convert';
import 'package:cashinout/models/transaction_model.dart';
import 'package:cashinout/screens/profilepage.dart';
import 'package:cashinout/utils/constants.dart';
import 'package:cashinout/utils/helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'customerdetailpage.dart';
import 'morepage.dart';
import 'reportpage.dart';
import 'addcustomer_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const CustomerListPage(),
    const ReportPage(),
    const MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'REPORT',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'MORE'),
        ],
        selectedItemColor: Color(0xFF468585),
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  List<TransactionModel> transactions = [];
  bool isLoading = true;
  String userPhone = '';
  String userId = '';
  double totalGive = 0;
  double totalGet = 0;
  String searchQuery = '';
  List<TransactionModel> filteredTransactions = [];
  String selectedSort = 'None';

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
    print("userid: $userId, phone: $userPhone");
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

        double give = 0;
        double get = 0;

        final Map<String, List<TransactionModel>> grouped = {};

        for (var tx in fetchedTransactions) {
          grouped.putIfAbsent(tx.contactId, () => []).add(tx);
        }

        final List<TransactionModel> uniqueFiltered = [];

        grouped.forEach((contactId, txList) {
          double totalPlus = 0;
          double totalMinus = 0;

          for (var tx in txList) {
            double amount = double.tryParse(tx.amount) ?? 0;
            if (tx.type == 'plus') {
              totalPlus += amount;
              get += amount;
            } else if (tx.type == 'minus') {
              totalMinus += amount;
              give += amount;
            }
          }

          final net = totalPlus - totalMinus;

          txList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final latestTx = txList.first;
          final summaryTx = TransactionModel(
            amount: net.abs().toStringAsFixed(2),
            detail: latestTx.detail,
            type: net >= 0 ? 'plus' : 'minus',
            createdAt: latestTx.createdAt,
            contactId: latestTx.contactId,
            contactName: latestTx.contactName,
            contactPhone: latestTx.contactPhone,
            contactProfileImage: latestTx.contactProfileImage,
          );

          uniqueFiltered.add(summaryTx);
        });

        setState(() {
          transactions = fetchedTransactions;
          filteredTransactions = uniqueFiltered;
          totalGive = give;
          totalGet = get;
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

  void sortTransactions(String criteria) {
    setState(() {
      selectedSort = criteria;
      switch (criteria) {
        case 'Name (A-Z)':
          filteredTransactions.sort(
            (a, b) => a.contactName.toLowerCase().compareTo(
              b.contactName.toLowerCase(),
            ),
          );
          break;
        case 'Name (Z-A)':
          filteredTransactions.sort(
            (a, b) => b.contactName.toLowerCase().compareTo(
              a.contactName.toLowerCase(),
            ),
          );
          break;
        case 'Time ↑':
          filteredTransactions.sort(
            (a, b) => a.createdAt.compareTo(b.createdAt),
          );
          break;
        case 'Time ↓':
          filteredTransactions.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          );
          break;
      }
    });
  }

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredTransactions =
          transactions.where((tx) {
            final query = searchQuery.toLowerCase();
            return tx.contactName.toLowerCase().contains(query) ||
                tx.contactPhone.toLowerCase().contains(query) ||
                tx.amount.toString().toLowerCase().contains(query);
          }).toList();

      sortTransactions(selectedSort);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF468585),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset('assets/images/logo2.png', height: 40),
                const SizedBox(width: 12),
                const Text(
                  'Cash In-Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(
                Icons.account_circle,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          buildTopCard(context),
          const SizedBox(height: 12),
          buildSearchBar(),
          const SizedBox(height: 12),
          Expanded(
            child:
                isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF468585),
                      ),
                    )
                    : filteredTransactions.isEmpty
                    ? const Center(
                      child: Text(
                        'No Transactions Found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: fetchTransactions,
                      color: const Color(0xFF468585),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = filteredTransactions[index];
                          return CustomerTile(
                            name: transaction.contactName,
                            amount: '₹ ${formatAmount(transaction.amount)}',
                            subtitle:
                                transaction.type == 'plus'
                                    ? "You'll Give"
                                    : "You'll Get",
                            time: transaction.createdAt,
                            isCredit: transaction.type == 'plus',
                            profileImageUrl: transaction.contactProfileImage,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => CustomerDetailPage(
                                        userId: userId,
                                        customerId:
                                            transaction.contactId.toString(),
                                      ),
                                ),
                              );
                              fetchTransactions();
                            },
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCustomerPage()),
          );
        },
        backgroundColor: const Color.fromARGB(255, 96, 33, 63),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Add Customer',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget buildTopCard(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              buildBalanceCard(
                'You will Get',
                '₹ ${formatAmount(totalGive.toString())}',
                Colors.red,
              ),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              buildBalanceCard(
                'You will Give',
                '₹ ${formatAmount(totalGet.toString())}',
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportPage()),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.bar_chart, size: 16, color: Color(0xFF468585)),
                SizedBox(width: 4),
                Text(
                  'VIEW REPORT',
                  style: TextStyle(
                    color: Color(0xFF468585),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBalanceCard(String title, String amount, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
            onSelected: sortTransactions,
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'Name (A-Z)',
                    child: Text('Name (A-Z)'),
                  ),
                  const PopupMenuItem(
                    value: 'Name (Z-A)',
                    child: Text('Name (Z-A)'),
                  ),
                  const PopupMenuItem(
                    value: 'Time ↑',
                    child: Text('Time Ascending'),
                  ),
                  const PopupMenuItem(
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

class CustomerTile extends StatelessWidget {
  final String name, amount, subtitle, time, profileImageUrl;
  final bool isCredit;
  final VoidCallback onTap;

  const CustomerTile({
    super.key,
    required this.name,
    required this.amount,
    required this.subtitle,
    required this.time,
    required this.profileImageUrl,
    required this.isCredit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF468585), width: 2),
          ),
          child: CircleAvatar(
            backgroundColor: const Color(0xFF468585),
            backgroundImage:
                profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : null,
            child:
                profileImageUrl.isEmpty
                    ? Text(
                      getInitials(name),
                      style: const TextStyle(color: Colors.white),
                    )
                    : null,
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          buildRelativeTime(time),
          style: const TextStyle(fontSize: 12),
        ),

        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: TextStyle(
                color: isCredit ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(subtitle, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
