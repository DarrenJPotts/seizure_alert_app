import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';

class AppDropdownField<T> extends StatefulWidget {
  const AppDropdownField({
    super.key,
    required this.items,
    required this.onChangeCallback,
    this.value,
    this.valueAccessor,
    this.displayText,
    this.label,
    this.hintText,
    this.validatorCallback,
    this.enabled = true,
    this.loading = false,
  }) : assert(
         (T == String || T == num) ||
             (displayText != null && valueAccessor != null),
         "If T is not String or num, both displayText and valueAccessor must be provided",
       );

  final List<T> items;

  final void Function(T? value) onChangeCallback;

  final T? value;

  final dynamic Function(T value)? valueAccessor;

  final String Function(T value)? displayText;

  final String? label;

  final String? hintText;

  final String? Function(T? value)? validatorCallback;

  final bool enabled;

  final bool loading;

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  T? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.value;
  }

  @override
  void didUpdateWidget(AppDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _selectedValue = widget.value;
    }
  }

  String _getDisplayText(T value) {
    if (widget.displayText != null) {
      return widget.displayText!(value);
    }
    return value.toString();
  }

  bool _itemsEqual(T? a, T? b) {
    if (a == null || b == null) return a == b;

    if (widget.valueAccessor != null) {
      return widget.valueAccessor!(a) == widget.valueAccessor!(b);
    }

    return a == b;
  }

  T? _findMatchingItem(T? value) {
    if (value == null) return null;

    try {
      return widget.items.firstWhere((item) => _itemsEqual(item, value));
    } catch (e) {
      return null;
    }
  }

  List<DropdownMenuItem<T>> _buildItemContent() {
    return widget.items.map((T value) {
      return DropdownMenuItem<T>(
        value: value,
        child: Text(
          _getDisplayText(value),
          style: context.textTheme.bodyMedium!.copyWith(
            color: widget.enabled ? Colors.black : Colors.black26,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final T? effectiveValue = _findMatchingItem(_selectedValue);

    return DropdownButtonFormField<T>(
      initialValue: effectiveValue,
      items: _buildItemContent(),
      onChanged: widget.enabled
          ? (T? value) {
              setState(() {
                _selectedValue = value;
              });
              widget.onChangeCallback(value);
            }
          : null,
      menuMaxHeight: 350,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        // Borders, padding and radius come from `inputDecorationTheme`. Only
        // the disabled hint is overridden, because the theme cannot express a
        // hint colour that depends on the field being enabled.
        hintStyle: widget.enabled
            ? null
            : context.textTheme.bodyMedium!.copyWith(color: Colors.black26),
        suffixIcon: widget.loading ? CircularProgressIndicator() : null,
        enabled: widget.enabled,
      ),
      validator: widget.validatorCallback,
      isExpanded: true,
    );
  }
}
