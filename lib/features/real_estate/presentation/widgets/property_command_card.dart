import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/real_estate/data/property_item.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class PropertyCommandCard extends StatelessWidget {
  const PropertyCommandCard({
    super.key,
    required this.config,
    required this.count,
    this.onAdd,
  });

  final PropertyListConfig config;
  final int count;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = l10n.tr(config.commandCardTitleKey);
    return Container(
      color: AppColors.screenBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$title ($count)',
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6C6C6C),
            ),
          ),
          if (onAdd != null)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.primaryRed, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add, color: AppColors.primaryRed, size: 24),
              ),
            ),
        ],
      ),
    );
  }
}
