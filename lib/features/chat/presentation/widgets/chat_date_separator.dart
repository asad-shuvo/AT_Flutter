import 'package:flutter/material.dart';

class ChatDateSeparator extends StatelessWidget {
  const ChatDateSeparator({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    // NS format: D.M.YYYY — no leading zeros
    final label = '${date.day}.${date.month}.${date.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF808080),
          ),
        ),
      ),
    );
  }
}
