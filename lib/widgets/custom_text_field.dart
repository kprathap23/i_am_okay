import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final int maxLines;
  final bool isOptional;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final AutovalidateMode autovalidateMode;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.isOptional = false,
    this.inputFormatters,
    this.onSubmitted,
    this.textInputAction,
    this.focusNode,
    this.validator,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 18.0, // Medium size for labels
                fontWeight: FontWeight.w500, // Medium (500)
                color: Color(0xFF000000), // Primary Text
              ),
            ),
            if (isOptional)
              const Text(
                ' (Optional)',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF333333), // Secondary Text
                ),
              )
            else
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          onFieldSubmitted: onSubmitted,
          textInputAction: textInputAction,
          validator: validator,
          autovalidateMode: autovalidateMode,
          style: const TextStyle(
            fontSize: 18.0, // Body text size
            fontWeight: FontWeight.w400, // Regular (400)
            color: Color(0xFF000000), // Primary Text
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w400,
              color: Color(0xFF999999), // Lighter gray for hint
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(0xFF1F4ED8), width: 2.0),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA), // Very light gray background for input
          ),
        ),
      ],
    );
  }
}
