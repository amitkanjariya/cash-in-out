import 'package:flutter/material.dart';
import 'profilepage.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        title: const Text('practice'),
        leading: const Icon(Icons.menu_book, color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text('P', style: TextStyle(color: Colors.white)),
            ),
            title: const Text('practice'),
            subtitle: const Text('+91-8780462605'),
            trailing: const Icon(Icons.edit, color: Colors.blue),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
          const SizedBox(height: 16),

          // Help & Support Section
          ExpansionTile(
            leading: const Icon(Icons.help, color: Colors.blue),
            title: const Text('Help & Support'),
            children: const [
              ListTile(
                title: Text('How To Use'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
              ListTile(
                title: Text('Help on WhatsApp'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
              ListTile(
                title: Text('Call Us'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // About Us Section
          ExpansionTile(
            leading: const Icon(Icons.info, color: Colors.blue),
            title: const Text('About Us'),
            children: const [
              ListTile(
                title: Text('About Khatabook'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
              ListTile(
                title: Text('Privacy Policy'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
              ListTile(
                title: Text('Terms & Conditions'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
