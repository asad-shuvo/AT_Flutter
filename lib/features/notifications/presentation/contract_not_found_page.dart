import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ContractNotFoundPage extends StatelessWidget {
  const ContractNotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(FilipIcons.back, size: 20, color: Color(0xFF2F2F2F)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              SelectNetworkIcons.contract,
              size: 44,
              color: Color(0xFFD0D0D0),
            ),
            const SizedBox(height: 14),
            Text(
              context.l10n.tr('tns.noDataFound'),
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Calibri',
                color: Color(0xFF9A9A9A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
