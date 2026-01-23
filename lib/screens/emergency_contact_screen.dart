import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'daily_reminder_screen.dart';

class EmergencyContactScreen extends StatefulWidget {
  final bool isOnboarding;

  const EmergencyContactScreen({
    super.key,
    this.isOnboarding = true,
  });

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  final List<Map<String, String>> _contacts = [];
  final _relationController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  void _addContact() {
    if (_contacts.length >= 3) return;
    if (_relationController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all required fields'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _contacts.add({
        'relation': _relationController.text,
        'name': _nameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
      });
      _relationController.clear();
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
    });
  }

  void _removeContact(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: widget.isOnboarding
          ? AppBar(
              backgroundColor: const Color(0xFFFFFFFF),
              elevation: 0,
              title: const Text(
                'Emergency Contacts',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),
            )
          : null, // Hide AppBar when inside TabBar as the TabBar wrapper might provide it or it's not needed
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add up to 3 emergency contacts (${_contacts.length}/3)',
                style: const TextStyle(
                  fontSize: 18.0,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 24),
              // List of added contacts
              if (_contacts.isNotEmpty) ...[
                ..._contacts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final contact = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      border: Border.all(color: const Color(0xFFCCCCCC)),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact['name']!,
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text('${contact['relation']} • ${contact['phone']}'),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeContact(index),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Add Contact Form
              if (_contacts.length < 3) ...[
                const Text(
                  'Add New Contact',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Relation',
                  hint: 'e.g. Mother, Spouse',
                  controller: _relationController,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Full Name',
                  hint: 'Enter full name',
                  controller: _nameController,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  keyboardType: TextInputType.phone,
                  controller: _phoneController,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter email address',
                  keyboardType: TextInputType.emailAddress,
                  isOptional: true,
                  controller: _emailController,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Add Contact',
                  onPressed: _addContact,
                  backgroundColor: Colors.transparent,
                  textColor: const Color(0xFF1F4ED8),
                ),
                const Divider(height: 48),
              ],

              if (widget.isOnboarding) ...[
                CustomButton(
                  text: 'Next',
                  onPressed: () {
                    if (_contacts.isEmpty) {
                      // Optional: require at least 1 contact?
                      // User said "User can add...", maybe optional?
                      // Usually onboarding enforces at least one.
                      // Let's assume at least one is needed for safety app.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please add at least one emergency contact'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DailyReminderScreen()),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
