import 'package:flutter/material.dart';

class PropertyEmptyCard extends StatelessWidget {
  const PropertyEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_work_outlined, size: 64, color: scheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'No data added yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Calibri',
              fontSize: 14,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
