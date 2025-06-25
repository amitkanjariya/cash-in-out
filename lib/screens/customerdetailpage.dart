import 'package:cashinout/screens/entry_detail_page.dart';
import 'package:cashinout/screens/you_gave_page.dart';
import 'package:cashinout/screens/you_got_page.dart';
import 'package:cashinout/utils/constants.dart';
import 'package:cashinout/utils/helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'customerprofilepage.dart';
import 'customer_report_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  String? profileImageUrl;
  bool _showSummary = true;
  ScrollController? _scrollController;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCustomerDetails();
    fetchCustomerEntries();
    _scrollController = ScrollController();
    _scrollController!.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (_scrollController?.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_showSummary) {
        setState(() {
          _showSummary = false;
        });
      }
    } else if (_scrollController?.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_showSummary) {
        setState(() {
          _showSummary = true;
        });
      }
    }
  }

  Future<void> fetchCustomerDetails() async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/get_customer_details.php'),
        body: {'user_id': widget.userId, 'customer_id': widget.customerId},
      );
      final jsonResponse = jsonDecode(response.body);
      print("user_id: ${widget.userId}");
      if (jsonResponse['success'] == true) {
        final data = jsonResponse['data'];
        setState(() {
          customerName = data['name'] ?? 'No Name';
          customerPhone = data['phone'] ?? '';
          profileImageUrl = data['profile_image'];
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
    setState(() {
      isLoading = true;
    });
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

        for (var i = data['data'].length - 1; i >= 0; i--) {
          var item = data['data'][i];
          String type = item['type'] ?? '';
          String amountStr = item['amount'] ?? '0';
          double amount = double.tryParse(amountStr) ?? 0.0;
          int transactionId = item['id'] ?? -1;
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
            'transactionId': transactionId.toString(),
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
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshEntries() async {
    await fetchCustomerEntries();
    setState(() {});
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
      message += 'you have to give ₹${formatAmount(diff.toStringAsFixed(2))}.';
    } else if (totalGot > totalGave) {
      message += 'you have to get ₹${formatAmount(diff.toStringAsFixed(2))}.';
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
      message += 'you have to give ₹${formatAmount(diff.toStringAsFixed(2))}.';
    } else if (totalGot > totalGave) {
      message += 'you have to get ₹${formatAmount(diff.toStringAsFixed(2))}.';
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
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF468585),
        toolbarHeight: 60,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => CustomerProfilePage(
                      userId: widget.userId,
                      customerId: widget.customerId,
                    ),
              ),
            );
            if (updated == true) {
              fetchCustomerDetails();
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        profileImageUrl != null
                            ? NetworkImage(profileImageUrl!)
                            : null,
                    child:
                        profileImageUrl == null
                            ? Text(
                              getInitials(customerName),
                              style: const TextStyle(color: Color(0xFF468585)),
                            )
                            : null,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customerPhone,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _showSummary ? null : 0,
            margin: _showSummary ? const EdgeInsets.all(14) : EdgeInsets.zero,
            padding: _showSummary ? const EdgeInsets.all(14) : EdgeInsets.zero,
            decoration:
                _showSummary
                    ? BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    )
                    : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showSummary ? 1.0 : 0.0,
              child: Builder(
                builder: (_) {
                  if (totalGave > totalGot) {
                    double diff = totalGave - totalGot;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'You will Get',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '₹ ${formatAmount(diff.toStringAsFixed(2))}',
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
                        const Text(
                          'You will give',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '₹ ${formatAmount(diff.toStringAsFixed(2))}',
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
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => CustomerReportPage(
                              customerId: widget.customerId,
                              userId: widget.userId,
                            ),
                      ),
                    );
                  },
                  child: const IconWithLabel(
                    icon: Icons.bar_chart,
                    label: 'Report',
                  ),
                ),
                GestureDetector(
                  onTap: _sendWhatsApp,
                  child: const IconWithLabel(
                    icon: FontAwesomeIcons.whatsapp,
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
          const SizedBox(height: 4),
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: const [
                Expanded(
                  flex: 4,
                  child: Text(
                    'ENTRIES',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'YOU GAVE',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'YOU GOT',
                    textAlign: TextAlign.right,
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
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF468585),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _refreshEntries,
                      color: const Color(0xFF468585),
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final String entryDate = entry['date'];
                          final DateTime currentDate = DateTime.parse(
                            entryDate,
                          );
                          final String formattedDate =
                              formatDateWithRelativeLabel(currentDate);

                          bool showDateLabel = false;
                          if (index == 0) {
                            showDateLabel = true;
                          } else {
                            final previousDate = DateTime.parse(
                              entries[index - 1]['date'],
                            );
                            showDateLabel =
                                !isSameDate(currentDate, previousDate);
                          }

                          return Column(
                            children: [
                              if (showDateLabel)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.shade400,
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => EntryDetailPage(
                                            transactionId:
                                                entry['transactionId'],
                                            name: customerName,
                                            dateTime: entry['date'],
                                            amount:
                                                entry['gave'].isNotEmpty
                                                    ? entry['gave']
                                                    : entry['got'],
                                            type:
                                                entry['gave'].isNotEmpty
                                                    ? 'minus'
                                                    : 'plus',
                                            note: entry['note'] ?? '',
                                            profileImageUrl: profileImageUrl,
                                          ),
                                    ),
                                  );
                                  fetchCustomerEntries();
                                },
                                child: EntryRow(
                                  date: entry['date'] ?? '',
                                  balance: entry['balance'] ?? '',
                                  gave: entry['gave'] ?? '',
                                  got: entry['got'] ?? '',
                                  note: entry['note'],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
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
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => YouGavePage(customerId: widget.customerId),
                    ),
                  );
                  fetchCustomerEntries();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'YOU GAVE ₹',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => YouGotPage(customerId: widget.customerId),
                    ),
                  );
                  fetchCustomerEntries();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'YOU GOT ₹',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
        Icon(icon, color: Color(0xFF468585)),
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

    final Color bgColor =
        parsedBalance < 0 ? Colors.red.shade50 : Colors.green.shade50;
    final Color textColor = parsedBalance < 0 ? Colors.red : Colors.green;

    String formatDisplayAmount(String value, Color color) {
      if (value.isEmpty || double.tryParse(value) == 0) return '';
      return '₹ ${formatAmount(value)}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
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
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatDateTimeHelper(date),
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
                      'Bal. ₹ ${formatAmount(parsedBalance.abs().toString())}',
                      style: TextStyle(
                        fontSize: 10,
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Container(
              color: const Color(0xFFFFEBEE),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 22),
              alignment: Alignment.centerRight,
              child: Text(
                formatDisplayAmount(gave, Colors.red),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 22),
              alignment: Alignment.centerRight,
              child: Text(
                formatDisplayAmount(got, Colors.green),
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
