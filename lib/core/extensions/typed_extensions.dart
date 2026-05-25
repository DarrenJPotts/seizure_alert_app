import 'package:flutter/material.dart';

extension NullableStringX on String? {
  bool get isNullOrEmpty => this?.isEmpty ?? true;

  bool get isNotNullOrEmpty => !isNullOrEmpty;

  String? get capitalizeFirstLetter => isNotNullOrEmpty ? this!.capitalizeFirstLetter : null;

  String? get lowerCaseFirstLetter => isNotNullOrEmpty ? this!.lowerCaseFirstLetter : null;

  bool get isSvg => isNotNullOrEmpty ? this!.endsWith('.svg') : false;
}

extension StringX on String {
  String get capitalizeFirstLetter => this[0].toUpperCase() + substring(1);

  String get lowerCaseFirstLetter => this[0].toLowerCase() + substring(1);

  String addLeadingWhiteSpace(int count) => ' ' * count + this;

  String addTrailingWhiteSpace(int count) => this + ' ' * count;

  String addLeadingLineBreak(int count) => '\n' * count + this;

  String addTrailLineBreak(int count) => this + '\n' * count;

  String addFullStop() => '$this.';

  String addTrailingDots(int count) {
    final dots = '.' * count;
    return endsWith(dots) ? this : '$this$dots';
  }

  String get removeWhiteSpaces => replaceAll(RegExp(r'\s+'), '');

  bool get isSvg => endsWith('.svg');

  String get toSentenceCase => split(' ')
      .map((word) {
        if (word.isNotEmpty) {
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }
        return word;
      })
      .join(' ');
}

extension NullableIterableX<E> on Iterable<E>? {
  bool get isNullOrEmpty => this?.isEmpty ?? true;

  bool get isNotNullOrEmpty => !isNullOrEmpty;
}

extension ColorExtension on Color {
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1, 'Amount should be between 0 and 1');
    final hsl = HSLColor.fromColor(this);
    final darkenedHsl = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkenedHsl.toColor();
  }

  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1, 'Amount should be between 0 and 1');
    final hsl = HSLColor.fromColor(this);
    final lightenedHsl = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lightenedHsl.toColor();
  }
}
