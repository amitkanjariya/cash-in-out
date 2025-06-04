import 'package:flutter/material.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  bool isCustomer = true;

  void toggleRole() {
    setState(() {
      isCustomer = !isCustomer;
    });
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
        title: const Text('Customer Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[800],
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Name'),
              subtitle: Text('Eva Charusat'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
            const Divider(height: 1),
            const ListTile(
              leading: Icon(Icons.phone_outlined),
              title: Text('Mobile Number'),
              subtitle: Text('+91-8849186917'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
            const Divider(height: 1),
            const ListTile(
              leading: Icon(Icons.location_on_outlined),
              title: Text('Add Address'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
            const Divider(height: 8),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                ),
                onPressed: () {},
                child: const Text('Delete Customer'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
