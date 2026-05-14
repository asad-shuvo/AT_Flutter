import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/theme/form_tokens.dart';
import 'package:flutter/material.dart';

class ContractDetailArchiveConfirmSheet extends StatelessWidget {
  const ContractDetailArchiveConfirmSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 14,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryRed, width: 2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 44,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryRed, width: 2),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(3),
                      bottomRight: Radius.circular(3),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 18,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l10n.tr('tns.archiveFileHeader'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 16,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryRed),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
                      ),
                    ),
                    child: Text(
                      l10n.tr('tns.cancel').toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryRed,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
                      ),
                    ),
                    child: Text(
                      l10n.tr('tns.confirm').toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
