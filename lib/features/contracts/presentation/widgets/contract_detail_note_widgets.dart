import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/theme/form_tokens.dart';
import 'package:flutter/material.dart';

enum ContractNoteAction { edit, delete }

class ContractNoteActionSheet extends StatelessWidget {
  const ContractNoteActionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ContractNoteActionTile(
              icon: 0xE969,
              label: l10n.tr('tns.editNOTE'),
              onTap: () => Navigator.of(context).pop(ContractNoteAction.edit),
            ),
            const Divider(height: 1, indent: 18, endIndent: 18),
            ContractNoteActionTile(
              icon: 0xE9F9,
              label: l10n.tr('tns.deleteNote'),
              onTap: () => Navigator.of(context).pop(ContractNoteAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}

class ContractNoteActionTile extends StatelessWidget {
  const ContractNoteActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final int icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
        child: Row(
          children: [
            Icon(
              IconData(icon, fontFamily: 'filip_at_iconpack_29022024'),
              size: 26,
              color: AppColors.primaryRed,
            ),
            const SizedBox(width: 20),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 18,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContractNoteDeleteConfirmSheet extends StatelessWidget {
  const ContractNoteDeleteConfirmSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 34, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  IconData(0xE9F9, fontFamily: 'filip_at_iconpack_29022024'),
                  size: 72,
                  color: AppColors.primaryRed,
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    l10n.tr('tns.deleteNoteConfirmationMessage'),
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD0D0D0)),
                          minimumSize: const Size.fromHeight(58),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
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
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          minimumSize: const Size.fromHeight(58),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
                          ),
                        ),
                        child: Text(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContractNoteEditorSheet extends StatefulWidget {
  const ContractNoteEditorSheet({
    super.key,
    required this.title,
    required this.initialValue,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final String title;
  final String initialValue;
  final bool isSubmitting;
  final Future<void> Function(String value) onSubmit;

  @override
  State<ContractNoteEditorSheet> createState() => _ContractNoteEditorSheetState();
}

class _ContractNoteEditorSheetState extends State<ContractNoteEditorSheet> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTextChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    if (!mounted) return;
    setState(() {
      _errorText = _validate(_controller.text, context.l10n);
    });
  }

  String? _validate(String value, AppLocalizations l10n) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty && trimmed.length < 10) {
      return l10n.tr('tns.minimumCharacters', {'count': '10'});
    }
    if (trimmed.length > 300) {
      return l10n.tr('tns.maximumCharacters', {'count': '300'});
    }
    return null;
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final validationError = _validate(_controller.text, l10n);
    setState(() => _errorText = validationError);
    if (validationError != null || _submitting || widget.isSubmitting) return;

    setState(() => _submitting = true);
    try {
      await widget.onSubmit(_controller.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final effectiveSubmitting = _submitting || widget.isSubmitting;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final textLength = _controller.text.length;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                child: Row(
                  children: [
                    const Icon(
                      IconData(0xE976, fontFamily: 'filip_at_iconpack_29022024'),
                      size: 22,
                      color: Color(0xFF333333),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: effectiveSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF666666),
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: TextField(
                    controller: _controller,
                    enabled: !effectiveSubmitting,
                    maxLength: 300,
                    maxLines: 7,
                    minLines: 7,
                    decoration: InputDecoration(
                      hintText: '${l10n.tr('writeTextHere')}...',
                      counterText: '$textLength/300',
                      errorText: _errorText,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
                        borderSide: const BorderSide(color: Color(0xFFA11C36)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
                        borderSide: const BorderSide(
                          color: Color(0xFFA11C36),
                          width: 1.2,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
                        borderSide:
                            const BorderSide(color: Color(0xFFD9D9D9)),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
                        borderSide:
                            const BorderSide(color: AppColors.primaryRed),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
                        borderSide: const BorderSide(
                          color: AppColors.primaryRed,
                          width: 1.2,
                        ),
                      ),
                      hintStyle: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 16,
                        color: Color(0xFFB5B5B5),
                      ),
                      counterStyle: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 13,
                        color: Color(0xFF8C8C8C),
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 16,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: effectiveSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      disabledBackgroundColor:
                          AppColors.primaryRed.withValues(alpha: 0.55),
                      elevation: 0,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
                      ),
                    ),
                    child: effectiveSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            l10n.tr('tns.save').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontFamily: 'Calibri',
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
