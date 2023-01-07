import 'package:flutter/material.dart';

class DKMenuItem<T> {
  final T value;
  final String? text ;
  final IconData? icon;
  final Color? color;
  final Color? textColor;

  DKMenuItem({
    required this.value,
    this.text,
    this.icon,
    this.color,
    this.textColor,
  });
}
