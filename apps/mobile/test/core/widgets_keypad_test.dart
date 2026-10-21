import 'package:cashe/core/widgets/amount_keypad.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String type(String keys) => keys.split('').fold('0', KeypadInput.press);

  test('replaces the leading zero', () => expect(type('12'), '12'));
  test('allows one decimal point', () => expect(type('1..5'), '1.5'));
  test('stops at two decimals', () => expect(type('3.999'), '3.99'));
  test('stops at six digits', () => expect(type('12345678'), '123456'));
  test('backspace returns to zero', () {
    expect(KeypadInput.press('7', '⌫'), '0');
    expect(KeypadInput.press('7.5', '⌫'), '7.');
  });
}
