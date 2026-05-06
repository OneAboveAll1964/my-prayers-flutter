import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/tokens.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
    this.prefix,
    this.suffix,
  });

  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final Widget? prefix;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.line),
      ),
      padding: EdgeInsets.only(
        left: prefix == null ? 14 : 12,
        right: suffix == null ? 14 : 12,
      ),
      child: Row(
        children: [
          if (prefix != null) ...[
            prefix!,
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: autofocus,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              cursorColor: palette.accent,
              style: TextStyle(color: palette.text, fontSize: 15),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: palette.textSubtle),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (suffix != null) ...[
            const SizedBox(width: 10),
            suffix!,
          ],
        ],
      ),
    );
  }
}

class AppNumberField extends StatelessWidget {
  const AppNumberField({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowNegative = false,
    this.allowDecimal = false,
  });

  final num value;
  final ValueChanged<num> onChanged;
  final bool allowNegative;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final controller = TextEditingController(text: value.toString());
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
    return SizedBox(
      width: 84,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.line),
        ),
        child: Center(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(
                signed: allowNegative, decimal: allowDecimal),
            textAlign: TextAlign.center,
            cursorColor: palette.accent,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(allowDecimal
                    ? (allowNegative ? r'^-?\d*\.?\d*' : r'^\d*\.?\d*')
                    : (allowNegative ? r'^-?\d*' : r'^\d*')),
              ),
            ],
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (s) {
              final parsed = allowDecimal ? num.tryParse(s) : int.tryParse(s);
              if (parsed != null) onChanged(parsed);
            },
          ),
        ),
      ),
    );
  }
}
