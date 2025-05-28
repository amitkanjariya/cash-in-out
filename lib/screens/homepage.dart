import 'dart:convert';
import 'package:cashinout/models/transaction_model.dart';
import 'package:cashinout/screens/profilepage.dart';
import 'package:cashinout/utils/constants.dart';
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
        selectedItemColor: Colors.blue,
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

        for (var tx in fetchedTransactions) {
          double amount = double.tryParse(tx.amount.toString()) ?? 0;
          if (tx.type == 'minus') {
            give += amount;
          } else if (tx.type == 'plus') {
            get += amount;
          }
        }

        setState(() {
          transactions = fetchedTransactions;
          filteredTransactions = fetchedTransactions;
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
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.book, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Cash In Out',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.account_circle, color: Colors.white),
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
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = filteredTransactions[index];
                        return CustomerTile(
                          name: transaction.contactName,
                          amount: '₹ ${transaction.amount}',
                          subtitle:
                              transaction.type == 'plus'
                                  ? "You'll Get"
                                  : "You'll Give",
                          time: transaction.createdAt,
                          isCredit: transaction.type == 'plus',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CustomerDetailPage(),
                              ),
                            );
                          },
                        );
                      },
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
                'You will give',
                '₹ ${totalGive.toStringAsFixed(2)}',
                Colors.green,
              ),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              buildBalanceCard(
                'You will get',
                '₹ ${totalGet.toStringAsFixed(2)}',
                Colors.red,
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
                Icon(Icons.bar_chart, size: 16, color: Colors.blue),
                SizedBox(width: 4),
                Text(
                  'VIEW REPORT',
                  style: TextStyle(
                    color: Colors.blue,
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
  final String name, amount, subtitle, time;
  final bool isCredit;
  final VoidCallback onTap;

  const CustomerTile({
    super.key,
    required this.name,
    required this.amount,
    required this.subtitle,
    required this.time,
    required this.isCredit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1565C0),
          child: Text(
            name.substring(0, 2).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(time, style: const TextStyle(fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: TextStyle(
                color: isCredit ? Colors.red : Colors.green,
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
