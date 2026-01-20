import 'package:flutter/material.dart';

class SafeFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final int? maxLines;
  final int? minLines;

  const SafeFormField({
    Key? key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.maxLines = 1,
    this.minLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          maxLines: maxLines,
          minLines: minLines,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.all(12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }
}
