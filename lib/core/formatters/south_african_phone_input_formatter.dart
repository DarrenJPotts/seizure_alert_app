import 'package:flutter/services.dart';
class SouthAfricanPhoneInputFormatter extends TextInputFormatter {
  const SouthAfricanPhoneInputFormatter();

static const int maxLength = 15;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {

    if (!newValue.composing.isCollapsed) return newValue;

    final String trimmed = newValue.text.trimLeft();
    final bool hasInternationalPlus = trimmed.startsWith('+');
    final String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      if (hasInternationalPlus) return _withSelection(newValue, '+');
      return newValue;
    }

    final String compact = hasInternationalPlus ? '+$digits' : digits;
    final String formatted;
    final int maxDigits = compact.startsWith('+27') || compact.startsWith('27')
        ? 11
        : compact.startsWith('00')
        ? 13
        : compact.startsWith('0')
        ? 10
        : 9;

    if (digits.length > maxDigits) return oldValue;

    if (compact.startsWith('+27')) {
      formatted = _group(compact, prefixLength: 3, groups: const <int>[2, 3, 4]);
    } else if (hasInternationalPlus || compact.startsWith('00')) {

      return newValue;
    } else if (compact.startsWith('0')) {
      formatted = _group(compact, prefixLength: 0, groups: const <int>[3, 3, 4]);
    } else if (compact.startsWith('27')) {
      formatted = _group(compact, prefixLength: 2, groups: const <int>[2, 3, 4]);
    } else {
      formatted = _group(compact, prefixLength: 0, groups: const <int>[2, 3, 4]);
    }

    if (formatted == newValue.text) return newValue;
    return _withSelection(newValue, formatted);
  }

  static String _group(
    String value, {
    required int prefixLength,
    required List<int> groups,
  }) {
    final StringBuffer result = StringBuffer(value.substring(0, prefixLength));
    int offset = prefixLength;

    for (final int groupLength in groups) {
      if (offset >= value.length) break;
      if (result.isNotEmpty) result.write(' ');
      final int end = (offset + groupLength).clamp(0, value.length).toInt();
      result.write(value.substring(offset, end));
      offset = end;
    }

    if (offset < value.length) result.write(value.substring(offset));
    return result.toString();
  }

  static TextEditingValue _withSelection(TextEditingValue value, String formatted) {
    final int base = _mapOffset(value.text, value.selection.baseOffset, formatted);
    final int extent = _mapOffset(value.text, value.selection.extentOffset, formatted);
    return value.copyWith(
      text: formatted,
      selection: TextSelection(
        baseOffset: base,
        extentOffset: extent,
        affinity: value.selection.affinity,
        isDirectional: value.selection.isDirectional,
      ),
      composing: TextRange.empty,
    );
  }

  static int _mapOffset(String oldText, int oldOffset, String formatted) {
    if (oldOffset < 0) return oldOffset;
    final int safeOffset = oldOffset.clamp(0, oldText.length).toInt();
    final String beforeCursor = oldText.substring(0, safeOffset);
    final int digitsBeforeCursor = RegExp(r'\d').allMatches(beforeCursor).length;
    final bool plusBeforeCursor = beforeCursor.contains('+') && formatted.startsWith('+');

    int newOffset = plusBeforeCursor ? 1 : 0;
    int seenDigits = 0;
    while (newOffset < formatted.length && seenDigits < digitsBeforeCursor) {
      if (RegExp(r'\d').hasMatch(formatted[newOffset])) seenDigits++;
      newOffset++;
    }

if (digitsBeforeCursor > 0 && newOffset < formatted.length && formatted[newOffset] == ' ') {
      newOffset++;
    }
    return newOffset;
  }
}
