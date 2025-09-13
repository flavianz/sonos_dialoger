import 'package:flutter/material.dart';

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

  factory InputBox.text(
    String title,
    String value,
    Function(String?) onChanged, {
    String? hint,
    bool password = false,
  }) {
    return InputBox(
      title: title,
      widget: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        obscureText: password,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
