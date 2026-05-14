import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

const double contractsBottomClearance = 96;

enum ContractDeleteSheetResult { cancelled, deleted, failed }

void showContractsSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<ContractDeleteSheetResult> showContractDeleteBottomSheet(
  BuildContext context, {
  required Future<void> Function() onConfirmDelete,
}) async {
  final l10n = context.l10n;
  final result = await showModalBottomSheet<ContractDeleteSheetResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (context) {
      var isDeleting = false;

      Future<void> confirmDelete(StateSetter setModalState) async {
        if (isDeleting) return;
        setModalState(() => isDeleting = true);
        try {
          await onConfirmDelete();
          if (!context.mounted) return;
          Navigator.of(context).pop(ContractDeleteSheetResult.deleted);
        } catch (_) {
          if (!context.mounted) return;
          Navigator.of(context).pop(ContractDeleteSheetResult.failed);
        }
      }

      return StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDeleting)
                      const LinearProgressIndicator(
                        minHeight: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryRed,
                        ),
                      ),
                    const SizedBox(height: 34),
                    const Icon(
                      IconData(
                        0xE9F9,
                        fontFamily: 'filip_at_iconpack_29022024',
                      ),
                      size: 72,
                      color: AppColors.primaryRed,
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(
                        l10n.tr('tns.deleteContractConfirmPrompt'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 22,
                          color: Color(0xFF333333),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 42),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isDeleting
                                  ? null
                                  : () => Navigator.of(
                                      context,
                                    ).pop(ContractDeleteSheetResult.cancelled),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFD0D0D0),
                                ),
                                minimumSize: const Size.fromHeight(58),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                l10n.tr('tns.cancel').toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primaryRed,
                                  fontSize: 18,
                                  fontFamily: 'Calibri',
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.6,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isDeleting
                                  ? null
                                  : () => confirmDelete(setModalState),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryRed,
                                disabledBackgroundColor: AppColors.primaryRed,
                                minimumSize: const Size.fromHeight(58),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: isDeleting
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          l10n.tr('tns.deleting').toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontFamily: 'Calibri',
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      l10n.tr('tns.confirm').toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontFamily: 'Calibri',
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.6,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
  return result ?? ContractDeleteSheetResult.cancelled;
}

String formatContractCurrency(double value) {
  final absValue = value.abs();
  final parts = absValue.toStringAsFixed(2).split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]}.',
  );
  final result = '$intPart,${parts[1]}';
  return '€ ${value < 0 ? '-' : ''}$result';
}

bool? readBoolLike(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}
