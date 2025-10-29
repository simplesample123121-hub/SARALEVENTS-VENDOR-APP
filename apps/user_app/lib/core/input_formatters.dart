import 'package:flutter/services.dart';

/// Blocks emoji and most non-text pictographic symbols.
/// Allows letters, numbers, punctuation, spaces, and common diacritics.
class NoEmojiTextInputFormatter extends TextInputFormatter {
  // Unicode property regex is not supported; use a conservative BMP range and exclude surrogate/private use.
  static final RegExp _disallowed = RegExp(
    r"[\uD800-\uDFFF\uE000-\uF8FF]", // surrogates and private-use (commonly emojis)
  );

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final filtered = newValue.text.replaceAll(_disallowed, '');
    if (filtered == newValue.text) return newValue;
    return TextEditingValue(
      text: filtered,
      selection: _updateSelection(newValue.selection, newValue.text, filtered),
      composing: TextRange.empty,
    );
  }

  TextSelection _updateSelection(TextSelection sel, String before, String after) {
    final int diff = before.length - after.length;
    final int base = (sel.baseOffset - diff).clamp(0, after.length);
    final int extent = (sel.extentOffset - diff).clamp(0, after.length);
    return TextSelection(baseOffset: base, extentOffset: extent);
  }
}

/// Allows only ASCII letters and spaces. Blocks digits, punctuation, emojis, symbols.
class LettersSpacesTextInputFormatter extends TextInputFormatter {
  static final RegExp _allowed = RegExp(r"[A-Za-z ]");

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final StringBuffer sb = StringBuffer();
    for (int i = 0; i < newValue.text.length; i++) {
      final String ch = newValue.text[i];
      if (_allowed.hasMatch(ch)) sb.write(ch);
    }
    final filtered = sb.toString();
    if (filtered == newValue.text) return newValue;
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}

/// Phone number formatter allowing leading '+', digits only after it,
/// and limiting total length to 15 (E.164 max digits incl. country code without separators).
class E164PhoneInputFormatter extends TextInputFormatter {
  final int maxLength;
  E164PhoneInputFormatter({this.maxLength = 15});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;
    if (text.isEmpty) return newValue;

    // Keep only leading '+', strip others.
    final StringBuffer sb = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final String ch = text[i];
      if (i == 0 && ch == '+') {
        sb.write(ch);
      } else if (_isAsciiDigit(ch)) {
        sb.write(ch);
      }
      // ignore everything else
    }

    String normalized = sb.toString();
    if (normalized.length > maxLength) {
      normalized = normalized.substring(0, maxLength);
    }

    // Prevent just '+' with no digits beyond a short length? Keep as is; validation can enforce.
    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }

  bool _isAsciiDigit(String ch) => ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;
}

/// Simple validators
class Validators {
  static String? requiredText(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  /// Validates an E.164-like phone: optional '+', followed by 10-15 digits total.
  /// Enforces at least 10 digits (common local length) and max 15 as per E.164.
  static String? phone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Enter phone number';
    final hasPlus = v.startsWith('+');
    final digits = v.replaceAll(RegExp(r"[^0-9]"), '');
    if (digits.length < 10) return 'Enter at least 10 digits';
    if (digits.length > 15) return 'Enter at most 15 digits';
    final RegExp pattern = hasPlus
        ? RegExp(r"^\+[0-9]{10,15}$")
        : RegExp(r"^[0-9]{10,15}$");
    if (!pattern.hasMatch(v)) {
      // fallback check to ensure shape is consistent
      return 'Invalid phone format';
    }
    return null;
  }

  /// Letters, spaces, hyphens and apostrophes; length 1..50
  static String? personName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Enter a name';
    if (v.length > 50) return 'Name is too long';
    if (!RegExp(r"^[A-Za-z][A-Za-z\s\-']{0,49}").hasMatch(v)) return 'Enter a valid name';
    return null;
  }

  /// Strict person name: only letters and spaces; length 1..50; single spaces between words
  static String? personNameLettersSpaces(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Enter a name';
    if (v.length > 50) return 'Name is too long';
    if (!RegExp(r"^[A-Za-z]+(?: [A-Za-z]+){0,9}").hasMatch(v)) {
      return 'Use letters and spaces only';
    }
    return null;
  }

  /// Basic email pattern; rely on backend for definitive validation.
  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Enter email';
    final ok = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]{2,}$").hasMatch(v);
    return ok ? null : 'Enter a valid email';
  }
}

/// Currency input formatter for price fields with ₹ symbol.
/// Allows only numbers with optional ₹ prefix.
class CurrencyInputFormatter extends TextInputFormatter {
  final double? maxValue;
  
  CurrencyInputFormatter({this.maxValue});
  
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // Allow ₹ symbol
    String text = newValue.text.replaceAll('₹', '').trim();
    
    // Allow only digits
    text = text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Apply max value limit if specified
    if (maxValue != null && text.isNotEmpty) {
      final double? value = double.tryParse(text);
      if (value != null && value > maxValue!) {
        text = maxValue!.toStringAsFixed(0);
      }
    }
    
    // Build the new text with ₹ prefix
    final newText = text.isEmpty ? '' : '₹ $text';
    
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}