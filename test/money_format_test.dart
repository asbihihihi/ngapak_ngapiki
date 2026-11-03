import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngapak_farm/money_format.dart';

void main() {
  test('formats and parses thousands-separated prices', () {
    expect(formatThousands('1000000'), '1.000.000');
    expect(parseMoneyInput('Rp 1.000.000'), 1000000);
    expect(parseMoneyInput(''), isNull);
  });

  test('keeps the cursor after the last entered digit', () {
    const formatter = ThousandsSeparatorInputFormatter();
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '1000000',
        selection: TextSelection.collapsed(offset: 7),
      ),
    );

    expect(result.text, '1.000.000');
    expect(result.selection, const TextSelection.collapsed(offset: 9));
  });
}
