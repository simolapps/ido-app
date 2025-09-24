import 'package:flutter/material.dart';

class FeedRow {
  final int id;
  final String title;
  final String? description;
  final String? meta;
  final String? amountText;
  final String? iconKey;   // для jobs
  final Color? color;      // для jobs
   final VoidCallback? onTap;

  // опционально — кастомный onTap/полезная нагрузка

  final Object? payload;

  const FeedRow({
    required this.id,
    required this.title,
    this.description,
    this.meta,
    this.amountText,
    this.iconKey,
    this.color,
    this.onTap,
    this.payload,
  });
}
