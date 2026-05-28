import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/real_estate/data/real_estate_repository.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

const _iconFont = 'filip_at_iconpack_29022024';
const _iconAgent   = ''; // U+E95A — injected via PS
const _iconArchive = ''; // U+EA29 — injected via PS

Future<void> showActivateAgentSheet({
  required BuildContext context,
  required RealEstateRepository repository,
  required VoidCallback onActivate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (sheetCtx) => SearchAgentActivateSheet(
      repository: repository,
      onActivate: () {
        Navigator.of(sheetCtx).pop();
        onActivate();
      },
    ),
  );
}

Future<void> showDeactivateAgentSheet({
  required BuildContext context,
  required VoidCallback onDeactivate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (sheetCtx) => SearchAgentDeactivateSheet(
      onDeactivate: () {
        Navigator.of(sheetCtx).pop();
        onDeactivate();
      },
      onCancel: () => Navigator.of(sheetCtx).pop(),
    ),
  );
}

class SearchAgentActivateSheet extends StatefulWidget {
  const SearchAgentActivateSheet({
    super.key,
    required this.repository,
    required this.onActivate,
  });

  final RealEstateRepository repository;
  final VoidCallback onActivate;

  @override
  State<SearchAgentActivateSheet> createState() => _SearchAgentActivateSheetState();
}

class _SearchAgentActivateSheetState extends State<SearchAgentActivateSheet> {
  late final TextEditingController _emailCtrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController();
    widget.repository.getUserEmail().then((email) {
      if (mounted) {
        setState(() {
          _emailCtrl.text = email;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  const Text(
                    _iconAgent,
                    style: TextStyle(
                      fontFamily: _iconFont,
                      fontSize: 22,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.tr('activateSearchAgent'),
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.tr('activateSearchAgentHeader'),
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 14,
                  color: Color(0xFF555555),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.tr('email')}:',
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 13,
                      color: Color(0xFF808080),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _isLoading
                      ? const SizedBox(
                          height: 48,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryRed,
                            ),
                          ),
                        )
                      : TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontFamily: 'Calibri',
                            fontSize: 14,
                            color: AppColors.textBody,
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFFD2D2D2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFFD2D2D2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: AppColors.primaryRed),
                            ),
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.tr('activateSearchAgentFooter'),
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 13,
                  color: Color(0xFF808080),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: widget.onActivate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    l10n.tr('activateAgent').toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchAgentDeactivateSheet extends StatelessWidget {
  const SearchAgentDeactivateSheet({
    super.key,
    required this.onDeactivate,
    required this.onCancel,
  });

  final VoidCallback onDeactivate;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              _iconArchive,
              style: TextStyle(
                fontFamily: _iconFont,
                fontSize: 64,
                color: AppColors.primaryRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.tr('deactivateModalHeader'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 15,
                color: AppColors.textBody,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                      side: const BorderSide(color: AppColors.primaryRed),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      l10n.tr('cancel').toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onDeactivate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      l10n.tr('confirm').toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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
