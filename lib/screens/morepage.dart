import 'package:cashinout/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profilepage.dart';
import 'login_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  String? _profileImageUrl;
  String _name = 'practice';
  String _phone = '+91-8780462605';

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Get phone number from prefs or use default
      String? phone = prefs.getString('phone') ?? _phone;

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/fetch_profile.php'),
        body: {'phone': phone},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true) {
          final data = jsonData['data'];

          setState(() {
            _name = data['name'] ?? _name;
            _phone = phone;

            if (data['profile_image'] != null &&
                data['profile_image'].isNotEmpty) {
              _profileImageUrl = data['profile_image'];
              // Your backend already prefixes /api/upload/, so no replacement needed
            }
          });
        } else {
          debugPrint('User not found or error: ${jsonData['message']}');
        }
      } else {
        debugPrint('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching profile data: $e');
    }
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF468585),
        centerTitle: true, // ✅ This centers the title
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading:
                _profileImageUrl != null
                    ? CircleAvatar(
                      backgroundImage: NetworkImage(_profileImageUrl!),
                      backgroundColor: Colors.transparent,
                    )
                    : CircleAvatar(
                      backgroundColor: Color(0xFF468585),
                      child: Text(
                        _name.isNotEmpty ? _name[0].toUpperCase() : 'P',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
            title: Text(_name),
            subtitle: Text(_phone),
            trailing: const Icon(Icons.edit, color: Color(0xFF468585)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
          const SizedBox(height: 16),

          ExpansionTile(
            leading: const Icon(Icons.help, color: Color(0xFF468585)),
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

          ExpansionTile(
            leading: const Icon(Icons.info, color: Color(0xFF468585)),
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

          const SizedBox(height: 32),

          ElevatedButton.icon(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF468585),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
