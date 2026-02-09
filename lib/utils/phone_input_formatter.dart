import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the new value is empty, return it
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Filter out non-digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    
    // Limit to 10 digits
    final truncated = digitsOnly.length > 10 
        ? digitsOnly.substring(0, 10) 
        : digitsOnly;

    final buffer = StringBuffer();
    // int selectionIndex = newValue.selection.end;

    // Adjust selection index based on formatting characters added/removed
    // This simple approach recalculates the cursor position at the end of the formatted text
    // A more complex implementation would be needed to handle cursor position perfectly in the middle of text editing
    // But for a phone number field, appending is the most common case.
    
    for (int i = 0; i < truncated.length; i++) {
      if (i == 0) {
        buffer.write('(');
      }
      if (i == 3) {
        buffer.write(') ');
      }
      if (i == 6) {
        buffer.write('-');
      }
      buffer.write(truncated[i]);
    }

    final formattedText = buffer.toString();

    // Simple cursor positioning: put it at the end
    // This prevents cursor jumping issues when backspacing formatted chars
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
