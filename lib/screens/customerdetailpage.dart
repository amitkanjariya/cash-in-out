import 'package:cashinout/screens/you_gave_page.dart';
import 'package:cashinout/screens/you_got_page.dart';
import 'package:cashinout/utils/constants.dart';
import 'package:cashinout/utils/entry_detail_card.dart';
import 'package:cashinout/utils/helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'customerprofilepage.dart';

class CustomerDetailPage extends StatefulWidget {
  final String userId;
  final String customerId;

  const CustomerDetailPage({
    super.key,
    required this.userId,
    required this.customerId,
  });

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  String customerName = 'Loading...';
  String customerPhone = '';
  List<Map<String, dynamic>> entries = [];
  double totalGave = 0.0;
  double totalGot = 0.0;

  @override
  void initState() {
    super.initState();
    fetchCustomerDetails();
    fetchCustomerEntries();
  }

  Future<void> fetchCustomerDetails() async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/get_customer_details.php'),
        body: {'user_id': widget.userId, 'customer_id': widget.customerId},
      );
      final jsonResponse = jsonDecode(response.body);
      print("user_id: ${widget.userId}");
      print("customer_id: ${widget.customerId}");
      if (jsonResponse['success'] == true) {
        final data = jsonResponse['data'];
        print("customer data: $data");
        setState(() {
          customerName = data['name'] ?? 'No Name';
          customerPhone = data['phone'] ?? '';
        });
      } else {
        setState(() {
          customerName = 'Error loading';
        });
      }
    } catch (e) {
      setState(() {
        customerName = 'Failed to load';
      });
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
        double gave = 0.0;
        double got = 0.0;
        double balance = 0.0;

        // Start from the end and calculate balance backward
        for (var i = data['data'].length - 1; i >= 0; i--) {
          var item = data['data'][i];
          String type = item['type'] ?? '';
          String amountStr = item['amount'] ?? '0';
          double amount = double.tryParse(amountStr) ?? 0.0;

          String entryGave = '';
          String entryGot = '';

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
            'date': item['created_at'] ?? '',
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

  void _launchDialer() async {
    if (customerPhone.isNotEmpty) {
      final Uri uri = Uri(scheme: 'tel', path: customerPhone);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer')),
        );
      }
    }
  }

  void _sendSMS() async {
    if (customerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    String message = 'Hello $customerName, ';
    double diff = (totalGave - totalGot).abs();

    if (totalGave > totalGot) {
      message += 'you have to give ₹${diff.toStringAsFixed(2)}.';
    } else if (totalGot > totalGave) {
      message += 'you have to get ₹${diff.toStringAsFixed(2)}.';
    } else {
      message += 'your account is settled.';
    }

    final Uri smsUri = Uri.parse(
      'sms:$customerPhone?body=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open SMS app')));
    }
  }

  void _sendWhatsApp() async {
    if (customerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    String message = 'Hello $customerName, ';
    double diff = (totalGave - totalGot).abs();

    if (totalGave > totalGot) {
      message += 'you have to give ₹${diff.toStringAsFixed(2)}.';
    } else if (totalGot > totalGave) {
      message += 'you have to get ₹${diff.toStringAsFixed(2)}.';
    } else {
      message += 'your account is settled.';
    }

    String phone = customerPhone.replaceAll(RegExp(r'\D'), '');
    final whatsappUrl = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomerProfilePage()),
            );
          },
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Text('EC', style: TextStyle(color: Colors.blue)),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    customerPhone,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: _launchDialer,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Builder(
              builder: (_) {
                if (totalGave > totalGot) {
                  double diff = totalGave - totalGot;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('You Gave', style: TextStyle(fontSize: 16)),
                      Text(
                        '₹ ${diff.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                } else if (totalGot > totalGave) {
                  double diff = totalGot - totalGave;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('You Got', style: TextStyle(fontSize: 16)),
                      Text(
                        '₹ ${diff.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Center(
                    child: Text(
                      'Settled up',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const IconWithLabel(
                  icon: Icons.picture_as_pdf,
                  label: 'Report',
                ),
                const IconWithLabel(icon: Icons.payments, label: 'Payments'),
                GestureDetector(
                  onTap: _sendWhatsApp,
                  child: const IconWithLabel(
                    icon: Icons.payments,
                    label: 'WhatsApp',
                  ),
                ),
                GestureDetector(
                  onTap: _sendSMS,
                  child: const IconWithLabel(icon: Icons.sms, label: 'SMS'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: const [
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
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (_) {
                        return Padding(
                          padding: MediaQuery.of(context).viewInsets,
                          child: EntryDetailCard(
                            date: entry['date'] ?? '',
                            gave: entry['gave'] ?? '',
                            got: entry['got'] ?? '',
                            balance: entry['balance'] ?? '',
                            note: entry['note'],
                          ),
                        );
                      },
                    );
                  },
                  child: EntryRow(
                    date: entry['date'] ?? '',
                    balance: entry['balance'] ?? '',
                    gave: entry['gave'] ?? '',
                    got: entry['got'] ?? '',
                    note: entry['note'],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => YouGavePage(customerId: widget.customerId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('YOU GAVE ₹'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => YouGotPage(customerId: widget.customerId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('YOU GOT ₹'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IconWithLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const IconWithLabel({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
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
    final double parsedBalance = double.tryParse(balance) ?? 0.0;

    // Decide colors based on balance sign
    final Color bgColor =
        parsedBalance < 0 ? Colors.red.shade50 : Colors.green.shade50;
    final Color textColor = parsedBalance < 0 ? Colors.red : Colors.green;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      padding: const EdgeInsets.all(12),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDateTime(date),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Bal. ${parsedBalance.abs()}',
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      note!,
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              gave,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              got,
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
}
