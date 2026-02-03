import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown_field.dart';
import '../widgets/loading_overlay.dart';
import '../services/graphql_service.dart';
import '../utils/phone_input_formatter.dart';
import 'login_screen.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _aliasNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _emailController = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _aliasNameFocus = FocusNode();
  final _mobileFocus = FocusNode();
  final _addressLine1Focus = FocusNode();
  final _addressLine2Focus = FocusNode();
  final _cityFocus = FocusNode();
  final _zipCodeFocus = FocusNode();
  final _emailFocus = FocusNode();

  final _formKey = GlobalKey<FormState>();

  String? _selectedState;

  // Mock data for Zip to State mapping
  final Map<String, String> _zipToState = {
    '10001': 'NY',
    '90001': 'CA',
    '60601': 'IL',
    '77001': 'TX',
    '33101': 'FL',
    // Add more as needed or integrate a real API
  };

  final List<String> _states = [
    'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
    'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
    'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
    'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
    'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'
  ];

  @override
  void initState() {
    super.initState();
    _zipCodeController.addListener(_onZipChanged);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _aliasNameController.dispose();
    _mobileController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _emailController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _aliasNameFocus.dispose();
    _mobileFocus.dispose();
    _addressLine1Focus.dispose();
    _addressLine2Focus.dispose();
    _cityFocus.dispose();
    _zipCodeFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _onZipChanged() {
    final zip = _zipCodeController.text;
    if (zip.length >= 5) {
      // Simple lookup
      if (_zipToState.containsKey(zip)) {
        setState(() {
          _selectedState = _zipToState[zip];
        });
      }
      // In a real app, you might call an API here
    }
  }

  Future<void> _handleRegister() async {
    // 1. Validation
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a state'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    LoadingOverlay.show(context);

    try {
      final rawMobile = _mobileController.text.trim();
      final mobile = rawMobile.replaceAll(RegExp(r'\D'), '');
      final email = _emailController.text.trim();

      // 2. Check if user already exists
      final userExists = await GraphQLService.checkUserExists(mobileNumber: mobile);
      if (userExists) {
        if (mounted) {
          LoadingOverlay.hide(context);
          _showUserExistsDialog(context, mobile);
        }
        return;
      }

      // 3. Prepare User Data (Do not create yet)
      final input = {
        'mobileNumber': mobile,
        if (email.isNotEmpty) 'email': email,
        'name': {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'alias': _aliasNameController.text.trim(),
        },
        'address': {
          'address1': _addressLine1Controller.text.trim(),
          'address2': _addressLine2Controller.text.trim(),
          'city': _cityController.text.trim(),
          'zipCode': _zipCodeController.text.trim(),
          'state': _selectedState,
        }
      };

      // 4. Request OTP
      await GraphQLService.requestOtp(mobile, isRegister: true);

      if (mounted) {
        LoadingOverlay.hide(context);
        // 5. Navigate
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              isRegistration: true,
              mobileNumber: mobile,
              userData: input,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUserExistsDialog(BuildContext context, String mobile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Already Exists'),
        content: const Text(
            'An account with this mobile number already exists. Would you like to log in instead?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              FocusScope.of(context).requestFocus(_mobileFocus);
            },
            child: const Text('Edit Number'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(
                    initialMobileNumber: mobile,
                  ),
                ),
              );
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000000)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Register',
          style: TextStyle(
            fontSize: 26.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  label: 'First Name',
                  hint: 'Enter your first name',
                  controller: _firstNameController,
                  focusNode: _firstNameFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(context).requestFocus(_lastNameFocus),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'First name is required';
                    }
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                      return 'Only alphabets are allowed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                CustomTextField(
                  label: 'Last Name',
                  hint: 'Enter your last name',
                  controller: _lastNameController,
                  focusNode: _lastNameFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(context).requestFocus(_aliasNameFocus),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Last name is required';
                    }
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                      return 'Only alphabets are allowed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                CustomTextField(
                  label: 'Alias Name',
                  hint: 'Enter your alias name',
                  controller: _aliasNameController,
                  isOptional: true,
                  focusNode: _aliasNameFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(context).requestFocus(_mobileFocus),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && !RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                      return 'Only alphabets are allowed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                CustomTextField(
                  label: 'Mobile Number',
                  hint: 'Enter your mobile number',
                  keyboardType: TextInputType.phone,
                  controller: _mobileController,
                  inputFormatters: [PhoneInputFormatter()],
                  focusNode: _mobileFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(context).requestFocus(_addressLine1Focus),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Mobile number is required';
                    }
                    final digits = value.replaceAll(RegExp(r'\D'), '');
                    if (digits.length != 10) {
                      return 'Enter a valid 10-digit mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                CustomTextField(
                  label: 'Address Line 1',
                  hint: 'Street address, P.O. box, etc.',
                  controller: _addressLine1Controller,
                  keyboardType: TextInputType.streetAddress,
                  focusNode: _addressLine1Focus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(context).requestFocus(_addressLine2Focus),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Address Line 1 is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                CustomTextField(
                  label: 'Address Line 2',
                  hint: 'Apartment, suite, unit, etc.',
                  controller: _addressLine2Controller,
                  isOptional: true,
                  focusNode: _addressLine2Focus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(context).requestFocus(_cityFocus),
                ),
                const SizedBox(height: 24.0),
                CustomTextField(
                  label: 'City',
                  hint: 'Enter your city',
                  controller: _cityController,
                  focusNode: _cityFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(context).requestFocus(_zipCodeFocus),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'City is required';
                    }
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                      return 'Only alphabets are allowed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomTextField(
                        label: 'Zip Code',
                        hint: 'Zip Code',
                        keyboardType: TextInputType.number,
                        controller: _zipCodeController,
                        focusNode: _zipCodeFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Zip Code is required';
                          }
                          if (!RegExp(r'^\d{5}$').hasMatch(value)) {
                            return 'Enter a valid 5-digit Zip Code';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      flex: 1,
                      child: CustomDropdownField<String>(
                        label: 'State',
                        hint: 'Select State',
                        value: _selectedState,
                        items: _states.map((String state) {
                          return DropdownMenuItem<String>(
                            value: state,
                            child: Text(state),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedState = newValue;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email address',
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  isOptional: true,
                  focusNode: _emailFocus,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleRegister(),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Enter a valid email address';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40.0),
                CustomButton(
                  text: 'Register',
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
