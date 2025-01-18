import 'package:app/data/data_entry.dart';
import 'package:flutter/material.dart';

class ItemPage extends StatelessWidget {
  final DataEntry item;

  const ItemPage(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(item.form),
      Text(item.notes),
    ],);
  }
}