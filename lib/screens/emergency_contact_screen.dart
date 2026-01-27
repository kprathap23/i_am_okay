import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown_field.dart';
import '../widgets/loading_overlay.dart';
import '../services/graphql_service.dart';
import '../utils/phone_input_formatter.dart';
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
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  bool _isFormVisible = true;
  final List<Map<String, dynamic>> _contacts = [];
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId != null) {
        final user = await GraphQLService.getUser(userId);
        if (mounted && user != null && user.emergencyContacts.isNotEmpty) {
          setState(() {
            _contacts.addAll(user.emergencyContacts.map((c) => {
                  'name': c.name ?? '',
                  'relation': c.relation ?? 'Other',
                  'phone': c.phone ?? '',
                  'email': c.email,
                }));
            _isFormVisible = _contacts.isEmpty;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching contacts: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedRelation;

  final List<String> _relations = [
    'Parent',
    'Spouse',
    'Child',
    'Sibling',
    'Friend',
    'Partner',
    'Other'
  ];

  void _addContact() {
    if (_contacts.length >= 3) return;
    if (_selectedRelation == null ||
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
        'relation': _selectedRelation!,
        'name': _nameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text.isEmpty ? null : _emailController.text,
      });
      _selectedRelation = null;
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _isFormVisible = false;
    });
  }

  void _removeContact(int index) {
    setState(() {
      _contacts.removeAt(index);
      if (_contacts.isEmpty) {
        _isFormVisible = true;
      }
    });
  }

  Future<void> _handleNext() async {
    // 1. Check if form has data and try to add it first
    if (_isFormVisible &&
        (_nameController.text.isNotEmpty ||
            _phoneController.text.isNotEmpty ||
            _selectedRelation != null)) {
      if (_selectedRelation == null ||
          _nameController.text.isEmpty ||
          _phoneController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please complete the contact details or clear the form before saving'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      _addContact();
    } else if (_isFormVisible && _contacts.isNotEmpty) {
      // If form is empty but visible, just collapse it (unless contacts are empty)
      setState(() {
        _isFormVisible = false;
      });
    }

    if (_contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one emergency contact'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isFormVisible = true;
      });
      return;
    }

    LoadingOverlay.show(context);

    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null) {
        throw Exception('User not found');
      }

      // Ensure email is null if empty string
      final contactsToUpdate = _contacts.map((c) {
        final rawPhone = c['phone'].toString();
        final phone = rawPhone.replaceAll(RegExp(r'\D'), '');
        return {
          'name': c['name'],
          'relation': c['relation'],
          'phone': phone,
          'email': (c['email'] == null || c['email'].toString().isEmpty)
              ? null
              : c['email'],
        };
      }).toList();

      await GraphQLService.updateUser(userId, {
        'emergencyContacts': contactsToUpdate,
      });

      if (mounted) {
        LoadingOverlay.hide(context);
        setState(() {
          _isFormVisible = false;
        });

        if (widget.isOnboarding) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const DailyReminderScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contacts saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update contacts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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
                if (_isFormVisible) ...[
                  const Text(
                    'Add New Contact',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomDropdownField<String>(
                    label: 'Relation',
                    hint: 'Select relation',
                    value: _selectedRelation,
                    items: _relations.map((String relation) {
                      return DropdownMenuItem<String>(
                        value: relation,
                        child: Text(relation),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedRelation = newValue;
                      });
                    },
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
                    inputFormatters: [PhoneInputFormatter()],
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
                ] else ...[
                  CustomButton(
                    text: 'Add Another Contact',
                    onPressed: () {
                      setState(() {
                        _isFormVisible = true;
                      });
                    },
                    backgroundColor: Colors.transparent,
                    textColor: const Color(0xFF1F4ED8),
                  ),
                  const SizedBox(height: 24),
                ],
              ],

              if (widget.isOnboarding) ...[
                CustomButton(
                  text: 'Next',
                  onPressed: _handleNext,
                ),
                const SizedBox(height: 24),
              ],
              if (!widget.isOnboarding) ...[
                CustomButton(
                  text: 'Save',
                  onPressed: _handleNext,
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
