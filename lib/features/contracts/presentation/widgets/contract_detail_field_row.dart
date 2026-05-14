import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_add_models.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/theme/form_tokens.dart';
import 'package:flutter/material.dart';

class ContractDetailFieldRow extends StatelessWidget {
  const ContractDetailFieldRow({super.key, required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == null || value!.isEmpty || value == '-';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 16,
                color: Color(0xFF808080),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              isEmpty ? context.l10n.tr('tns.noDataFound') : value!,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: 'Calibri',
                fontSize: 16,
                color: isEmpty
                    ? const Color(0xFFBBBBBB)
                    : const Color(0xFF333333),
                fontStyle:
                    isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContractDetailDocumentRow extends StatelessWidget {
  const ContractDetailDocumentRow({
    super.key,
    required this.document,
    required this.formatDate,
    required this.onArchiveTap,
  });

  final ContractDocument document;
  final String Function(DateTime?) formatDate;
  final VoidCallback onArchiveTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              document.name ?? 'Document',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryRed,
              ),
            ),
          ),
          Text(
            formatDate(document.uploadDate),
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 16,
              color: Color(0xFF808080),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onArchiveTap,
            child: const Icon(
              IconData(0xEA29, fontFamily: 'filip_at_iconpack_29022024'),
              size: 20,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}
