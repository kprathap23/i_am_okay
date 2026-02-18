import 'package:flutter/material.dart';
import 'package:i_am_okay/models/user_model.dart';
import 'package:i_am_okay/services/graphql_service.dart';
import 'package:i_am_okay/widgets/custom_button.dart';
import 'package:i_am_okay/widgets/loading_overlay.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _address1Controller;
  late TextEditingController _address2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.name?.firstName);
    _lastNameController = TextEditingController(text: widget.user.name?.lastName);
    _address1Controller = TextEditingController(text: widget.user.address?.address1);
    _address2Controller = TextEditingController(text: widget.user.address?.address2);
    _cityController = TextEditingController(text: widget.user.address?.city);
    _stateController = TextEditingController(text: widget.user.address?.state);
    _zipCodeController = TextEditingController(text: widget.user.address?.zipCode);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (_formKey.currentState!.validate()) {
      LoadingOverlay.show(context);
      try {
        await GraphQLService.updateUser(widget.user.id, {
          'name': {
            'firstName': _firstNameController.text,
            'lastName': _lastNameController.text,
          },
          'address': {
            'address1': _address1Controller.text,
            'address2': _address2Controller.text,
            'city': _cityController.text,
            'state': _stateController.text,
            'zipCode': _zipCodeController.text,
          },
        });

        if (mounted) {
          LoadingOverlay.hide(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _address1Controller,
                decoration: const InputDecoration(labelText: 'Address Line 1'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _address2Controller,
                decoration: const InputDecoration(labelText: 'Address Line 2'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(labelText: 'State'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _zipCodeController,
                decoration: const InputDecoration(labelText: 'ZIP Code'),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Save Changes',
                onPressed: _handleUpdate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
