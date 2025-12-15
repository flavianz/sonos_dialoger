import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class InputBox extends StatelessWidget {
  final String title;
  final Widget widget;

  const InputBox({super.key, required this.title, required this.widget});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        widget,
        SizedBox(height: 10),
      ],
    );
  }

  factory InputBox.number(
    String title,
    double initialValue,
    Function(double?) onChanged, {
    String? hint,
  }) {
    return InputBox(
      title: title,
      widget: TextFormField(
        keyboardType: TextInputType.number,
        initialValue: initialValue.toString(),
        onChanged: (value) {
          onChanged(double.tryParse(value));
        },
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  factory InputBox.text(
    String title,
    String initialValue,
    Function(String?) onChanged, {
    String? hint,
    bool password = false,
  }) {
    return InputBox(
      title: title,
      widget: TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        obscureText: password,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  factory InputBox.textControlled(
    String title,
    TextEditingController controller, {
    String? hint,
    bool password = false,
  }) {
    return InputBox(
      title: title,
      widget: TextFormField(
        controller: controller,
        obscureText: password,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
