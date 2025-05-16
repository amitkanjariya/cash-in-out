import 'package:flutter/material.dart';
import 'customerprofilepage.dart';

class CustomerDetailPage extends StatelessWidget {
  const CustomerDetailPage({super.key});

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
              MaterialPageRoute(
                builder: (context) => const CustomerProfilePage(),
              ),
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
                children: const [
                  Text(
                    'Eva Charusat',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    'Click here to view settings',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: const [
          Icon(Icons.call, color: Colors.white),
          SizedBox(width: 16),
          Icon(Icons.more_vert, color: Colors.white),
          SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // "You will get" Box
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'You will get',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    Text(
                      '₹ 1,000',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: const Text('Set Collection Dates'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ],
            ),
          ),
          // Quick Actions
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                IconWithLabel(icon: Icons.picture_as_pdf, label: 'Report'),
                IconWithLabel(icon: Icons.payments, label: 'Payments'),
                IconWithLabel(
                  icon: Icons.notifications_active,
                  label: 'Reminders',
                ),
                IconWithLabel(icon: Icons.sms, label: 'SMS'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Header Row for Entries
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
          // Entries List
          Expanded(
            child: ListView(
              children: const [
                EntryRow(
                  date: '16 May 25 • 12:31 PM',
                  balance: '₹ 1,000',
                  gave: '₹ 800',
                  got: '',
                ),
                EntryRow(
                  date: '16 May 25 • 12:31 PM',
                  balance: '₹ 200',
                  gave: '',
                  got: '₹ 200',
                ),
                EntryRow(
                  date: '16 May 25 • 12:29 PM',
                  balance: '₹ 400',
                  gave: '',
                  got: '₹ 100',
                ),
                EntryRow(
                  date: '16 May 25 • 12:27 PM',
                  balance: '₹ 500',
                  gave: '₹ 500',
                  got: '',
                  note: 'Food',
                ),
              ],
            ),
          ),
        ],
      ),
      // Bottom Buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('YOU GAVE ₹'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
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
          // Column 1: ENTRIES
          Expanded(
            flex: 2,
            child: Container(
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
                  if (note != null) ...[
                    const SizedBox(height: 4),
                    Text(note!, style: const TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),

          // Column 2: YOU GAVE
          Expanded(
            child: Container(
              color: gave.isNotEmpty ? Colors.white : Colors.grey[100],
              padding: const EdgeInsets.all(12),
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

          // Column 3: YOU GOT
          Expanded(
            child: Container(
              color: got.isNotEmpty ? Colors.white : Colors.grey[100],
              padding: const EdgeInsets.all(12),
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
