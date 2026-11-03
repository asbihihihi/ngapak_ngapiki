import 'package:flutter/services.dart';

String formatThousands(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';
  return digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
}

double? parseMoneyInput(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? null : double.tryParse(digits);
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  const ThousandsSeparatorInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsBeforeCursor = newValue.text
        .substring(0, newValue.selection.end.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;
    final formatted = formatThousands(newValue.text);
    if (newValue.selection.isCollapsed) {
      var offset = 0;
      var digitCount = 0;
      while (offset < formatted.length && digitCount < digitsBeforeCursor) {
        if (formatted.codeUnitAt(offset) >= 48 &&
            formatted.codeUnitAt(offset) <= 57) {
          digitCount++;
        }
        offset++;
      }
      while (offset < formatted.length &&
          formatted.codeUnitAt(offset) == 46) {
        offset++;
      }
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: offset),
      );
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
