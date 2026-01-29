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
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _mobileController.text.trim().isEmpty ||
        _addressLine1Controller.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _zipCodeController.text.trim().isEmpty ||
        _selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    LoadingOverlay.show(context);

    try {
      final rawMobile = _mobileController.text.trim();
      final mobile = rawMobile.replaceAll(RegExp(r'\D'), '');

      // 2. Create User
      final input = {
        'mobileNumber': mobile,
        'email': _emailController.text.trim(),
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

      await GraphQLService.createUser(input);

      // 3. Request OTP
      await GraphQLService.requestOtp(mobile);

      if (mounted) {
        LoadingOverlay.hide(context);
        // 4. Navigate
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              isRegistration: true,
              mobileNumber: mobile,
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
              ),
              const SizedBox(height: 24.0),
              CustomTextField(
                label: 'Last Name',
                hint: 'Enter your last name',
                controller: _lastNameController,
                focusNode: _lastNameFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => FocusScope.of(context).requestFocus(_aliasNameFocus),
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
    );
  }
}
