import 'package:flutter/material.dart';
import 'you_gave_page.dart';
import 'you_got_page.dart';

class Addcustomerpage extends StatelessWidget {
  final String name;
  final String phone;

  const Addcustomerpage({super.key, required this.name, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: const [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Text('EC', style: TextStyle(color: Colors.blue)),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Eva Charusat',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  Text(
                    'Click here to view settings',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Row(
              children: const [
                Icon(Icons.verified_user, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Only you and Eva Charusat can see these entries',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: SizedBox()),
          const Text(
            'Add first transaction of Eva Charusat',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Icon(Icons.arrow_downward, color: Colors.blue),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  YouGavePage(name: name, phone: phone),
                        ),
                      );
                    },

                    child: const Text('YOU GAVE ₹'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => YouGotPage(name: name, phone: phone),
                        ),
                      );
                    },

                    child: const Text('YOU GOT ₹'),
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
