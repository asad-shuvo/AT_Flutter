import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contract_delete_sheet.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ContractsSectionHeader extends StatelessWidget {
  const ContractsSectionHeader({
    super.key,
    required this.label,
    this.countLabel = '0',
    this.showActions = false,
    this.onInfoTap,
    this.onAddTap,
    this.isAddEnabled = true,
  });

  final String label;
  final String countLabel;
  final bool showActions;
  final VoidCallback? onInfoTap;
  final VoidCallback? onAddTap;
  final bool isAddEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label ($countLabel)',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Calibri',
            fontWeight: FontWeight.w700,
            color: Color(0xFF6C6C6C),
          ),
        ),
        if (showActions)
          Row(
            children: [
              if (onInfoTap != null)
                GestureDetector(
                  onTap: onInfoTap,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      FilipIcons.about,
                      size: 24,
                      color: Color(0xFF6C6C6C),
                    ),
                  ),
                ),
              if (onInfoTap != null && onAddTap != null)
                const SizedBox(width: 8),
              if (onAddTap != null)
                GestureDetector(
                  onTap: isAddEnabled ? onAddTap : null,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isAddEnabled
                          ? Colors.white
                          : const Color(0xFFF3F3F3),
                      border: Border.all(
                        color: isAddEnabled
                            ? const Color(0xFFD5D5D5)
                            : const Color(0xFFE1E1E1),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add,
                        size: 26,
                        color: isAddEnabled
                            ? AppColors.primaryRed
                            : const Color(0xFFAFAFAF),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class ContractsPromoCard extends StatelessWidget {
  const ContractsPromoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD8D8D8)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/dashboard/filip_explorer_background.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                  Container(color: Colors.white.withValues(alpha: 0.78)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x14FFFFFF)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -2),
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontFamily: 'Calibri',
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Calibri',
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF666666),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFFA11C36),
                        width: 1,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 24,
                        color: const Color(0xFFA11C36),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContractsListLoadingState extends StatelessWidget {
  const ContractsListLoadingState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Calibri',
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

class ContractsOverviewLoadingState extends StatelessWidget {
  const ContractsOverviewLoadingState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      child: Column(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Calibri',
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ContractsOverviewRow extends StatelessWidget {
  const ContractsOverviewRow({
    super.key,
    required this.label,
    required this.value,
    this.valueBold = false,
    this.valueColor,
    this.dot = false,
  });

  final String label;
  final String value;
  final bool valueBold;
  final Color? valueColor;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Calibri',
            color: Color(0xFF808184),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: valueColor ?? const Color(0xFF3BAF8E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Calibri',
                fontWeight: valueBold ? FontWeight.w700 : FontWeight.w400,
                color: (dot ? valueColor : null) ?? const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ContractsEmptyContractTab extends StatelessWidget {
  const ContractsEmptyContractTab({super.key, required this.labelKey});

  final String labelKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, contractsBottomClearance),
      child: Column(
        children: [
          ContractsSectionHeader(label: l10n.tr(labelKey)),
          const SizedBox(height: 50),
          ContractsEmptyState(message: l10n.tr('tns.noDataAddedYet')),
        ],
      ),
    );
  }
}

class ContractsEmptyState extends StatelessWidget {
  const ContractsEmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          SelectNetworkIcons.contract,
          size: 44,
          color: Color(0xFFD0D0D0),
        ),
        const SizedBox(height: 14),
        Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Calibri',
            color: Color(0xFF9A9A9A),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
