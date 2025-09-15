import 'package:flutter/material.dart';

Widget getPill(String s, Color c, bool lightText) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    margin: EdgeInsets.only(left: 10),
    decoration: BoxDecoration(
      color: c,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      s,
      style: TextStyle(fontSize: 12, color: lightText ? Colors.white : null),
    ),
  );
}
