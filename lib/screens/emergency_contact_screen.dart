import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown_field.dart';
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
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();

  final _formKey = GlobalKey<FormState>();

  // Track which contact is being edited. Null means adding a new contact.
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
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

  Future<void> _updateBackend({bool showSuccessMessage = true}) async {
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null) return;

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

      if (mounted && showSuccessMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contacts updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sync contacts. Please check your connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatPhoneDisplay(String phone) {
    // Assuming 10 digits
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 10)}';
    }
    return phone;
  }

  bool _saveContact() {
    // If adding new, check limit
    if (_editingIndex == null && _contacts.length >= 3) return false;
    
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    final inputPhone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');

    // Check for duplicates
    for (int i = 0; i < _contacts.length; i++) {
      // Skip if we are editing this specific contact
      if (_editingIndex != null && i == _editingIndex) continue;

      final existingPhone = _contacts[i]['phone'].toString().replaceAll(RegExp(r'\D'), '');
      
      if (existingPhone == inputPhone) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This phone number is already added as an emergency contact.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    final newContact = {
      'relation': _selectedRelation!,
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
    };

    setState(() {
      if (_editingIndex != null) {
        // Update existing
        _contacts[_editingIndex!] = newContact;
        _editingIndex = null;
      } else {
        // Add new
        _contacts.add(newContact);
      }
      
      // Reset form
      _selectedRelation = null;
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _isFormVisible = false;
    });
    
    // Auto-save
    _updateBackend();
    
    return true;
  }

  void _removeContact(int index) {
    setState(() {
      _contacts.removeAt(index);
      // If we were editing this specific contact, cancel edit
      if (_editingIndex == index) {
        _editingIndex = null;
        _isFormVisible = false;
        _selectedRelation = null;
        _nameController.clear();
        _phoneController.clear();
        _emailController.clear();
      } else if (_editingIndex != null && _editingIndex! > index) {
        // Adjust index if we removed a contact before the one being edited
        _editingIndex = _editingIndex! - 1;
      }

      if (_contacts.isEmpty) {
        _isFormVisible = true;
      }
    });
    // Auto-save
    _updateBackend();
  }

  void _editContact(int index) {
    final contact = _contacts[index];
    setState(() {
      _editingIndex = index;
      _nameController.text = contact['name'];
      
      // Format phone for the controller if it's just digits
      String rawPhone = contact['phone'];
      _phoneController.text = _formatPhoneDisplay(rawPhone);
      
      _emailController.text = contact['email'] ?? '';
      _selectedRelation = contact['relation'];
      
      _isFormVisible = true;
    });
  }

  Future<void> _handleNext() async {
    // For Onboarding:
    // If form is visible and has data, user might have forgotten to click "Add".
    // We try to add it. If it fails validation, we stop.
    if (_isFormVisible &&
        (_nameController.text.isNotEmpty ||
            _phoneController.text.isNotEmpty ||
            _selectedRelation != null)) {
      if (!_saveContact()) {
        return;
      }
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

    // Since we auto-save, we just navigate.
    // If not onboarding (e.g. settings), we don't need this method unless it's a "Done" button?
    // User requested "remove save button in contacts screen".
    // So this is mainly for Onboarding "Next".
    
    if (widget.isOnboarding) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const DailyReminderScreen()),
      );
    } else {
      // Just a fallback if this is called in non-onboarding mode
      Navigator.pop(context);
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
                            Text('${contact['relation']} • ${_formatPhoneDisplay(contact['phone'])}'),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF1F4ED8)),
                              onPressed: () => _editContact(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeContact(index),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Add Contact Form
              if (_contacts.length < 3) ...[
                if (_isFormVisible)
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _editingIndex != null ? 'Edit Contact' : 'Add New Contact',
                          style: const TextStyle(
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
                          validator: (value) =>
                              value == null ? 'Please select a relation' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Full Name',
                          hint: 'Enter full name',
                          controller: _nameController,
                          focusNode: _nameFocus,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_phoneFocus),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name is required';
                            }
                            if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                              return 'Only alphabets are allowed';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Phone Number',
                          hint: 'Enter phone number',
                          keyboardType: TextInputType.phone,
                          controller: _phoneController,
                          inputFormatters: [PhoneInputFormatter()],
                          focusNode: _phoneFocus,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_emailFocus),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            final digits =
                                value.replaceAll(RegExp(r'\D'), '');
                            if (digits.length != 10) {
                              return 'Enter a valid 10-digit phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Email',
                          hint: 'Enter email address',
                          keyboardType: TextInputType.emailAddress,
                          isOptional: true,
                          controller: _emailController,
                          focusNode: _emailFocus,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _saveContact(),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final emailRegex = RegExp(
                                  r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
                              if (!emailRegex.hasMatch(value)) {
                                return 'Enter a valid email address';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: _editingIndex != null ? 'Update Contact' : 'Add Contact',
                          onPressed: _saveContact,
                          backgroundColor: Colors.transparent,
                          textColor: const Color(0xFF1F4ED8),
                        ),
                        const Divider(height: 48),
                      ],
                    ),
                  )
                else ...[
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
              // "Save" button removed as per request for auto-save logic.
              // We only keep "Next" for onboarding flow.
            ],
          ),
        ),
      ),
    );
  }
}
