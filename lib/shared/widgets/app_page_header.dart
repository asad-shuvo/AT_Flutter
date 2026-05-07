import 'package:flutter/material.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFD82034), Color(0xFFA11C36)],
        ),
      ),
      child: Text(
        title,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Calibri',
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w400,
          fontSize: 24,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }
}
