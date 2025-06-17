import 'package:cashinout/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class CustomerProfilePage extends StatefulWidget {
  final String userId;
  final String customerId;

  const CustomerProfilePage({
    super.key,
    required this.userId,
    required this.customerId,
  });

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _profileImageUrl;
  String? _initialName;
  File? _imageFile;
  bool _hasChanges = false;

  final _onlyLetters = FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'));

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_checkForChanges);
    _fetchCustomerProfileData();
  }

  Future<void> _fetchCustomerProfileData() async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/get_customer_details.php'),
        body: {'user_id': widget.userId, 'customer_id': widget.customerId},
      );

      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success'] == true) {
        final data = jsonResponse['data'];
        setState(() {
          _initialName = data['name'] ?? '';
          _nameController.text = _initialName!;
          _phoneController.text = data['phone'] ?? 'No Phone';
          _profileImageUrl = data['profile_image'] ?? '';
        });
      } else {
        setState(() {
          _nameController.text = 'error';
          _phoneController.text = 'error';
        });
      }
    } catch (e) {
      setState(() {
        _nameController.text = 'failed to fetch';
        _phoneController.text = 'failed to fetch';
      });
      print("Error fetching profile data: $e");
    }
  }

  void _checkForChanges() {
    final nameChanged = _nameController.text.trim() != (_initialName ?? '');
    final imageChanged = _imageFile != null;
    setState(() {
      _hasChanges = nameChanged || imageChanged;
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
      _checkForChanges();
    }
  }

  Future<void> _saveCustomerProfile() async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${Constants.baseUrl}/update_customer_profile.php'),
    );
    request.fields['user_id'] = widget.userId;
    request.fields['customer_id'] = widget.customerId;
    request.fields['name'] = _nameController.text.trim();
    request.fields['phone'] = _phoneController.text.trim();

    if (_imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('profile_image', _imageFile!.path),
      );
    }

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final jsonResponse = json.decode(respStr);

      if (jsonResponse['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonResponse['message'] ?? 'Profile updated')),
        );
        Navigator.pop(context, true); // Go back and indicate update
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonResponse['message'] ?? 'Update failed')),
        );
      }
    } catch (e) {
      print('Update profile error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('An error occurred')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF468585),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Customer Profile',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 24),

              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFFCCCCCC),
                  backgroundImage:
                      _imageFile != null
                          ? FileImage(_imageFile!)
                          : (_profileImageUrl != null &&
                                  _profileImageUrl!.isNotEmpty
                              ? NetworkImage(_profileImageUrl!)
                              : null),
                  child:
                      _imageFile == null &&
                              (_profileImageUrl == null ||
                                  _profileImageUrl!.isEmpty)
                          ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          )
                          : null,
                ),
              ),

              const SizedBox(height: 12),
              const Text(
                "Tap image to change",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _nameController,
                inputFormatters: [_onlyLetters],
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _hasChanges ? _saveCustomerProfile : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF468585),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
